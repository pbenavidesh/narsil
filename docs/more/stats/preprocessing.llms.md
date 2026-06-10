# Preprocessing Regressors for Forecasting

stats

A practical guide to preparing explanatory variables before fitting a TSLM: scaling, transformations, categorical encoding, interactions, and a pre-flight checklist.

Published

March 28, 2026

Modified

June 10, 2026

This document is a companion to the

[Linear Regression Models](../../../docs/modules/module_3/02_regression/regression.llms.md) module. It addresses questions that frequently come up when building a `TSLM()`:

*Do I need to scale my variables? Should I log-transform this regressor? How do I handle a categorical variable with more than two levels?*

The short answer to all three: *it depends* — and this document explains on what.

# 1 Scaling and Standardization

## 1.1 What scaling does (and does not do)

Standardization transforms a variable x into:

z = \frac{x - \bar{x}}{s_x}

so that z has mean 0 and standard deviation 1. Min-max normalization maps the variable to \[0, 1\]:

z = \frac{x - x\_{\min}}{x\_{\max} - x\_{\min}}

Both are linear transformations. Because OLS estimates are equivariant under linear transformations of the regressors, **scaling does not change predicted values, residuals, or goodness-of-fit metrics**. It only rescales the coefficients.

> **IMPORTANT:**
>
> Scaling is **irrelevant for forecast quality** in OLS-based models like `TSLM()`. Predicted values \hat{y} are identical whether you scale or not.

## 1.2 When scaling *does* matter

There are two situations where scaling genuinely changes the result:

**Regularized regression (Ridge, Lasso, Elastic Net).** The penalty term \lambda \sum_j \beta_j^2 treats all coefficients equally. If x_1 is measured in millions of pesos and x_2 is a rate between 0 and 1, the penalty will shrink \hat\beta_2 much more aggressively than \hat\beta_1 simply because of scale differences — not because x_2 is less important. Scaling before regularization is therefore **required**.

**Comparing coefficient magnitudes.** If you want to interpret which regressor has the largest *effect size* (not just the largest coefficient), standardized coefficients (also called beta coefficients) make the comparison meaningful. This is an inferential use, not a forecasting use.

> **NOTE:**
>
> `fable`’s `TSLM()` uses ordinary least squares without any penalty term. Scaling is therefore unnecessary for `TSLM()` models.

## 1.3 A quick illustration

Code

``` r
us_change_scaled <- us_change |>                                # <1>
  mutate(across(                                                # <2>
    c(Income, Production, Savings, Unemployment),
    \(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE),   # <3>
    .names = "{.col}_z"                                        # <3>
  ))

fit_original <- us_change |>                                   # <4>
  model(TSLM(Consumption ~ Income + Production))

fit_scaled <- us_change_scaled |>                              # <5>
  model(TSLM(Consumption ~ Income_z + Production_z))
```

1.  Start from `us_change`, the dataset used throughout the regression module.
2.  `across()` applies the same transformation to multiple columns at once.
3.  The anonymous function `\(x)` standardizes each selected column. `.names = "{.col}_z"` creates new columns with a `_z` suffix, preserving the originals.
4.  Fit the model on the original scale.
5.  Fit the same model on the standardized scale.

Code

``` r
fc_original <- fit_original |>                                 # <1>
  forecast(us_change |> tail(8))

fc_scaled <- fit_scaled |>                                     # <2>
  forecast(us_change_scaled |> tail(8))

bind_cols(                                                     # <3>
  fc_original |> as_tibble() |> select(.mean) |> rename(original = .mean),
  fc_scaled   |> as_tibble() |> select(.mean) |> rename(scaled   = .mean)
)
```

1.  Forecast using the original-scale model.
2.  Forecast using the standardized model.
3.  Side-by-side comparison. The columns should be identical (within floating- point precision).

> **TIP:**
>
> Compute `accuracy()` for both models. Do the RMSE and MAE differ?

# 2 Transforming the Response and Regressors

## 2.1 Transforming y: back-transformation and bias

You already saw Box-Cox and log transformations applied to y in the [decomposition module](../../../docs/modules/module_1/02_ts_dcmp/ts_dcmp.llms.md). The same logic applies inside a regression: if your series has multiplicative seasonality or variance that grows with the level, transforming y before fitting can stabilize residuals and improve forecast intervals.

In `fable`, the transformation is applied directly inside the model formula and back-transformation is handled automatically:

Code

``` r
model(TSLM(log(Consumption) ~ Income + Production))
```

> **WARNING:**
>
> When you back-transform a forecast from log scale, e^{\hat{y}} is the median of the forecast distribution, not the mean. `fable` corrects for this automatically when using `forecast()`, but it is worth knowing when interpreting point forecasts from other tools.

## 2.2 Transforming regressors: linearizing relationships

Transforming a *regressor* x is about **linearizing the relationship** between x and y. OLS assumes the relationship is linear in the parameters — but the regressors themselves can be nonlinear functions of the original variables.

Common cases:

| Relationship        | Transform  | Formula              |
|---------------------|------------|----------------------|
| Diminishing returns | Log        | y \sim \log(x)       |
| Multiplicative      | Both log   | \log(y) \sim \log(x) |
| Quadratic           | Polynomial | y \sim x + x^2       |
| Exponential growth  | Log y only | \log(y) \sim x       |

Code

``` r
model(TSLM(Consumption ~ log(Income) + Production))            # <1>
model(TSLM(Consumption ~ Income + I(Income^2)))                # <2>
```

1.  Log-transform `Income` to capture diminishing marginal effects.
2.  Add a quadratic term for `Income`. The `I()` wrapper tells R to treat `Income^2` arithmetically, not as a formula interaction.

> **NOTE:**
>
> Transforming a regressor changes the *shape* of the relationship between x and y. Transforming y changes the *distributional assumptions* about the residuals. Both can be done simultaneously.

# 3 Categorical Variables

## 3.1 From categories to numbers: dummy encoding

OLS cannot directly use a text variable. A categorical variable with k levels is converted into k - 1 binary (0/1) dummy variables. The omitted level becomes the **reference category**, and every coefficient is interpreted relative to it.

> **IMPORTANT:**
>
> Including all k dummies would create perfect multicollinearity (the *dummy variable trap*): the k columns always sum to 1, which is identical to the intercept column. OLS cannot invert the design matrix in that case.

In R, factors are automatically expanded into dummies by `lm()` and therefore by `TSLM()`. You rarely need to create them manually:

Code

``` r
us_employment |>
  filter(Title %in% c("Mining and Logging", "Construction", "Manufacturing")) |>
  model(TSLM(Employed ~ trend() + season() + Title))           # <1>
```

1.  `Title` is a character/factor variable. `TSLM()` will automatically create two dummies (three levels minus one reference).

## 3.2 Choosing the reference category

R picks the reference level alphabetically by default. You can change it with `relevel()` if a different baseline makes more interpretive sense:

Code

``` r
data |>
  mutate(quarter = relevel(factor(quarter), ref = "Q1")) |>    # <1>
  model(TSLM(y ~ trend() + quarter))
```

1.  Set Q1 as the reference so that all quarterly dummies are interpreted as deviations from Q1.

> **TIP:**
>
> When you use `season()` inside `TSLM()`, `fable` creates the seasonal dummies for you and drops one level automatically. You only need manual dummy encoding when your categorical variable is *not* the time index’s seasonal period — for example, a product category, a region, or a promotional event type.

# 4 Interactions and Nonlinear Terms

## 4.1 What an interaction says

An interaction x_1 \times x_2 allows the *effect* of x_1 on y to depend on the value of x_2. Without an interaction, OLS assumes the two effects are additive and independent.

In forecasting terms: maybe the effect of a promotional discount (`promo`) on sales is larger during the holiday season (`holiday = 1`) than during the rest of the year. That is an interaction.

Code

``` r
model(TSLM(Sales ~ trend() + season() + promo * holiday))      # <1>
model(TSLM(Sales ~ trend() + season() + promo + holiday +
             promo:holiday))                                   # <2>
```

1.  The `*` shorthand expands to main effects plus the interaction term.
2.  The `:` operator adds only the interaction term, assuming the main effects are already included.

> **WARNING:**
>
> With p regressors, you can form \binom{p}{2} pairwise interactions. Adding all of them will almost certainly overfit, especially with short time series. Only include interactions that have a clear theoretical justification.

## 4.2 Polynomial terms

For a smooth nonlinear relationship, polynomial regression adds powers of a regressor:

y_t = \beta_0 + \beta_1 x_t + \beta_2 x_t^2 + \varepsilon_t

Code

``` r
model(TSLM(y ~ x + I(x^2) + I(x^3)))                         # <1>
```

1.  Always wrap polynomial terms in `I()` inside a formula. Without it, `^` has a different meaning in R’s formula syntax.

> **NOTE:**
>
> High-degree polynomials oscillate wildly near the boundaries of the data. Splines (piecewise polynomials with smooth joins) are generally preferred for capturing smooth nonlinearities — see `splines::bs()` or `splines::ns()` for use inside `lm()` and `TSLM()`.

# 5 Pre-flight Checklist

Before running a `TSLM()`, work through these questions:

| Question | Action |
|----|----|
| Does y have variance that grows with its level? | Apply Box-Cox or log to y |
| Does a regressor have a nonlinear relationship with y? | Transform or add polynomial/spline terms |
| Does a regressor have very different scale from the others? | No action needed for OLS; scale only if using regularization |
| Do you have a categorical regressor? | Let `TSLM()` handle it automatically (factor/character columns) |
| Does the effect of one regressor depend on another? | Add an interaction term — only if theoretically justified |
| Do you have many candidate regressors? | Check VIF for multicollinearity; consider regularization |

> **IMPORTANT:**
>
> Running a TSLM with standardized variables because “it’s good practice” — and then being confused by uninterpretable coefficients. Scale only when you have a specific reason to do so.

> **TIP:**
>
> | Syntax        | Meaning                             |
> |---------------|-------------------------------------|
> | `y ~ x1 + x2` | Main effects only                   |
> | `y ~ x1 * x2` | Main effects + interaction          |
> | `y ~ x1:x2`   | Interaction only                    |
> | `y ~ I(x^2)`  | Arithmetic expression (polynomial)  |
> | `y ~ log(x)`  | Function of a regressor             |
> | `y ~ .`       | All remaining columns as regressors |

Back to top
