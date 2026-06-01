# Course Structure — Time Series Forecasting at ITESO

## Progressive Narrative

The course builds ONE forecasting approach across 16 weeks, adding complexity at
each module. Every new method must justify itself by beating the previous baseline.

---

## Module 1: Foundation — Building Your First Forecast (Weeks 1–4)
*"Getting data ready and establishing a baseline"* | FPP3 Ch. 2–5

- Week 1: Time series basics — tsibble, visualization, patterns
- Week 2: Data preparation — transformations, calendar adjustments
- Week 3: STL decomposition — trend, season, remainder
- Week 4: Benchmark forecasting — MEAN, NAIVE, SNAIVE, Drift, decomposition model

**Module deliverable:**
```r
decomposition_model(STL(y), SNAIVE(season()), RW(drift = TRUE))
```
This is **the baseline**. Every future model is compared against it.

Key concepts introduced: train/test split, residual diagnostics, accuracy metrics
(MAE, RMSE, MAPE, MASE, RMSSE)

---

## Module 2: Smarter Filters — ETS and ARIMA (Weeks 5–8)
*"Replacing naive methods with statistical filters"* | FPP3 Ch. 8–9

- Weeks 5–6: Exponential Smoothing (ETS) — error, trend, season components
- Weeks 7–8: Stationarity, differencing, ARIMA identification and fitting

**Module deliverable:**
```r
# Option A: ETS inside decomposition
decomposition_model(STL(y), ETS(season_adjust ~ error("A") + trend("N") + season("N")))

# Option B: Full ARIMA (replaces decomposition)
ARIMA(y)  # with possible seasonal terms
```

Key concepts: ACF/PACF interpretation, unit root tests, AIC/BIC model selection,
information criteria, seasonal ARIMA (P,D,Q)

---

## Module 3: External Information — Regression (Weeks 9–12)
*"Your model now knows what's happening in the world"* | FPP3 Ch. 7, 10

- Weeks 9–10: Linear regression for time series (TSLM)
  - `TSLM(y ~ trend() + season())` — uses seasonal **dummies**, not Fourier
  - Adding external regressors
- Weeks 11–12: Dynamic regression and harmonic regression
  - Motivation: TSLM residuals show autocorrelation → need ARIMA errors
  - `ARIMA(y ~ xreg + PDQ(0,0,0))` — regression with ARIMA errors
  - Harmonic regression: `ARIMA(y ~ fourier(K=k) + PDQ(0,0,0))`
  - Prophet: `prophet(y ~ season("week") + season("year"))`

**Critical distinction**: TSLM uses seasonal dummies; harmonic regression uses
Fourier terms. This contrast is pedagogically important — don't conflate them.

Key concepts: spurious regression, cointegration intuition, lagged regressors,
distributed lag models, Fourier terms for complex seasonality

---

## Module 4: Real-World Deployment (Weeks 13–16)
*"Making models production-ready"* | FPP3 Ch. 12–13

- Week 13: Complex seasonality
  - Multiple `season()` calls in STL for sub-daily data
  - Fourier + ARIMA errors for large/non-integer periods
- Week 14: Practical issues
  - Outliers, missing values, short series, forecast constraints
- Week 15: Bootstrapping, bagging, forecast combinations
  - `bootstrap_simulations()`, `generate()`, ensemble methods
- Week 16: Hierarchical & grouped forecasting
  - `reconcile()`, MinT, BU, TD approaches

---

## Datasets Used in the Course

| Dataset | Package | Used for |
|---|---|---|
| `aus_retail` | tsibbledata | Module 1–2 examples |
| `vic_elec` | tsibbledata | Complex seasonality (Module 4) |
| `us_change` | fpp3 | Dynamic regression (Module 3) |
| `insurance` | fpp3 | Lagged predictors |
| `PBS` | tsibbledata | Module 3 exam |
| `bank_calls` | fpp3 | In-class exercise |
| `global_economy` | tsibbledata | Hierarchical forecasting |
| Various `fpp3` datasets | fpp3 | Throughout |

Primary package for all datasets: `fpp3` (loads everything needed).

---

## Grading Philosophy

- Baseline model (STL + SNAIVE + Drift) is the scoring **threshold**
- Teams beating the baseline score on a linear scale
- Teams failing to beat it are capped
- Metrics: MAPE for global forecasting, RMSSE for hierarchical
