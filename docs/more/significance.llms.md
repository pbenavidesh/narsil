# Statistical Significance

refreshers

What a p-value is, what α commits you to, and what rejection means in each of the three hypothesis tests this course uses.

Published

August 21, 2026

Modified

August 21, 2026

Code

``` r
library(tidyverse)
library(fpp3)
```

## TL;DR

A **p-value** is the probability of observing data at least as extreme as yours *assuming H_0 is true*. Small p-value → the data are hard to reconcile with H_0 → **reject H_0**. Large p-value → **fail to reject H_0**.

That is the whole decision rule. Everything below is about what it does and does not license you to say.

# 1 What a hypothesis test asks

A hypothesis test puts two claims in competition:

- The **null hypothesis** H_0 — the claim the test defends. It stands unless the data argue against it.
- The **alternative hypothesis** H_1 — what remains if H_0 falls.

The test does not treat the two symmetrically. Every piece of machinery in it — the statistic, the critical value, the p-value — measures evidence *against* H_0. Nothing measures evidence *for* it. That asymmetry fixes the form the conclusion can take.

**We reject H_0, or we fail to reject H_0. We never accept it.**

The wording carries content. Failing to reject means the data did not supply enough evidence against H_0 to overturn it at the threshold you chose, not that the data supported H_0. The p-value alone cannot distinguish the two: a large p-value can come from a series that genuinely satisfies H_0, or from one that violates it in a way the test was too weak to detect. [Section 4](#sec-power) is about the second case; [Section 7](#sec-tests) is where it bites in this course.

> **NOTE:**
>
> “The residuals are white noise” and “we cannot rule out that the residuals are white noise” describe the same output and commit you to different things. Write the second, and pair any fail-to-reject you report with the series length — a reader cannot judge one without it.

# 2 The significance level \alpha

The **significance level** \alpha is the threshold you set *before* seeing the data. If the p-value falls below \alpha, you reject.

Choosing \alpha = 0.05 commits you to a long-run error rate: across many applications of the test to data where H_0 is in fact true, you will reject about 5% of the time anyway. It is a property of the *procedure*, not of the single test in front of you — there is no sense in which this particular rejection “has a 5% chance of being wrong”. And 0.05 is a convention: it is convenient because everyone else uses it, which is most of its justification.

# 3 Type I and Type II error

Two ways to be wrong, depending on a state of the world you cannot observe:

|  | H_0 is true | H_0 is false |
|----|----|----|
| **Reject H_0** | **Type I error** (rate \alpha) | Correct — rate 1 - \beta |
| **Fail to reject H_0** | Correct | **Type II error** (rate \beta) |

A **Type I error** is a false positive: you claim an effect that is not there. A **Type II error** is a false negative: an effect is there and you miss it.

## 3.1 The asymmetry between \alpha and \beta

Courses, textbooks, and software defaults are organised around controlling \alpha and say comparatively little about \beta. Two reasons, both of which matter for reading output.

First, \alpha is *chosen*. You fix it in advance and the test is constructed to respect it. \beta is not: it depends on how far the truth sits from H_0 — the effect size — which is unknown, and is why you are running a test at all. You cannot fix in advance a number that depends on the answer.

Second, H_0 is conventionally written as the conservative, status-quo claim: no autocorrelation, no relationship, nothing going on. Under that convention a Type I error announces a discovery that is not there, the costlier mistake, and controlling \alpha tightly is the price of it. Both reasons depend on H_0 being the boring claim. [Section 7](#sec-tests) has a case where it is not.

# 4 Power

The **power** of a test is 1 - \beta: the probability of rejecting H_0 when H_0 is genuinely false. It depends on three things:

- **Effect size** — how badly H_0 is violated. Large violations are easy to detect.
- **Sample size** — more observations, more power. Usually the only lever you control.
- **\alpha** — a stricter threshold rejects less often, which lowers power. Protection against Type I error is bought with Type II error.

Power is where Type II error lives, and it is why a fail-to-reject is weak evidence rather than a finding. A test with low power fails to reject almost regardless of the truth, so its fail-to-reject carries almost no information.

## 4.1 Low power is dangerous in KPSS

In most tests you will meet, rejecting is the interesting outcome, and low power costs you a discovery. The KPSS test used in [Stationarity](../../docs/modules/module_2/02_stationarity/stationarity.llms.md) inverts this. There, H_0 is *the series is stationary* — the outcome you want. Failing to reject is the green light to stop differencing and start modelling.

That inversion makes low power work in your favour, which is what makes it dangerous. A short series that genuinely has a unit root can fail to reject KPSS simply because there are not enough observations to detect the drift in the partial sums. The p-value comes back large; read under the normal habit — large p-value, good news — the student concludes the series is stationary, skips the differencing step, and fits an ARIMA to non-stationary data. Nothing in the output flags it. The test did not say the series was stationary; it said it could not tell.

So a fail-to-reject on KPSS has to be read alongside how much data produced it. On 250 daily observations it is informative. On 30 quarterly observations it is close to uninformative, and the series plot and its ACF should outweigh the p-value.

# 5 What a p-value is, and what it is not

The **p-value** is P(\text{data at least this extreme} \mid H_0 \text{ true}) — a statement about data, conditional on a hypothesis. Four misreadings are common enough to name.

**It is not P(H_0 \mid \text{data}).** The conditioning runs the other way. Getting from one to the other needs a prior on H_0, which the test neither has nor uses.

**It is not a measure of effect size.** It answers “is this distinguishable from H_0”, not “how large is it”. Two coefficients with the same p-value can differ by orders of magnitude. Read the estimate.

**It shrinks with sample size.** Any deviation from H_0, however small, will eventually produce an arbitrarily small p-value given enough observations. A residual autocorrelation of 0.03 is economically meaningless and still rejects Ljung-Box on 5,000 daily observations. “Statistically significant” and “large enough to matter” are separate claims needing separate evidence.

**A non-significant result is not evidence that H_0 is true.** The rule from [Section 1](#sec-asks) again, and the misreading with the most expensive consequences in this course. Without knowing the power of the test you cannot tell whether H_0 holds or the test was blind.

# 6 Using p-values consciously

The 0.05 threshold controls the error rate of *one* test. Run twenty independent tests on data where H_0 holds everywhere and you should expect about one rejection by construction. Time series work walks into this constantly: reading an ACF plot is taking a significance decision at every lag at once, which is why the portmanteau tests in [Section 7](#sec-tests) exist — they test a whole group of autocorrelations with one statistic instead of lag by lag.

**P-hacking** names a workflow, not an intent. Trying several transformations, lag choices, and predictor sets and then reporting whichever specification cleared 0.05 produces a p-value that no longer means what it says, because the reported test was selected *for* being significant. The usual version in a forecasting project is honest and invisible: you fit six models, check the diagnostics, report the one that passed. Say how many you tried.

The American Statistical Association’s 2016 statement on p-values makes one point worth carrying: a p-value alone does not support a scientific or business conclusion. It is one input, read next to the effect size, the sample size, the plot, and what you know about the series.

# 7 The three tests this course uses

What rejection *means* differs in all three, and that is the part to memorise.

Code

``` r
beer <- aus_production |>
  filter(year(Quarter) >= 1992) |>
  select(Quarter, Beer)

beer_fit <- beer |>
  slice_head(n = nrow(beer) - 16) |>              #<1>
  model(
    naive  = NAIVE(Beer),
    snaive = SNAIVE(Beer)
  )

google_2015 <- gafa_stock |>
  filter(Symbol == "GOOG") |>
  mutate(day = row_number()) |>                   #<2>
  update_tsibble(index = day, regular = TRUE) |>
  mutate(diff_close = difference(Close)) |>
  filter(year(Date) == 2015)
```

1.  Hold back the last 16 quarters, as in [Forecasting Foundations](../../docs/modules/module_1/03_fcst/forecasting.llms.md).
2.  Trading days are irregular on the calendar, so the row number is the index. This is the construction used in [Stationarity](../../docs/modules/module_2/02_stationarity/stationarity.llms.md), so the numbers below match what you see there.

## 7.1 Ljung-Box

H_0: \text{the residuals are white noise} \qquad H_1: \text{they are not}

**Rejecting is bad news.** It says the model left structure in the residuals that it could have used. The test runs on `.innov`, the innovation residuals, not on `.resid` — when the model contains a transformation the two are on different scales, and the white noise assumption applies to `.innov`.

Code

``` r
beer_fit |>
  augment() |>
  features(.innov, ljung_box, lag = 8, dof = 0)   #<1>
```

1.  `lag = 8` is 2m for quarterly data; `dof = 0` because the benchmark methods estimate no parameters.

Both benchmarks reject — neither is an adequate model here, which is what the diagnostics are for. A fail-to-reject looks like this instead:

Code

``` r
google_2015 |>
  model(naive = NAIVE(Close)) |>
  augment() |>
  features(.innov, ljung_box, lag = 10, dof = 0)
```

Read that as the test finding nothing, not as the model being right.

## 7.2 KPSS

H_0: \text{the series is stationary} \qquad H_1: \text{it is not}

**Rejecting is bad news for the opposite reason.** Here H_0 is the outcome you want, so rejection means “difference again”. What the inversion does to the way you read the hypotheses is covered in [Stationarity](../../docs/modules/module_2/02_stationarity/stationarity.llms.md); what it does to *power* is [Section 4](#sec-power), and that is the part easy to miss.

Code

``` r
google_2015 |> features(Close, unitroot_kpss)
```

Code

``` r
google_2015 |> features(diff_close, unitroot_kpss)
```

### 7.2.1 KPSS and ADF invert the null

Students arriving from an econometrics course have usually met the **augmented Dickey-Fuller (ADF)** test instead. The two answer the same question with the hypotheses swapped: ADF has H_0 = *the series has a unit root*, KPSS has H_0 = *the series is stationary*.

That swap flips the default conclusion — the answer you land on when the data are not decisive. Failing to reject ADF reads as “there is a unit root”; failing to reject KPSS reads as “the series is stationary”. A test with too little power fails to reject in both cases, so on the same short, ambiguous series the two conventions quietly hand you opposite answers, and neither output looks less confident than the other.

Which is why practitioners often run both and treat agreement as the confirmation, disagreement as a sign the series sits near the boundary and the plots should decide. This course uses only KPSS, because `feasts` exposes `unitroot_kpss` and `ARIMA()` reaches it through `unitroot_ndiffs()`. **Phillips-Perron** and **DF-GLS** are variants of the ADF null with different corrections for serial correlation — Phillips-Perron adjusts the statistic non-parametrically, DF-GLS detrends first to gain power.

## 7.3 Regression coefficients

H_0: \beta_i = 0 \qquad H_1: \beta_i \neq 0

**Rejecting is the evidence you were looking for** — the only one of the three where the interesting outcome is rejection. Failing to reject says the data cannot distinguish the coefficient from zero, which is not the same as establishing that the predictor is irrelevant.

Code

``` r
us_change |>
  model(TSLM(Consumption ~ Income + Production + Savings + Unemployment)) |>
  report()
```

    Series: Consumption 
    Model: TSLM 

    Residuals:
         Min       1Q   Median       3Q      Max 
    -0.90555 -0.15821 -0.03608  0.13618  1.15471 

    Coefficients:
                  Estimate Std. Error t value Pr(>|t|)    
    (Intercept)   0.253105   0.034470   7.343 5.71e-12 ***
    Income        0.740583   0.040115  18.461  < 2e-16 ***
    Production    0.047173   0.023142   2.038   0.0429 *  
    Savings      -0.052890   0.002924 -18.088  < 2e-16 ***
    Unemployment -0.174685   0.095511  -1.829   0.0689 .  
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

    Residual standard error: 0.3102 on 193 degrees of freedom
    Multiple R-squared: 0.7683, Adjusted R-squared: 0.7635
    F-statistic:   160 on 4 and 193 DF, p-value: < 2.22e-16

The stars in the `Pr(>|t|)` column are a compressed reading of the p-value:

| Marker  | p-value              |
|---------|----------------------|
| `***`   | p \< 0.001           |
| `**`    | 0.001 \leq p \< 0.01 |
| `*`     | 0.01 \leq p \< 0.05  |
| `.`     | 0.05 \leq p \< 0.1   |
| (blank) | p \geq 0.1           |

The `.` marker is worth noticing: it sits on the wrong side of the conventional threshold and R prints it anyway.

This output also shows [Section 5](#sec-pvalue)’s second misreading where you will meet it most often. `Income` and `Savings` both earn `***` with estimates differing by roughly a factor of fourteen; `Production` and `Savings` have estimates of comparable size and different star counts. The stars rank how cleanly a coefficient separates from zero and say nothing about magnitude — itself a further question, since comparing magnitudes across predictors requires comparable scales. See [Preprocessing Regressors](../../docs/more/stats/preprocessing.llms.md).

# 8 Short exercise

1.  You fit a model to 34 quarterly observations. `unitroot_kpss` on the undifferenced series returns a p-value of 0.1, and Ljung-Box on `.innov` returns 0.42. Write down what each result licenses you to conclude and what it does not. Which of the two would you trust less, and why?

2.  Two predictors in a `TSLM()` both come back with `***`. One has an estimate of 0.74, the other 0.004. A colleague concludes both are important drivers of the response. Identify the error, and say what you would need to look at to decide whether either predictor matters.

Back to top
