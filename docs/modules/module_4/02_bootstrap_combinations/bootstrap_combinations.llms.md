# Bootstrapping, Bagging & Model Combinations

Modified

August 21, 2026

Code

``` r
library(plotly)    #<1>
library(tidyquant) #<2>
library(fable.prophet) #<3>
```

1.  For interactive plots.
2.  For retrieving `mexretail` from FRED.
3.  Neccesary for fitting `prophet` models.

# 1 Where We Are

Over the course of this semester, we have built a progressively richer model:

| Module | What we added | Model |
|:---|:---|:---|
| **1** | Decomposition + benchmark | STL + Drift + SNAIVE |
| **2** | Smarter trend-cycle | STL + ETS / ARIMA |
| **3** | External context + harmonic regression | TSLM, dynamic regression, Prophet |
| **4.1** | Multiple seasonality | MSTL, STL + ARIMA + Fourier |
| **4.2 (now)** | Ensemble strategies | **Combinations + Bagging** |

> **IMPORTANT:**
>
> We have several good models. **Which one do we deploy?**
>
> What if the answer is: *all of them*?

# 2 Forecast Combinations

## 2.1 The core idea

> *“The results have been virtually unanimous: combining multiple forecasts leads to increased forecast accuracy. In many cases one can make dramatic performance improvements by simply averaging the forecasts.”*
>
> — Hyndman & Athanasopoulos, FPP3

This result, first documented by Bates & Granger (1969), has been replicated across hundreds of forecasting competitions and domains. It is one of the most robust empirical findings in the field.

## 2.2 Why Does Combination Work?

Intuitively: each model captures some patterns but misses others. When models make **different kinds of errors**, averaging them out reduces overall error.

The key condition is **diversity** — combining models that fail in the same way provides little benefit. This is why combining ETS, ARIMA, and Prophet tends to work better than combining three variants of ARIMA.

> **NOTE:**
>
> If two unbiased forecasts f_1 and f_2 have errors with equal variance \sigma^2 and correlation \rho, the equal-weight combination has error variance:
>
> \text{Var}\left(\frac{e_1 + e_2}{2}\right) = \frac{\sigma^2(1 + \rho)}{2}
>
> When \rho \< 1, the combination **always beats the average individual model**. When \rho = 0, variance halves.

## 2.3 A First Example: Australian Cement Production

We introduce combinations with `aus_production` (Cement) — a quarterly manufacturing series with clear trend and seasonality.

Code

``` r
cement <- aus_production |>
  select(Quarter, Cement) |>
  filter(!is.na(Cement))

cement_train <- cement |> filter(year(Quarter) <= 2005) #<1>
cement_test  <- cement |> filter(year(Quarter) >  2005) #<2>
```

1.  Training set: up to and including 2005.
2.  Test set: 2006 Q1 through 2010 Q2 — 18 quarters.

## 2.4 Fitting Individual Models

Code

``` r
cement_fit <- cement_train |>
  model(
    ets   = ETS(Cement),                         #<1>
    arima = ARIMA(Cement),                       #<2>
    stlf  = decomposition_model(                 #<3>
              STL(Cement ~ trend(window = NULL) +
                    season(window = "periodic"),
                  robust = TRUE),
              ETS(season_adjust ~ season("N"))
            )
  )
```

1.  Automatic ETS selection.
2.  Automatic ARIMA selection.
3.  STL + ETS on the seasonally adjusted component — our Module 2 approach.

## 2.5 Combining: The Manual Approach

The simplest combination is an equal-weight average computed **after** forecasting, using `mutate()` on the fable object. This is the approach shown in FPP3.

Code

``` r
cement_fc_manual <- cement_fit |>
  mutate(                                                  #<1>
    combination = (ets + arima) / 2
  ) |> 
  forecast(h = nrow(cement_test))
```

1.  `mutate()` on a `mable` object adds a new model column.

> **TIP:**
>
> The `.mean` of the combined distribution is the average of the individual `.mean` values.

## 2.6 Combining: Inside `model()` with `combination_ensemble()`

`fable` also provides `combination_ensemble()` to define combinations **inside** `model()`, keeping the entire workflow within a single `mable`. This is cleaner and more consistent with the `fable` framework.

Code

``` numberSource
cement_fit2 <- cement_train |>
  model(
    ets   = ETS(Cement),
    arima = ARIMA(Cement),
    stlf  = decomposition_model(
              STL(Cement ~ trend(window = NULL) +
                    season(window = "periodic"),
                  robust = TRUE),
              ETS(season_adjust ~ season("N"))
            ),
    comb_equal = combination_ensemble(             #<1>
                   ETS(Cement),
                   ARIMA(Cement),
                   decomposition_model(
                     STL(Cement ~ trend(window = NULL) +
                           season(window = "periodic"),
                         robust = TRUE),
                     ETS(season_adjust ~ season("N"))
                   ),
                   weights = "equal"               #<2>
                 ),
    comb_inv_var = combination_ensemble(           #<3>
                     ETS(Cement),
                     ARIMA(Cement),
                     decomposition_model(
                       STL(Cement ~ trend(window = NULL) +
                             season(window = "periodic"),
                           robust = TRUE),
                       ETS(season_adjust ~ season("N"))
                     ),
                     weights = "inv_var"           #<4>
                   )
  )
```

1.  `combination_ensemble()` defines the combination inside `model()`. Every sub-model is re-fitted automatically.
2.  `weights = "equal"` gives each model weight 1/K. Equivalent to the `mutate()` average.
3.  A second combination with data-driven weights.
4.  `weights = "inv_var"` assigns weights inversely proportional to each model’s in-sample error variance.

> **NOTE:**
>
> | Function | Weights | Best for |
> |:---|:---|:---|
> | `combination_ensemble()` | `"equal"` or `"inv_var"` | Standard use — let the data or equal weighting decide |
> | `combination_weighted()` | Explicit numeric vector | When you have domain knowledge about which model to trust more |
> | `combination_model()` | Explicit numeric vector | Same as above, slightly different syntax |
>
> For most applications, `combination_ensemble()` with `"equal"` or `"inv_var"` is the right choice.

## 2.7 Forecasts and Accuracy

Code

``` r
cement_fc2 <- cement_fit2 |>
  forecast(h = nrow(cement_test))

cement_accu <- cement_fc2 |>
  accuracy(cement) |>
  select(.model, RMSE, MAE, MAPE, MASE) |>
  arrange(RMSE)

cement_accu
```

# 3 Bootstrapping and Bagging

## 3.1 The idea: simulating alternative histories

Combinations average across **different models** fitted to the same data. Bagging takes a complementary approach: average across **the same model** fitted to many **simulated versions** of the data.

A single model fit is one realization of what could have happened given a different path of random shocks. If we observe many plausible alternative histories of the series, we can average forecasts from all of them — reducing variance without changing the model family.

## 3.2 How Block Bootstrap Works

Standard bootstrap (resample observations independently) breaks temporal dependence. For time series, we use **block bootstrap**:

1.  Decompose the series with STL → isolate the **remainder** component
2.  Resample the remainder in **blocks** to preserve local autocorrelation
3.  Reconstruct synthetic series: trend + seasonal + bootstrapped remainder
4.  Repeat B times → B plausible alternative histories

**Bagging** (Bootstrap AGGregating) = fit a model to each bootstrapped series, then average the B forecasts.

## 3.3 Generating Bootstrap Series

We continue with Cement to maintain continuity:

Code

``` r
cement_stl <- cement_train |>
  model(stl = STL(Cement ~ trend(window = NULL) +    #<1>
                    season(window = "periodic"),
                  robust = TRUE))
```

1.  We need the fitted STL object to generate bootstrap series from it.

Code

``` numberSource
set.seed(2025)

cement_sim <- cement_stl |>
  generate(
    new_data             = cement_train, #<1>
    times                = 100,          #<2>
    bootstrap_block_size = 8             #<3>
  ) |>
  select(-.model, -Cement)               #<4>
```

1.  Regenerate over the training period.
2.  100 bootstrapped alternative histories.
3.  Block size of 8 quarters (~2 years) — preserves seasonal autocorrelation in the remainder.
4.  Drop the original series column; `.sim` contains the bootstrapped values.

> **TIP:**
>
> A rule of thumb: one or two seasonal periods. For quarterly data (m = 4), `bootstrap_block_size = 4` or `8` is typically appropriate.

## 3.4 Visualizing the Bootstrap Series

## 3.5 Fitting, Forecasting, and Averaging

Code

``` r
cement_bag_fit <- cement_sim |>
  model(ets = ETS(.sim))  #<1>
```

1.  `fable` fits one ETS model per bootstrapped series (100 models). The key variable `.rep` distinguishes each replicate.

Code

``` r
cement_bag_mean <- cement_bag_fit |>
  forecast(h = nrow(cement_test)) |>
  summarise(                          #<1>
    bagged_mean = mean(.mean)         #<2>
  )
```

1.  Collapse the 100 forecast trajectories into a single point forecast.
2.  The bagged forecast is the simple average across replicates.

## 3.6 Comparing Bagging with Individual Models

Code

``` r
cement_bag_accu <- cement_test |>
  left_join(cement_bag_mean, by = "Quarter") |>
  as_tibble() |> 
  summarise(
    .model = "bagging_ets",
    RMSE   = sqrt(mean((Cement - bagged_mean)^2)),
    MAE    = mean(abs(Cement - bagged_mean)),
    MAPE   = mean(abs((Cement - bagged_mean) / Cement)) * 100
  )

bind_rows(cement_accu, cement_bag_accu) |> arrange(RMSE)
```

> **WARNING:**
>
> Bagged forecasts come from 100 separately keyed series (`.rep`) and cannot be piped into `combination_ensemble()` alongside standard models. Compare them with other models manually via `accuracy()`.

> **TIP:**
>
> Bagging helps most when the series is short or volatile. On longer, stable series the improvement over a single well-fitted model is often modest.

# 4 The Full Picture: Three Datasets

## 4.1 Series overview

We now apply both strategies to three series from across the course, putting every model we have built this semester head-to-head:

| Dataset | Models available | Notes |
|:---|:---|:---|
| `aus_production` (Beer) | ETS, ARIMA, STLF, TSLM, Prophet | No external regressors — TSLM uses trend + season only |
| `mexretail` | ETS, ARIMA, STLF, TSLM, Prophet | Same — TSLM with trend + season |
| `aus_accommodation` (NSW) | All above + dynamic regression (CPI) | Full Module 3 arsenal available |

> **NOTE:**
>
> The bagging pipeline works with any model that `fable` can fit — ARIMA, Prophet, etc. We use ETS here because it is the approach validated by Bergmeir, Hyndman & Benitez (2016), and because fitting 100 ARIMAs with automatic order selection is substantially slower. ETS is fast, robust, and well-supported by the literature for this use case.

## 4.2 Data Setup

## Beer production

Code

``` numberSource
beer <- aus_production |>
  select(Quarter, Beer) |>
  filter_index("1990 Q1" ~ .) |> 
  rename(y = Beer)

beer_train <- beer |> filter(year(Quarter) <= 2006)
beer_test  <- beer |> filter(year(Quarter) >  2006)
```

## MEXRETAIL

Code

``` numberSource
mexretail <- tq_get(
  "MEXSLRTTO01IXOBM",
  get = "economic.data",
  from = "1985-01-01",
  to = "2019-12-31"
) |>
  mutate(date = yearmonth(date)) |>
  rename(y = price) |>
  as_tsibble(index = date)

mexretail_train <- mexretail |> filter(year(date) <= 2017)
mexretail_test <- mexretail |> filter(year(date) > 2017)
```

## NSW accomodation

Code

``` numberSource
nsw <- aus_accommodation |>
  filter(State == "New South Wales") |>
  select(Date, Takings, CPI) |>
  rename(y = Takings)

nsw_train <- nsw |> filter(year(Date) <= 2012)
nsw_test <- nsw |> filter(year(Date) > 2012)
```

> **IMPORTANT:**
>
> We rename our forecast variable to `y` in every `tsibble` so that we can reuse the model specs and save lines of code.

## 4.3 Model Specs

We will use the same models across the three datasets:

## Model specs

Code

``` r
tslm_spec <- TSLM(log(y) ~ trend() + season()) #<1>

ets_spec <- ETS(log(y))

arima_spec <- ARIMA(log(y))

stlf_spec <- decomposition_model(
  STL(
    log(y) ~ trend(window = NULL) + season(window = "periodic"),
    robust = TRUE
  ),
  ETS(season_adjust ~ season("N"))
)

prophet_spec <- prophet(y) #<2>
```

1.  TSLM with deterministic trend and seasonal dummies — no external regressors available for Beer.
2.  Requires `fable.prophet`. Uses default automatic specification.

## Combination specs

Code

``` r
comb_equal_spec <- combination_ensemble(
  tslm_spec,
  ets_spec,
  arima_spec,
  stlf_spec,
  prophet_spec,
  weights = "equal" #<3>
)

comb_inv_var_spec <- combination_ensemble(
  tslm_spec,
  ets_spec,
  arima_spec,
  stlf_spec,
  prophet_spec,
  weights = "inv_var" #<4>
)
```

1.  Combining all the models using equal weights.
2.  Combining all the models using an inverse variance weighted ensemble.

## `mable` specs

Code

``` r
mable_spec <- function(.train_tsb) {   #<5>  
  .train_tsb |>                        #<5> 
    model(                             #<5> 
      tslm         = tslm_spec,        #<5> 
      ets          = ets_spec,         #<5> 
      arima        = arima_spec,       #<5> 
      stlf         = stlf_spec,        #<5>
      prophet      = prophet_spec,     #<5>
      comb_equal   = comb_equal_spec,  #<5>
      comb_inv_var = comb_inv_var_spec #<5>
    )                                  #<5>
}
```

1.  We define a function containing the `mable` to fit with all our model specifications.

## 4.4 Beer: Full Model Comparison

## Models & Combinations

Code

``` r
beer_fit <- beer_train |>
  mable_spec() #<1>

beer_fit |> 
  glimpse()

beer_fc <- beer_fit |>
  forecast(h = nrow(beer_test))
```

1.  We simply use our `mable_spec()` function to fit all our models.

    Rows: 1
    Columns: 7
    $ tslm         <model> [TSLM]
    $ ets          <model> [ETS(A,Ad,A)]
    $ arima        <model> [ARIMA(1,0,2)(0,1,2)[4]]
    $ stlf         <model> [STL decomposition model]
    $ prophet      <model> [prophet]
    $ comb_equal   <model> [COMBINATION]
    $ comb_inv_var <model> [COMBINATION]

Code

``` r
p <- beer_fc |> 
  autoplot(beer |> filter_index("1998 Q1" ~ .), level = NULL)

ggplotly(p, dynamicTicks = TRUE)
```

## Bagging

Code

``` r
set.seed(2025)

beer_bag_mean <- beer_train |>
  model(stl = STL(log(y) ~ trend(window = NULL) + season(window = "periodic"),
                  robust = TRUE)) |>
  generate(
    new_data             = beer_train,
    times                = 100,
    bootstrap_block_size = 4
  ) |>
  select(-.model, -y) |>
  model(ets = ETS(.sim)) |>
  forecast(h = nrow(beer_test)) |>
  summarise(bagged_mean = mean(.mean))
```

## Accuracy

Code

``` r
beer_accu_std <- beer_fc |>
  accuracy(beer) |>
  select(.model, RMSE, MAE, MAPE)

beer_accu_bag <- beer_test |>
  left_join(beer_bag_mean, by = "Quarter") |>
  as_tibble() |> 
  summarise(
    .model = "bagging_ets",
    RMSE   = sqrt(mean((y - bagged_mean)^2)),
    MAE    = mean(abs(y - bagged_mean)),
    MAPE   = mean(abs((y - bagged_mean) / y)) * 100
  )

bind_rows(beer_accu_std, beer_accu_bag) |> arrange(RMSE)
```

## 4.5 mexretail: Full Model Comparison

## Models & Combinations

Code

``` r
mexretail_fit <- mexretail_train |>
  mable_spec()

mexretail_fit |> 
  glimpse()
```

    Rows: 1
    Columns: 7
    $ tslm         <model> [TSLM]
    $ ets          <model> [ETS(A,N,A)]
    $ arima        <model> [ARIMA(3,1,1)(1,1,1)[12]]
    $ stlf         <model> [STL decomposition model]
    $ prophet      <model> [prophet]
    $ comb_equal   <model> [COMBINATION]
    $ comb_inv_var <model> [COMBINATION]

Code

``` r
mexretail_fc <- mexretail_fit |>
  forecast(h = nrow(mexretail_test))
```

Code

``` r
p <- mexretail_fc |> 
  autoplot(mexretail, level = NULL)

ggplotly(p, dynamicTicks = TRUE)
```

## Bagging

Code

``` r
set.seed(2025)

mexretail_bag_mean <- mexretail_train |>
  model(stl = STL(log(y) ~ trend(window = NULL) + season(window = "periodic"),
                  robust = TRUE)) |>
  generate(
    new_data             = mexretail_train,
    times                = 100,
    bootstrap_block_size = 12
  ) |>
  select(-.model, -y) |>
  model(ets = ETS(.sim)) |>
  forecast(h = nrow(mexretail_test)) |>
  summarise(bagged_mean = mean(.mean))
```

## Accuracy

Code

``` r
mexretail_accu_std <- mexretail_fc |>
  accuracy(mexretail) |>
  select(.model, RMSE, MAE, MAPE)

mexretail_accu_bag <- mexretail_test |>
  left_join(mexretail_bag_mean, by = "date") |>
  as_tibble() |>
  summarise(
    .model = "bagging_ets",
    RMSE = sqrt(mean((y - bagged_mean)^2, na.rm = TRUE)),
    MAE = mean(abs(y - bagged_mean), na.rm = TRUE),
    MAPE = mean(abs((y - bagged_mean) / y), na.rm = TRUE) * 100
  )

bind_rows(mexretail_accu_std, mexretail_accu_bag) |> arrange(RMSE)
```

## 4.6 NSW Accommodation: Full Model Comparison

NSW is the richest comparison: it includes CPI as a covariate, so dynamic regression enters the mix.

## Models & Combinations

Code

``` r
nsw_fit <- nsw_train |>
  model(                             
      tslm         = TSLM(y ~ trend()+ season() + CPI),  #<1>     
      ets          = ets_spec,
      arima        = ARIMA(y),         
      dynamic      = ARIMA(y ~ CPI),                     #<2>  
      stlf         = stlf_spec,       
      prophet      = prophet(y ~ CPI + season(period = "year", type = "additive")), #<3>   
      comb_equal   = comb_equal_spec, 
      comb_inv_var = comb_inv_var_spec
    )  

nsw_fit |> 
  glimpse()

nsw_fc <- nsw_fit |>
  forecast(new_data = nsw_test)
```

1.  NSW has CPI available, so TSLM can use it as a predictor — unlike Beer and mexretail.
2.  Dynamic regression: ARIMA errors + CPI regressor.
3.  Prophet allows including predictors as well, so we use CPI here too.

    Rows: 1
    Columns: 8
    $ tslm         <model> [TSLM]
    $ ets          <model> [ETS(A,N,A)]
    $ arima        <model> [ARIMA(1,0,0)(0,1,1)[4] w/ drift]
    $ dynamic      <model> [LM w/ ARIMA(1,0,0)(0,1,1)[4] errors]
    $ stlf         <model> [STL decomposition model]
    $ prophet      <model> [prophet]
    $ comb_equal   <model> [COMBINATION]
    $ comb_inv_var <model> [COMBINATION]

Code

``` r
p <- nsw_fc |> 
  autoplot(nsw, level = NULL)

ggplotly(p, dynamicTicks = TRUE)
```

## Bagging

Code

``` r
set.seed(2025)

nsw_bag_mean <- nsw_train |>
  model(stl = STL(log(y) ~ trend(window = NULL) + season(window = "periodic"),
                  robust = TRUE)) |>
  generate(
    new_data             = nsw_train,
    times                = 100,
    bootstrap_block_size = 4
  ) |>
  select(-.model, -y) |>
  model(ets = ETS(.sim)) |>
  forecast(h = nrow(nsw_test)) |>
  summarise(bagged_mean = mean(.mean))
```

## Accuracy

Code

``` r
nsw_accu_std <- nsw_fc |>
  accuracy(nsw) |>
  select(.model, RMSE, MAE, MAPE)

nsw_accu_bag <- nsw_test |>
  left_join(nsw_bag_mean, by = "Date") |>
  as_tibble() |>
  summarise(
    .model = "bagging_ets",
    RMSE = sqrt(mean((y - bagged_mean)^2, na.rm = TRUE)),
    MAE = mean(abs(y - bagged_mean), na.rm = TRUE),
    MAPE = mean(abs((y - bagged_mean) / y), na.rm = TRUE) * 100
  )

bind_rows(nsw_accu_std, nsw_accu_bag) |> arrange(RMSE)
```

# 5 Key Takeaways

## 5.1 What to remember

> **IMPORTANT:**
>
> - **Forecast combinations** work because diverse models make different errors — one of the most robust findings in forecasting.
> - **Equal-weight averaging** is surprisingly hard to beat. Complex weighted schemes need careful validation to justify the added complexity.
> - **Bagging** averages across simulated alternative histories, not different models. Most useful for short or volatile series.
> - **More complex ≠ always better.** Always compare on a held-out test set — sometimes a single model wins.
> - **Bagged forecasts cannot be combined** with standard `fable` models inside `combination_ensemble()` — compare them via `accuracy()` separately.

### 5.1.1 When to use each strategy

| Strategy | Use when… | Avoid when… |
|:---|:---|:---|
| **Equal-weight combination** | Models have comparable accuracy, diverse error structures | All models fail the same way |
| **`inv_var` combination** | One model is clearly better in-sample | Sample too small to reliably estimate variances |
| **Bagging** | Series is short or volatile | Series is long and stable — marginal gain rarely justifies computation |
| **No combination** | One model dominates clearly on the test set | — |

**FPP3 references:** [§12.5 Bootstrapping and bagging](https://otexts.com/fpp3/bootstrap.html) · [§13.4 Forecast combinations](https://otexts.com/fpp3/combinations.html)

Back to top
