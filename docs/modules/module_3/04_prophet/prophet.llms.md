# Prophet

Modified

June 4, 2026

Code

``` r
library(plotly)        #<1>
library(fable.prophet) #<2>
```

1.  For interactive plots.
2.  The `fable`-compatible interface to Meta’s Prophet algorithm.

# 1 Where We Are

Look at how far our model has come since Module 1:

| Module | What we added | Model |
|:---|:---|:---|
| **1** | Decomposition + benchmark | STL + Drift + SNAIVE |
| **2** | Smarter trend-cycle | STL + ETS / ARIMA |
| **3.1–3.2** | External context | TSLM, dynamic regression with xreg |
| **3.3** | Harmonic regression | ARIMA + Fourier terms |
| **3.4 (now)** | Automated, scalable, interpretable | **Prophet** |

Every previous model required us to make choices manually: how many AR terms? Which regressors? Where do the knots go?

> **NOTE:**
>
> In [Linear Regression](../../../../docs/modules/module_3/02_regression/regression.llms.md), we saw that piecewise TSLM is sensitive to *where* we place the knots — different choices produce dramatically different forecasts, even with similar in-sample fit. Prophet solves this automatically.

# 2 What Is Prophet?

**Prophet** is a forecasting procedure developed by Meta (Facebook) and released as open source in 2017. It was designed for business time series — daily, weekly, and yearly data with strong seasonal effects, holidays, and shifting trends.

> *“Prophet is a procedure for forecasting time series data based on an additive model where non-linear trends are fit with yearly, weekly, and daily seasonality, plus holiday effects. It works best with time series that have strong seasonal effects and several seasons of historical data.”*
>
> — [facebook.github.io/prophet](https://facebook.github.io/prophet/)

## 2.1 The Prophet model

At its core, Prophet fits a **decomposition model**:

y(t) = g(t) + s(t) + h(t) + \varepsilon_t

- g(t) — **trend**: piecewise linear or logistic growth, with changepoints detected automatically.
- s(t) — **seasonality**: Fourier series approximating yearly, weekly, or daily patterns.
- h(t) — **holidays / special events**: user-supplied dummy variables with windowed effects.
- \varepsilon_t — **noise**: assumed i.i.d. normal.

> **IMPORTANT:**
>
> This is exactly what we’ve been building all semester — trend + seasonality + external effects. Prophet just automates the specification and fits it in a Bayesian framework using Stan.

## 2.2 Automatic changepoint detection

The key innovation over piecewise TSLM is **automatic changepoint detection**. Prophet:

1.  Places a large number of *potential* changepoints uniformly in the first `changepoint_range` proportion of the data (default: 80%).
2.  Uses a sparse prior (Laplace) to shrink most changepoint magnitudes to zero — only genuine structural breaks survive.
3.  The user can tune `n_changepoints` (default 25) and `changepoint_prior_scale` (flexibility of trend changes).

No more guessing where the knots go.

## 2.3 When to use Prophet

| Situation                                                    | Use Prophet? |
|:-------------------------------------------------------------|:------------:|
| Sub-daily data (hourly, daily) with multiple seasonal cycles |      ✅      |
| Business data with holidays and known events                 |      ✅      |
| Need interpretable components for stakeholders               |      ✅      |
| Several seasons of history available                         |      ✅      |
| Short series (\< 2 full seasonal cycles)                     |      ❌      |
| Series with no clear trend or seasonality                    |      ❌      |
| Need formal inference on model parameters                    |      ❌      |
| Need prediction intervals from theory, not simulation        |      ⚠️      |

:::

> **WARNING:**
>
> Prophet was designed for *at-scale*, analyst-friendly forecasting. On many classical monthly or quarterly economic series, a well-specified ARIMA or ETS will outperform it. Always compare on a held-out test set.

# 3 Setup: `fable.prophet`

Prophet is available in R through two packages:

- `prophet` — the original package. Works standalone, does not integrate with `fable`.
- `fable.prophet` — a `fable`-compatible wrapper by Mitchell O’Hara-Wild. Lets us use Prophet inside `model()`, `forecast()`, `accuracy()`, and all the tools we already know.

Code

``` r
install.packages("fable.prophet") #<1>
library(fable.prophet)            #<2>
```

1.  `fable.prophet` is now available on CRAN.
2.  Load it alongside `fpp3` — the `prophet()` function is then available inside `model()`.

> **NOTE:**
>
> `fable.prophet` depends on `rstan` and `prophet`. On first install, R will also install Stan and its dependencies. This can take a few minutes — plan accordingly before class.

# 4 Model Specification

Inside `model()`, Prophet is specified with the `prophet()` function. Like `ARIMA()` and `ETS()`, it can be fully automatic or manually specified.

Code

``` r
# Automatic — Prophet chooses everything
prophet(y)

# Manual — explicit components
prophet(y ~ growth("linear") + season("year", type = "multiplicative"))
```

## 4.1 Trend: `growth()`

The `growth()` term specifies the trend model:

- `growth("linear")` — piecewise linear trend. Best for series that grow or decline without a natural ceiling.
- `growth("logistic")` — logistic growth (S-curve). Requires a `capacity` column in the data specifying the theoretical maximum.

Code

``` r
prophet(y ~ growth("linear",
                   n_changepoints    = 25,   #<1>
                   changepoint_range = 0.8,  #<2>
                   changepoint_prior_scale = 0.05)) #<3>
```

1.  Number of potential changepoints to consider (default: 25).
2.  Proportion of history where changepoints can occur (default: 0.8).
3.  Flexibility of trend changes — larger = more flexible, smaller = more rigid (default: 0.05).

## 4.2 Seasonality: `season()`

The `season()` term adds a Fourier-approximated seasonal pattern:

Code

``` r
prophet(y ~
  season("year",  period = 365.25, order = 10, type = "additive") +      #<1>
  season("week",  period = 7,      order = 3,  type = "multiplicative") + #<2>
  season("day",   period = 1,      order = 5,  type = "additive"))        #<3>
```

1.  Annual seasonality — 10 Fourier pairs; additive (level of seasonality does not change with the series level).
2.  Weekly seasonality — 3 Fourier pairs; multiplicative (seasonality scales with the series level).
3.  Daily seasonality — only relevant for sub-daily data.

> **TIP:**
>
> The `order` argument in `season()` is the same K we used in harmonic regression (`fourier(K = ...)`). Higher K → more flexible seasonal shape, but more parameters. Start with the default and adjust if residuals show seasonal structure.

## 4.3 Component summary

| Prophet component | Equivalent in previous models |
|:---|:---|
| `growth("linear")` | `trend(knots = ...)` in TSLM |
| `growth("logistic")` | — (no direct equivalent) |
| `season("year", type = "additive")` | `season()` in TSLM / SAR terms in SARIMA |
| `season("year", type = "multiplicative")` | Multiplicative STL seasonality |
| `season("year", order = K)` | `fourier(K = ...)` in harmonic regression |
| `holiday()` | Spike/shift dummies in TSLM |
| Changepoints (automatic) | `trend(knots = c(...))` in TSLM — but manual |

# 5 Application: LAX Passengers

We’ll apply Prophet to monthly passenger counts at **Los Angeles International Airport (LAX)**, broken down by domestic and international flights — a dataset with a clear piecewise trend, multiplicative seasonality, and a major structural break (the 2001 and 2008 shocks).

## 5.1 Load and prepare

Code

``` r
lax_passengers <- read.csv(
  "https://raw.githubusercontent.com/mitchelloharawild/fable.prophet/master/data-raw/lax_passengers.csv"
)

lax_passengers <- lax_passengers |>
  mutate(datetime = lubridate::mdy_hms(ReportPeriod)) |>        #<1>
  group_by(
    month = yearmonth(datetime),
    type  = Domestic_International
  ) |>
  summarise(passengers = sum(Passenger_Count), .groups = "drop") |> #<2>
  as_tsibble(index = month, key = type)                           #<3>

lax_passengers
```

1.  Parse the date-time string into a proper datetime object.
2.  Sum all passenger categories within each month and travel type.
3.  Convert to `tsibble` — `type` (Domestic / International) is the key variable.

## 5.2 Exploratory analysis

A few things to note from the plot:

- **Piecewise trend**: visible drops around 2001 (9/11) and 2008–2009 (financial crisis). The trend clearly changes slope at these points — this is exactly what automatic changepoint detection handles.
- **Multiplicative seasonality**: the seasonal swings grow proportionally with the series level, suggesting a multiplicative model.
- **International \< Domestic** throughout, but both share a similar seasonal shape.

> **TIP:**
>
> [![](https://i.imgflip.com/2/1ur9b0.jpg)](https://i.imgflip.com/2/1ur9b0.jpg)
>
> *Spending three hours choosing knots manually vs. discovering Prophet does it for you.*

## 5.3 Train / test split

Code

``` r
lax_train <- lax_passengers |> filter_index(~ "2017 Dec.")
lax_test  <- lax_passengers |> filter_index("2018 Jan." ~ .)
```

The test set covers 2018–2019 (24 months of out-of-sample evaluation). We intentionally stop before 2020 to avoid COVID-19 contaminating the evaluation.

## 5.4 Fit models

Code

``` r
lax_fit <- lax_train |>
  model(
    Prophet     = prophet(passengers ~                              #<1>
                    growth("linear") +
                    season("year", type = "multiplicative")),
    Prophet_auto = prophet(passengers),                            #<2>
    ARIMA       = ARIMA(passengers),                               #<3>
    ETS         = ETS(passengers),                                 #<4>
    Harmonic    = ARIMA(passengers ~ fourier(K = 3) + PDQ(0,0,0)) #<5>
  )

lax_fit
```

1.  Manual Prophet: piecewise linear trend + multiplicative annual seasonality.
2.  Automatic Prophet: lets the algorithm decide on all components.
3.  Automatic ARIMA — our Module 2 benchmark.
4.  Automatic ETS — our other Module 2 benchmark.
5.  Harmonic regression: ARIMA errors + Fourier seasonality (Module 3.3).

## 5.5 Components

One of Prophet’s biggest advantages in practice: **interpretable components** that you can show to a non-technical audience.

Code

``` r
lax_fit |>
  select(type, Prophet) |>
  components() |>
  autoplot()
```

[![](prophet_files/figure-html/lax-components-1.png)](prophet_files/figure-html/lax-components-1.png)

The decomposition shows:

- **Trend** (g(t)): captures the piecewise nature of growth, including the post-2001 and post-2009 recoveries — with no manual knot placement.
- **Annual** (s(t)): the seasonal pattern for each series. Notice it’s being fitted as a proportion of the level (multiplicative).
- **Residuals** (\varepsilon_t): should look like white noise if the model is well-specified.

## 5.6 Seasonal pattern by month

We can also visualize the seasonal component overlaid by year — useful to check if the seasonal *shape* is stable over time:

Code

``` r
lax_fit |>
  select(type, Prophet) |>
  components() |>
  ggplot(aes(
    x      = lubridate::month(month, label = TRUE), #<1>
    y      = year,                                  #<2>
    colour = type,
    group  = interaction(type, lubridate::year(month))
  )) +
  geom_line(alpha = 0.7) +
  labs(
    title = "Annual seasonal component by year",
    x     = "Month",
    y     = "Seasonal effect",
    color = "Type"
  ) +
  theme(legend.position = "top")
```

1.  Extract the month name from the time index for the x-axis.
2.  `year` is the name of the annual seasonal component extracted by `components()`.

[![](prophet_files/figure-html/lax-seasonal-1.png)](prophet_files/figure-html/lax-seasonal-1.png)

> **NOTE:**
>
> If the seasonal lines are stacked consistently, the shape is stable across years — a multiplicative model is appropriate. If lines diverge or change shape dramatically, you may need to reconsider the specification.

## 5.7 Forecast

Code

``` r
lax_fc <- lax_fit |>
  forecast(h = "2 years")

lax_fc |>
  autoplot(
    lax_passengers |> filter_index("2012 Jan." ~ .),
    level = 80
  ) +
  facet_wrap(~ type, ncol = 1, scales = "free_y") +
  labs(
    title  = "LAX passenger forecasts — 2018–2019",
    y      = "Passengers",
    x      = NULL,
    color  = "Model"
  ) +
  theme(legend.position = "top")
```

[![](prophet_files/figure-html/lax-forecast-1.png)](prophet_files/figure-html/lax-forecast-1.png)

## 5.8 Accuracy

Code

``` r
lax_accu <- lax_fc |>
  accuracy(lax_test) |>
  select(.model, type, RMSE, MAE, MAPE) |>
  arrange(type, MAPE)
```

    Warning: The future dataset is incomplete, incomplete out-of-sample data will be treated as missing. 
    9 observations are missing between 2019 abr. and 2019 dic.

Code

``` r
lax_accu
```

> **WARNING:**
>
> When your `tsibble` has a key variable (like `type` here), `accuracy()` returns one row per model *per key*. A model that performs best for Domestic passengers may not be best for International — always check both.

## 5.9 Residual diagnostics

Code

``` r
lax_fit |>
  select(type, Prophet) |>
  filter(type == "Domestic") |>
  gg_tsresiduals()
```

[![](prophet_files/figure-html/lax-resid-1.png)](prophet_files/figure-html/lax-resid-1.png)

Check:

- **Residuals vs. time**: should show no visible trend, seasonality, or heteroscedasticity.
- **ACF**: if significant spikes remain at seasonal lags, the `order` in `season()` may be too low.
- **Histogram**: roughly bell-shaped for valid prediction intervals.

# 6 Changepoints: Diagnosing the Trend

We can extract the changepoints Prophet detected and plot them against the original series — a powerful diagnostic for communicating with stakeholders.

Code

``` r
# Extract trend component to visualize changepoints
lax_fit |>
  select(type, Prophet) |>
  filter(type == "Domestic") |>
  components() |>
  autoplot(trend) +
  labs(
    title = "Prophet trend component with detected changepoints",
    y     = "Trend",
    x     = NULL
  )
```

[![](prophet_files/figure-html/lax-changepoints-1.png)](prophet_files/figure-html/lax-changepoints-1.png)

> **TIP:**
>
> In [Linear Regression](../../../../docs/modules/module_3/02_regression/regression.llms.md) we saw that different manual knot choices produce dramatically different forecasts. The plot above shows what Prophet *automatically* detected as genuine structural breaks — no trial and error needed.

# 7 Model Comparison

## 7.1 Which model wins?

Let’s put all models side by side — zooming in on the test period:

Code

``` r
p <- lax_fc |>
  ggplot(aes(x = month, y = .mean, color = .model)) +
  geom_line() +
  geom_line(
    data  = lax_passengers |> filter_index("2015 Jan." ~ .),
    aes(y = passengers, color = NULL),
    color = "grey30",
    linewidth = 0.8
  ) +
  facet_wrap(~ type, ncol = 1, scales = "free_y") +
  labs(
    title = "All models: point forecast comparison",
    y     = "Passengers",
    x     = NULL,
    color = "Model"
  ) +
  theme(legend.position = "top")

ggplotly(p)
```

> **NOTE:**
>
> - Does any model consistently over- or under-forecast?
> - Do the Prophet variants track the seasonal shape better than ARIMA/ETS?
> - Is `Prophet_auto` meaningfully different from the manual `Prophet`?
>
> These visual checks complement the numeric accuracy table — a model can have good MAPE but systematically miss peaks or troughs.

## 7.2 When does Prophet shine?

| Scenario | Prophet advantage |
|:---|:---|
| Daily / hourly data with multiple seasonalities | Handles automatically; ARIMA struggles |
| Known structural breaks (holidays, crises) | `holiday()` term + changepoints |
| Non-technical audience needs interpretation | Readable component plots |
| Large-scale automated forecasting | Consistent, robust default behavior |
| Short quarterly series (\< 4 years) | ARIMA/ETS preferred |
| Stationary series, no trend | ARIMA preferred |

## 7.3 Prophet vs. the rest

| Feature                  | ARIMA | ETS | Dynamic Reg. | Prophet |
|:-------------------------|:------|:----|:-------------|:--------|
| Automatic specification  | ✅    | ✅  | ❌           | ✅      |
| Multiple seasonalities   | ⚠️    | ⚠️  | ✅ (Fourier) | ✅      |
| Changepoints (automatic) | ❌    | ❌  | ❌           | ✅      |
| Holiday effects          | ❌    | ❌  | ✅ (manual)  | ✅      |
| Interpretable components | ⚠️    | ✅  | ✅           | ✅      |
| Formal inference         | ✅    | ✅  | ✅           | ⚠️      |
| Very short series        | ✅    | ✅  | ⚠️           | ❌      |

# 8 Summary

| Component | Syntax | Purpose |
|:---|:---|:---|
| Automatic | `prophet(y)` | Let Prophet decide everything |
| Linear trend | `growth("linear")` | Piecewise linear with auto changepoints |
| Logistic trend | `growth("logistic")` | S-curve growth with capacity |
| Additive season | `season("year", type = "additive")` | Fixed seasonal amplitude |
| Multiplicative season | `season("year", type = "multiplicative")` | Seasonal amplitude scales with level |
| Fourier order | `season("year", order = K)` | Flexibility of seasonal shape |
| Holiday effects | `holiday(holidays_df)` | User-supplied event windows |

**Key takeaways:**

- Prophet is a **decomposition model** — trend + seasonality + holidays + noise — fitting the same structure we’ve built all semester, but in an automated, Bayesian framework.
- The key innovation is **automatic changepoint detection**: no manual knot selection required.
- In `fable`, Prophet fits into the same `model()` → `forecast()` → `accuracy()` workflow — no new syntax to learn.
- Prophet is not universally better: on short, classical economic series, ARIMA and ETS often win. **Always compare on a held-out test set.**
- Components are interpretable and easy to communicate to non-technical stakeholders — a real practical advantage.

> **NOTE:**
>
> **Coming up in Module 4:** We’ve now seen all the main model families. In Module 4, we tackle what happens when data has *multiple* seasonal periods simultaneously (daily + weekly + yearly), and how to make our models robust to outliers, missing values, and real-world messiness — including ensembling the models we’ve built throughout the semester.

Back to top
