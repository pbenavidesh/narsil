# Exponential smoothing

Modified

June 9, 2026

## 0.1 Introduction

In Module 1, you built your **first complete forecasting model**. That model used:

- **STL decomposition** to separate trend-cycle and seasonal patterns.
- **Drift** to forecast the trend-cycle component (assuming the last observed trend continues linearly).
- **SNAIVE** to forecast the seasonal component (assuming last year’s season repeats).

> **NOTE:**
>
> Code
>
> ``` r
> tsibble |>
>   model(
>     baseline = decomposition_model(
>       STL(y ~ trend(window = NULL) + season(window = "periodic"), robust = TRUE),
>       RW(season_adjust ~ drift()),
>       SNAIVE(season_year)
>     )
>   )
> ```
>
> This is your **benchmark**. Every model we build from now on must beat it.

That’s a solid start — but the Drift method is very simple: it just extrapolates the last observed average growth rate forever. **What if the trend is slowing down? Accelerating? Or changing direction?**

This module introduces **Exponential Smoothing (ETS)** models — a smarter way to model the trend-cycle component (and eventually, the seasonal component too).

> **TIP:**
>
> | Component     | Module 1 (Baseline) |    Module 2 (ETS upgrade)    |
> |:--------------|:-------------------:|:----------------------------:|
> | Trend-cycle   | Drift (RW + drift)  | **ETS** (adaptive smoothing) |
> | Seasonal      |       SNAIVE        |       SNAIVE (for now)       |
> | Decomposition |         STL         |        STL (for now)         |
>
> We’re making the trend-cycle component **smarter**. Same architecture, better engine.

- Exponential smoothing methods are still relatively simple: they’re simply weighted averages from historical data.

  - However, these forecasting methods are widely used in practice, and they can be very effective.

- The exponential smoothing method is a compromise between the mean and naïve methods. It uses all historical data, but it assigns exponentially decreasing weights to older observations.

  - In the *mean* method, all observations are weighted equally (all have the same importance), while in the *naïve* method, only the most recent observation is used for forecasting. (we ignore all previous observations).

- The smoothing parameter \alpha controls the rate of decrease:

  - when \alpha is close to 1, the method behaves like the naïve method, giving more weight to recent observations;
  - when \alpha is close to 0, it behaves like the mean method, giving more equal weight to all observations.

\hat{y}\_{T+1 \| T}= \alpha y\_{T} + \alpha(1-\alpha) y\_{T-1} + \alpha(1-\alpha)^{2} y\_{T-2} + \ldots

where 0\leq \alpha \leq1 is the smoothing parameter.

|          | \alpha = 0.2 | \alpha = 0.4 | \alpha = 0.6 | \alpha = 0.8 |
|----------|:------------:|:------------:|:------------:|:------------:|
| y_t      |    0.2000    |    0.4000    |    0.6000    |    0.8000    |
| y\_{t-1} |    0.1600    |    0.2400    |    0.2400    |    0.1600    |
| y\_{t-2} |    0.1280    |    0.1440    |    0.0960    |    0.0320    |
| y\_{t-3} |    0.1024    |    0.0864    |    0.0384    |    0.0064    |
| y\_{t-4} |    0.0819    |    0.0518    |    0.0154    |    0.0013    |
| y\_{t-5} |    0.0655    |    0.0311    |    0.0061    |    0.0003    |

Table 1: Weights for different values of \alpha

- \alpha can be thought of as the *memory* of the time series: The smaller the value of \alpha, the longer the memory (i.e., the more past observations are taken into account).

- Conversely, a larger value of \alpha means a shorter memory, with more emphasis on recent observations. See [Table 1](#tbl-ets_alpha_weights) for some examples.

# 1 Exponential smoothing methods

## 1.1 Simple exponential smoothing (SES)

\begin{aligned} \text{Forecast equation} \quad & \hat{y}\_{t+h\|t} = \ell_t \\ \text{Smoothing equation} \quad & \ell_t = \alpha y_t + (1-\alpha)\ell\_{t-1} \end{aligned}

where \ell_t is the level at time t.

> **NOTE:**
>
> SES has a flat forecast function, so it is appropriate for data with **no trend** or **seasonal** pattern.

#### Example: Forecasting Algeria’s exports

Code

``` r
algeria_economy <- global_economy |>
  filter(Country == "Algeria")
  
algeria_economy |> 
  autoplot(Exports)
```

[![](ets_files/figure-revealjs/alg-plot-1.png)](ets_files/figure-revealjs/alg-plot-1.png)

Code

``` r
alg_fit <- algeria_economy |>
  model(
    SES = ETS(Exports ~ error("A") + trend("N") + season("N")), #<1>
    Naive = NAIVE(Exports)
  )

alg_fc <- alg_fit |>
  forecast(h = 5)
```

1.  We specify `trend("N")` and `season("N")` to indicate that we want a simple exponential smoothing (SES) model, which assumes no trend and no seasonality. The model will estimate the smoothing parameter \alpha automatically.

> **TIP:**
>
> The **mean** and **naïve** methods are typically the best fit as benchmark methods when using SES.

> **NOTE:**
>
> Code
>
> ``` r
> alg_fit |> 
>   select(SES) |> 
>   report()        #<1>
> ```
>
> 1.  The `report()` function allows us to see a model’s report (the time series modeled, the model used, the estimated parameters, and more). It needs a 1 \times 1 dimension `mable`[^1].
>
>     Series: Exports 
>     Model: ETS(A,N,N) 
>       Smoothing parameters:
>         alpha = 0.8399875 
>
>       Initial states:
>        l[0]
>      39.539
>
>       sigma^2:  35.6301
>
>          AIC     AICc      BIC 
>     446.7154 447.1599 452.8968 

[![](ets_files/figure-revealjs/ses-plot-1.png)](ets_files/figure-revealjs/ses-plot-1.png)

Comparing the SES and Naive forecasts:

[![](ets_files/figure-revealjs/ses-v-naive-plot-1.png)](ets_files/figure-revealjs/ses-v-naive-plot-1.png)

## 1.2 Methods with trend

### 1.2.1 Holt’s linear trend

We can extend SES models to allow our forecasts to include trend in the data. We need to add a new smoothing parameter \beta^\*, and its corresponding smoothing equation:

\begin{aligned} \text{Forecast equation} \quad & \hat{y}\_{t+h\|t} = \ell_t + hb_t \\ \text{Level equation} \quad & \ell_t = \alpha y_t + (1-\alpha)\ell\_{t-1}\\ \text{Trend equation} \quad & b_t = \beta^\*(\ell_t - \ell\_{t-1}) + (1-\beta^\*)b\_{t-1} \end{aligned}

where b_t is the growth (or slope) at time t.

> **TIP:**
>
> - Holt’s linear trend method is appropriate for data with a **linear trend** but **no seasonal** pattern.
> - The proper benchmark method to compare against is the **drift** method.

Let’s see an example using Holt’s linear trend method to forecast Brazil’s population.

#### Example: Forecasting Brazil’s population

Code

``` r
bra_economy <- global_economy |> 
  filter(Code == "BRA") |> 
  mutate(Pop = Population / 1e6)

bra_economy |> 
  autoplot(Pop)
```

[![](ets_files/figure-revealjs/bra-pop-1.png)](ets_files/figure-revealjs/bra-pop-1.png)

Code

``` r
bra_fit <- bra_economy |> 
  model(
    Holt  = ETS(Pop ~ error("A") + trend("A") + season("N")), #<1>
    Drift = RW(Pop ~ drift())
  )

bra_fit |>  
  select(Holt) |>  
  report()

bra_fc <- bra_fit |>  
  forecast(h = 15)
```

1.  We specify `trend("A")` to indicate that we want a linear trend. The model will estimate the smoothing parameters \alpha and \beta^\* automatically.

    Series: Pop 
    Model: ETS(A,A,N) 
      Smoothing parameters:
        alpha = 0.9999 
        beta  = 0.9998999 

      Initial states:
         l[0]     b[0]
     70.06297 2.132884

      sigma^2:  0.0021

          AIC      AICc       BIC 
    -115.2553 -114.1014 -104.9531 

Code

``` r
bra_fc |>
  autoplot(bra_economy, level = NULL) +
  labs(title = "Brazilian population", y = "Millions") +
  guides(colour = guide_legend(title = "Forecast"))
```

[![](ets_files/figure-revealjs/holt_full_plt-1.png)](ets_files/figure-revealjs/holt_full_plt-1.png)

### 1.2.2 Damped trend

- Holt’s linear trend method assume that the trend will continue indefinitely at the same rate. However, in many real-world scenarios, this assumption may not hold true. This methods tend to overestimate (*or underestimate*) long-term forecasts when the trend is strong.

- We can include a damping parameter \phi, which reduces the trend over time.

\begin{aligned} \text{Forecast equation} \quad & \hat{y}\_{t+h\|t} = \ell_t + (\phi + \phi^2 + \ldots + \phi^h) b_t \\ \text{Level equation} \quad & \ell_t = \alpha y_t + (1 - \alpha) (\ell\_{t-1} + \phi b\_{t-1}) \\ \text{Trend equation} \quad & b_t = \beta^\*(\ell_t-\ell\_{t-1}) + (1-\beta^\*)\phi b\_{t-1} \end{aligned}

where 0 \< \phi \< 1[^2] is the damping parameter.

> **CAUTION:**
>
> - If \phi = 1, the model reduces to Holt’s linear trend method, meaning the trend continues indefinitely at the same rate.
> - If \phi = 0, the trend component is completely eliminated, and the model behaves like simple exponential smoothing (SES), where forecasts are based solely on the level component without any trend influence.

#### Example: Forecasting Brazil’s population (continued)

Code

``` r
bra_economy |> 
  model(
    Holt   = ETS(Pop ~ error("A") + trend("A") + season("N")),
    Damped = ETS(Pop ~ error("A") + trend("Ad", phi = 0.9) + season("N")) #<1>
  ) |> 
  forecast(h = 15) |> 
  autoplot(bra_economy, level = NULL) +
  labs(title = "Brazilian population",
       y = "Millions") +
  guides(colour = guide_legend(title = "Forecast"))
```

1.  We specify `trend("Ad")` to indicate that we want a damped trend, and `phi = 0.9` sets the damping parameter to 0.9. We could also let the model estimate \phi automatically by omitting the `phi` argument.

[![](ets_files/figure-revealjs/damped_full-1.png)](ets_files/figure-revealjs/damped_full-1.png)

## 1.3 Handling seasonality: two strategies

So far, we’ve improved the trend-cycle component of our baseline model. But we haven’t touched the seasonal component yet — SNAIVE is still handling it. There are two ways to bring ETS into seasonal data, and they lead to different model families.

> **TIP:**
>
> | Strategy | How it works | When to prefer it |
> |:---|:---|:---|
> | **Decompose first** | Use STL to extract seasonality, then fit ETS on the seasonally adjusted series | Seasonal pattern is complex, changes over time, or you want explicit control |
> | **Model directly** | Use a full ETS model with a seasonal component (Holt-Winters) | Seasonal pattern is stable; simpler, self-contained model |

### 1.3.1 Strategy 1: STL + ETS via `decomposition_model()`

In Module 1 you used `decomposition_model()` to pair STL with Drift + SNAIVE. The same wrapper accepts **any** model for the seasonally adjusted series — including ETS.

Code

``` r
aus_holidays <- tourism |> 
  filter(Purpose == "Holiday") |>
  summarise(Trips = sum(Trips))

aus_holidays |> autoplot(Trips) +
  labs(title = "Australian holiday trips",
       y = "Overnight trips (millions)")
```

[![](ets_files/figure-revealjs/aus-holidays-data-1.png)](ets_files/figure-revealjs/aus-holidays-data-1.png)

Code

``` r
stl_ets_add_spec <- decomposition_model(                                        #<1>
  STL(Trips ~ trend(window = 7) + season(window = "periodic"), robust = TRUE),
  ETS(season_adjust ~ error("A") + trend("A") + season("N"))                    #<2>
)

stl_ets_mul_spec <- decomposition_model(                                        #<3>
  STL(Trips ~ trend(window = 7) + season(window = "periodic"), robust = TRUE),
  ETS(season_adjust ~ error("M") + trend("A") + season("N"))                    #<4>
)

aus_holidays |> 
  model(
    stl_ets_add = stl_ets_add_spec,
    stl_ets_mul = stl_ets_mul_spec
  ) |> 
  forecast(h = "2 years") |> 
  autoplot(aus_holidays, level = NULL) +
  labs(title = "STL + ETS forecasts",
       y = "Overnight trips (millions)") +
  scale_color_brewer(type = "qual", palette = "Dark2")
```

1.  Save the decomposition spec as a standalone object — this keeps `model()` clean and allows reuse.
2.  The ETS model is fitted on `season_adjust` (the STL-extracted seasonally adjusted series). We set `season("N")` because STL has already removed the seasonal component; SNAIVE handles it implicitly via `decomposition_model()`.
3.  A multiplicative error version of the same spec.
4.  Multiplicative errors (`error("M")`) are often better when the variance of the series grows with its level.

[![](ets_files/figure-revealjs/stl_ets_full-1.png)](ets_files/figure-revealjs/stl_ets_full-1.png)

> **NOTE:**
>
> When you pass only one sub-model (the ETS on `season_adjust`), `decomposition_model()` automatically uses **SNAIVE** for the seasonal component. You can override this by passing a second model explicitly, as in the Module 1 baseline.

### 1.3.2 Strategy 2: Holt-Winters

Instead of decomposing first, Holt-Winters extends ETS to model level, trend, and seasonality **simultaneously**.

#### 1.3.2.1 HW — Additive

\begin{aligned} \text{Forecast equation} \quad & \hat{y}\_{t+h\|t} = \ell_t + hb_t + s\_{t+h-m(k+1)} \\ \text{Level equation} \quad & \ell_t = \alpha (y_t - s\_{t-m}) + (1 - \alpha) (\ell\_{t-1} + b\_{t-1}) \\ \text{Trend equation} \quad & b_t = \beta^\*(\ell_t-\ell\_{t-1}) + (1-\beta^\*) b\_{t-1} \\ \text{Seasonal equation} \quad & s_t = \gamma(y_t - \ell\_{t-1} - b\_{t-1}) + (1-\gamma)s\_{t-m} \end{aligned}

where s_t is the seasonal component at time t, m is the period of the seasonality[^3], and k = \lfloor (h-1)/m \rfloor.

#### 1.3.2.2 HW — Multiplicative

\begin{aligned} \text{Forecast equation} \quad & \hat{y}\_{t+h\|t} = (\ell_t + hb_t) s\_{t+h-m(k+1)} \\ \text{Level equation} \quad & \ell_t = \alpha \frac{y_t}{s\_{t-m}} + (1 - \alpha)(\ell\_{t-1} + b\_{t-1}) \\ \text{Trend equation} \quad & b_t = \beta^\*(\ell_t-\ell\_{t-1}) + (1-\beta^\*) b\_{t-1} \\ \text{Seasonal equation} \quad & s_t = \gamma \frac{y_t}{\ell\_{t-1} + b\_{t-1}} + (1-\gamma)s\_{t-m} \end{aligned}

> **TIP:**
>
> - Use **additive** when seasonal fluctuations are roughly constant in size over time.
> - Use **multiplicative** when seasonal variation grows or shrinks with the level of the series.
> - When in doubt, look at the time plot: if the seasonal swings widen as the series rises, go multiplicative.

#### Example: Forecasting Australian holiday trips

Code

``` r
aus_fit_hw <- aus_holidays |> 
  model(
    hw_add = ETS(Trips ~ error("A") + trend("A") + season("A")), #<1>
    hw_mul = ETS(Trips ~ error("M") + trend("A") + season("M"))  #<2>
  )
```

1.  `error("A")` and `season("A")`: additive errors and additive seasonality. Seasonal fluctuations are treated as constant in size.
2.  `error("M")` and `season("M")`: multiplicative errors and multiplicative seasonality. Seasonal fluctuations scale with the level of the series.

Code

``` r
aus_fit_hw |>
  forecast(h = "3 years") |>
  autoplot(aus_holidays, level = NULL) +
  labs(
    title = "Holt-Winters forecasts: additive vs. multiplicative",
    y = "Overnight trips (millions)",
    caption = "Can you spot any differences between both forecasts?"
  ) +
  scale_color_brewer(type = "qual", palette = "Dark2") +
  guides(colour = guide_legend(title = "Forecast"))
```

[![](ets_files/figure-revealjs/hw_full_plt-1.png)](ets_files/figure-revealjs/hw_full_plt-1.png)

> **NOTE:**
>
> Code
>
> ``` r
> aus_fit_hw |> 
>   tidy()  #<1>
> ```
>
> 1.  The `tidy()` function allows us to see the estimated parameters of each model in a [tidy](https://r4ds.hadley.nz/data-tidy.html) table.

#### 1.3.2.3 Holt-Winters’ damped method

- Similar to Holt’s linear trend method, we can also include a damping parameter \phi in the Holt-Winters method to reduce the trend over time.
  - This can be done on both additive or multiplicative seasonal models.
- A configuration that has proven to be robust and accurate in practice is to use a multiplicative seasonal component with a damped trend.

\begin{aligned} \text{Forecast equation} \quad & \hat{y}\_{t+h\|t} = \[\ell_t +(\phi + \phi^2 + \ldots + \phi^h)b_t\] s\_{t+h-m(k+1)} \\ \text{Level equation} \quad & \ell_t = \alpha \frac{y_t}{s\_{t-m}} + (1 - \alpha)(\ell\_{t-1} + b\_{t-1}) \\ \text{Trend equation} \quad & b_t = \beta^\*(\ell_t-\ell\_{t-1}) + (1-\beta^\*) \phi b\_{t-1} \\ \text{Seasonal equation} \quad & s_t = \gamma \frac{y_t}{\ell\_{t-1} + \phi b\_{t-1}} + (1-\gamma)s\_{t-m} \end{aligned}

#### Example: Forecasting daily pedestrian traffic

Code

``` r
sth_cross_ped <- pedestrian |>
  filter(Date >= "2016-07-01", Sensor == "Southern Cross Station") |>
  index_by(Date) |>
  summarise(Count = sum(Count) / 1000)
```

Code

``` numberSource
sth_cross_ped |>
  filter(Date <= "2016-07-31") |>
  model(
    hw = ETS(Count ~ error("M") + trend("Ad") + season("M"))
  ) |>
  forecast(h = "2 weeks") |>
  autoplot(sth_cross_ped |> filter(Date <= "2016-08-14")) +
  labs(title = "Daily traffic: Southern Cross",
       y="Pedestrians ('000)")
```

[![](ets_files/figure-revealjs/hw_damped-1.png)](ets_files/figure-revealjs/hw_damped-1.png)

> **TIP:**
>
> The setup `ETS(y ~ error("M") + trend("Ad") + season("M"))` is often a robust choice for seasonal data with trend.

## 1.4 Automatic ETS selection

- Using `fable`, we can automatically select the best ETS model for our data using the `ETS()` function. We achieve this by **not specifying** the error, trend, or seasonal components.
- You can also get a *semi-automatic* selection by specifying some components and leaving others to be selected automatically, or by providing a set of possible values for a component.
- Automatic selection is especially useful when we have multiple time series to model, as it allows us to fit different ETS models to each series.

#### Example: Forecasting daily pedestrian traffic (continued)

Code

``` r
ped_fit <- pedestrian |> 
  filter(
    Date >= "2016-07-01",
    Sensor != "Birrarung Marr"
  ) |> 
  index_by(Date) |>
  group_by_key() |> 
  summarise(Count = sum(Count)/1000) |> 
  model(
    ETS_auto       = ETS(Count),                       #<1>
    ets_with_trend = ETS(Count ~ trend(c("A", "Ad"))), #<2>
  )

ped_fit                                                #<3>
```

1.  Leaving the right-hand side of the formula empty allows `fable` to automatically select the best ETS model for each time series.
2.  Here, we specify that the trend component can be either additive or damped, while the error and seasonal components will be selected automatically.
3.  The output shows the selected model for each sensor.

    # A mable: 3 x 3
    # Key:     Sensor [3]
      Sensor                            ETS_auto ets_with_trend
      <chr>                              <model>        <model>
    1 Bourke Street Mall (North)    <ETS(M,N,A)>   <ETS(M,A,A)>
    2 QV Market-Elizabeth St (West) <ETS(M,N,A)>   <ETS(M,A,A)>
    3 Southern Cross Station        <ETS(M,N,M)>   <ETS(M,A,M)>

# 2 Model comparison

Now we put all five models side by side on a proper train/test split. The goal is not just to see which number wins, but to understand *why* some approaches work better for this particular series.

### 2.0.1 Train/test split

We now evaluate all five models on the same holdout period: the **last 8 quarters** of `aus_holidays` (2 years).

Code

``` r
h <- 8

holidays_train <- aus_holidays |> 
  slice_head(n = nrow(aus_holidays) - h)   #<1>

holidays_test <- aus_holidays |> 
  slice_tail(n = h)                         #<2>
```

1.  All observations except the last 8 quarters go into training.
2.  The last 8 quarters are held out for evaluation.

Code

``` r
holidays_train |>
  autoplot(Trips) +
  autolayer(holidays_test, Trips, colour = "#C0392B", linetype = "dashed") +
  labs(
    title = "Australian holiday trips: train/test split",
    subtitle = glue::glue(
      "Training: {min(holidays_train$Quarter)} – {max(holidays_train$Quarter)}  |  Test: {min(holidays_test$Quarter)} – {max(holidays_test$Quarter)}"
    ),
    y = "Overnight trips (millions)"
  )
```

[![](ets_files/figure-revealjs/train-test-split-plt-1.png)](ets_files/figure-revealjs/train-test-split-plt-1.png)

### 2.0.2 Fitting all five models

Code

``` r
# Module 1 baseline spec (reused from Module 1)
baseline_spec <- decomposition_model(
  STL(Trips ~ trend(window = 7) + season(window = "periodic"), robust = TRUE),
  RW(season_adjust ~ drift())
)

# STL + ETS specs (defined earlier in this document)
stl_ets_add_spec <- decomposition_model(
  STL(Trips ~ trend(window = 7) + season(window = "periodic"), robust = TRUE),
  ETS(season_adjust ~ error("A") + trend("A") + season("N"))
)

stl_ets_mul_spec <- decomposition_model(
  STL(Trips ~ trend(window = 7) + season(window = "periodic"), robust = TRUE),
  ETS(season_adjust ~ error("M") + trend("A") + season("N"))
)

holidays_fit <- holidays_train |> 
  model(
    baseline    = baseline_spec,                                             #<1>
    stl_ets_mul = stl_ets_mul_spec,                                          #<3>
    stl_ets_add = stl_ets_add_spec,                                          #<2>
    hw_add      = ETS(Trips ~ error("A") + trend("A") + season("A")),        #<4>
    hw_mul      = ETS(Trips ~ error("M") + trend("A") + season("M"))         #<5>
  )

holidays_fit
```

1.  Module 1 baseline: STL + Drift + SNAIVE. The model every new approach must beat.
2.  STL decomposition, then additive ETS on the seasonally adjusted series.
3.  STL decomposition, then multiplicative ETS on the seasonally adjusted series.
4.  Holt-Winters additive: models level, trend, and seasonality jointly with additive components.
5.  Holt-Winters multiplicative: seasonal fluctuations scale with the level of the series.

    # A mable: 1 x 5
                       baseline               stl_ets_mul               stl_ets_add
                        <model>                   <model>                   <model>
    1 <STL decomposition model> <STL decomposition model> <STL decomposition model>
    # ℹ 2 more variables: hw_add <model>, hw_mul <model>

### 2.0.3 Forecast plot

Code

``` r
holidays_fc <- holidays_fit |> 
  forecast(h = h)

holidays_fc |> 
  autoplot(
    aus_holidays |> filter_index("2012 Q1" ~ .),
    level = NULL
  ) +
  labs(
    title = "ETS model comparison: 5 models, 8-quarter horizon",
    y = "Overnight trips (millions)"
  ) +
  scale_color_brewer(type = "qual", palette = "Dark2") +
  guides(colour = guide_legend(title = "Model"))
```

[![](ets_files/figure-revealjs/all-models-fc-1.png)](ets_files/figure-revealjs/all-models-fc-1.png)

### 2.0.4 Accuracy

> **WARNING:**
>
> `accuracy()` must receive the **full original tsibble** (not just the test set) as its second argument. MASE and RMSSE denominators are computed from naive errors on the **training data** — passing only the test set makes those metrics undefined.

Code

``` r
holidays_accu <- holidays_fc |> 
  accuracy(aus_holidays)           #<1>

holidays_accu |> 
  select(.model, RMSE, MAE, MAPE, RMSSE, MASE) |> 
  arrange(RMSSE)
```

1.  Always pass the **full** tsibble here, not `holidays_test`. `fable` handles the train/test split internally using the model’s training window.

### 2.0.5 What does the comparison show?

A few questions worth discussing after looking at the accuracy table:

- Do the ETS models beat the Module 1 baseline? If not, what does that tell us?
- Does the choice between additive and multiplicative matter more for STL + ETS or for Holt-Winters?
- Look at the time plot again: does the seasonal variation grow with the level? Does that match what the accuracy numbers suggest?

> **TIP:**
>
> If `hw_mul` or `stl_ets_mul` win, it is consistent with the visual evidence: the seasonal swings in `aus_holidays` do appear to widen slightly over time, which multiplicative models handle better.
>
> If the baseline is competitive, it is a reminder that more parameters do not automatically mean better forecasts — and that SNAIVE for the seasonal component is often harder to beat than it looks.

# 3 In summary

## 3.1 The lineup of exponential smoothing methods

| Trend component           | N (None) | A (Additive) | M (Multiplicative) |
|:--------------------------|:--------:|:------------:|:------------------:|
| N **(None)**              |  (N,N),  |    (N,A)     |       (N,M)        |
| A **(Additive)**          |  (A,N),  |    (A,A)     |       (A,M)        |
| A_d **(Additive damped)** | (A_d,N), |   (A_d, A)   |      (A_d,M)       |

Table 2: ETS component combinations (trend × seasonal)

| Notation |               Method               |
|:--------:|:----------------------------------:|
|  (N,N)   | Simple Exponential Smoothing (SES) |
|  (A,N)   |        Holt’s Linear Trend         |
| (A_d,N)  |       Additive damped Trend        |
|  (A,A)   |       Holt-Winters’ Additive       |
|  (A,M)   |    Holt-Winters’ Multiplicative    |
| (A_d,M)  |        Holt-Winters’ damped        |

Table 3: Names of some popular ETS models

- Exponential smoothing methods are a family of forecasting methods that use **weighted averages** of past observations to make forecasts.
- The **weights decrease exponentially** for older observations, controlled by smoothing parameters.
- Different configurations of ETS models can be used to handle various data patterns, including trend and seasonality.
- The choice of model components (`error(c("A", "M"))`, `trend(c("N", "A", "Ad"))`, `season(c("N", "A", "M"))`) should be based on the characteristics of the data — start by looking at the time plot.
- When data has both trend and seasonality, two strategies are available: **decompose first** (STL + ETS) or **model jointly** (Holt-Winters). Neither dominates universally.
- Automatic ETS selection can be a powerful tool for fitting models to multiple time series efficiently.

Back to top

## Footnotes

[^1]: (i.e., a `mable` containing only one model and one time series.)

[^2]: In practice, we restrict 0.8 \leq \phi \leq 0.98 because the damping effect would be too great for smaller values than 0.8 and almost non distinguishable from a linear trend for greater values than 0.98.

[^3]: e.g., m=4 for quarterly data, m=12 for monthly data, …
