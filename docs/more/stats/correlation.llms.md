# Correlation, dependence, and time series pitfalls

Stat refreshers

A refresher on correlation and statistical dependence, with an emphasis on why correlation can be misleading in time series data.

Author

Pablo Benavides-Herrera

Modified

June 3, 2026

This document is **optional**, but strongly recommended.

Correlation is one of the most commonly used statistical tools — and one of the most frequently misunderstood.

In time series, this misunderstanding can lead to **serious modeling errors**.

## 1 From covariance to correlation

Recall that the covariance between two random variables X and Y is defined as

\operatorname{Cov}(X, Y) = \mathbb{E}\[(X - \mu_X)(Y - \mu_Y)\].

Covariance measures whether large values of X tend to occur with large (or small) values of Y.

However, covariance depends on the **scale** of the variables.

To address this, we define the **correlation coefficient**:

\rho(X,Y) = \frac{\operatorname{Cov}(X,Y)} {\sqrt{\operatorname{Var}(X)\operatorname{Var}(Y)}}.

By construction,

-1 \le \rho(X,Y) \le 1.

## 2 What correlation actually measures

Correlation measures **linear association** between two random variables.

If \rho(X,Y) \neq 0, there is evidence of a linear relationship.  
If \rho(X,Y) = 0, there is **no linear relationship**.

> **NOTE:**
>
> Zero correlation does **not** imply independence.
>
> It only implies absence of *linear* dependence.

There exist dependent random variables with zero correlation.

## 3 Dependence is broader than correlation

Two random variables X and Y are **independent** if their joint distribution factorizes:

f\_{X,Y}(x,y) = f_X(x) f_Y(y).

Independence is a **strong** condition.

Correlation, by contrast, captures only one specific aspect of dependence.

> **IMPORTANT:**
>
> Independence \Rightarrow zero correlation  
> Zero correlation \nRightarrow independence

This distinction is often ignored — with consequences.

## 4 Why time series make this worse

In time series, observations are **not independent across time**.

We work with a sequence of random variables \\Y_t\\, where dependence across time is the norm, not the exception.

Correlation computed directly on time series data is therefore affected by:

- trends,
- seasonality,
- persistence,
- shared temporal structure.

## 5 Spurious correlation

Consider two unrelated time series, each with a strong trend.

Even if the underlying processes are independent, their sample correlation can be **large**.

This phenomenon is known as **spurious correlation**.

> **WARNING:**
>
> High correlation does not imply meaningful dependence  
> when time series share common structure.

This is one of the most common pitfalls in applied forecasting.

## 6 Correlation across time: autocorrelation

In time series analysis, correlation most often appears as **autocorrelation**.

The lag-h autocorrelation is defined as

\rho(h) = \frac{\operatorname{Cov}(Y_t, Y\_{t-h})} {\operatorname{Var}(Y_t)}.

Autocorrelation measures linear dependence **across time**, not across variables.

> **TIP:**
>
> Autocorrelation is not a nuisance.
>
> It is the signal that time series models are built to capture.

## 7 Why correlation is not enough

Correlation answers a narrow question:

> Is there a linear relationship?

Forecasting requires a broader understanding of dependence:

- how long dependence persists,
- how it decays over time,
- whether it is stable.

These questions cannot be answered by a single correlation coefficient.

## 8 Where this shows up in the course

This refresher is foundational for:

- autocorrelation and partial autocorrelation functions,
- stationarity assumptions,
- AR and MA models,
- residual diagnostics.

Misunderstanding correlation leads directly to misinterpreting these tools.

## 9 What you do *not* need yet

At this stage, you do **not** need:

- nonlinear dependence measures,
- copulas,
- mutual information.

Those tools exist, but linear dependence is צור enough for the models covered in this course.

## 10 Takeaway

> **IMPORTANT:**
>
> Correlation measures linear association.
>
> Dependence is broader.
>
> In time series, confusing the two leads to spurious conclusions.

Back to top
