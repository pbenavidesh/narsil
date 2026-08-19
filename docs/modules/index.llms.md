# Modules

Welcome to the **Modules** section. Over the course of the semester, you’ll build **one forecasting model** and progressively improve it — adding smarter components, external context, and production-aware robustness with each module.

## The course arc

![](data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwJSIgdmlld2JveD0iMCAwIDY4MCAxOTIiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgc3R5bGU9ImZvbnQtZmFtaWx5OiBpbmhlcml0OyI+CjxkZWZzPgogIDxtYXJrZXIgaWQ9ImFyciIgdmlld2JveD0iMCAwIDEwIDEwIiByZWZ4PSI4IiByZWZ5PSI1IiBtYXJrZXJ3aWR0aD0iNiIgbWFya2VyaGVpZ2h0PSI2IiBvcmllbnQ9ImF1dG8tc3RhcnQtcmV2ZXJzZSI+CiAgICA8cGF0aCBkPSJNMiAxTDggNUwyIDkiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzg4OCIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIgLz4KICA8L21hcmtlcj4KPC9kZWZzPgo8cmVjdCB4PSIzMCIgeT0iMzAiIHdpZHRoPSIxMzgiIGhlaWdodD0iNjYiIHJ4PSI4IiBmaWxsPSIjRjFFRkU4IiBzdHJva2U9IiM4ODg3ODAiIHN0cm9rZS13aWR0aD0iMC41IiAvPgo8dGV4dCB4PSI5OSIgeT0iNTciIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSI1MDAiIGZpbGw9IiMyQzJDMkEiPk1vZHVsZSAxPC90ZXh0Pgo8dGV4dCB4PSI5OSIgeT0iNzYiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTIiIGZpbGw9IiM1RjVFNUEiPkRlY29tcG9zaXRpb24gYmFzZWxpbmU8L3RleHQ+CjxyZWN0IHg9IjE5OCIgeT0iMzAiIHdpZHRoPSIxMzgiIGhlaWdodD0iNjYiIHJ4PSI4IiBmaWxsPSIjRTFGNUVFIiBzdHJva2U9IiMwRjZFNTYiIHN0cm9rZS13aWR0aD0iMC41IiAvPgo8dGV4dCB4PSIyNjciIHk9IjU3IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iNTAwIiBmaWxsPSIjMDg1MDQxIj5Nb2R1bGUgMjwvdGV4dD4KPHRleHQgeD0iMjY3IiB5PSI3NiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1zaXplPSIxMiIgZmlsbD0iIzBGNkU1NiI+RVRTICZhbXA7IEFSSU1BIGZpbHRlcnM8L3RleHQ+CjxyZWN0IHg9IjM2NiIgeT0iMzAiIHdpZHRoPSIxMzgiIGhlaWdodD0iNjYiIHJ4PSI4IiBmaWxsPSIjRUVFREZFIiBzdHJva2U9IiM1MzRBQjciIHN0cm9rZS13aWR0aD0iMC41IiAvPgo8dGV4dCB4PSI0MzUiIHk9IjU3IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iNTAwIiBmaWxsPSIjMjYyMTVDIj5Nb2R1bGUgMzwvdGV4dD4KPHRleHQgeD0iNDM1IiB5PSI3NiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1zaXplPSIxMiIgZmlsbD0iIzUzNEFCNyI+RXhvZ2Vub3VzIHZhcmlhYmxlczwvdGV4dD4KPHJlY3QgeD0iNTM0IiB5PSIzMCIgd2lkdGg9IjExNiIgaGVpZ2h0PSI2NiIgcng9IjgiIGZpbGw9IiNGQUVDRTciIHN0cm9rZT0iIzk5M0MxRCIgc3Ryb2tlLXdpZHRoPSIwLjUiIC8+Cjx0ZXh0IHg9IjU5MiIgeT0iNTciIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSI1MDAiIGZpbGw9IiM0QTFCMEMiPk1vZHVsZSA0PC90ZXh0Pgo8dGV4dCB4PSI1OTIiIHk9Ijc2IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXNpemU9IjEyIiBmaWxsPSIjOTkzQzFEIj5Sb2J1c3RuZXNzICZhbXA7IHNjYWxlPC90ZXh0Pgo8bGluZSB4MT0iMTY5IiB5MT0iNjMiIHgyPSIxOTYiIHkyPSI2MyIgc3Ryb2tlPSIjODg4IiBzdHJva2Utd2lkdGg9IjEiIG1hcmtlci1lbmQ9InVybCgjYXJyKSI+PC9saW5lPgo8bGluZSB4MT0iMzM3IiB5MT0iNjMiIHgyPSIzNjQiIHkyPSI2MyIgc3Ryb2tlPSIjODg4IiBzdHJva2Utd2lkdGg9IjEiIG1hcmtlci1lbmQ9InVybCgjYXJyKSI+PC9saW5lPgo8bGluZSB4MT0iNTA1IiB5MT0iNjMiIHgyPSI1MzIiIHkyPSI2MyIgc3Ryb2tlPSIjODg4IiBzdHJva2Utd2lkdGg9IjEiIG1hcmtlci1lbmQ9InVybCgjYXJyKSI+PC9saW5lPgo8bGluZSB4MT0iOTkiIHkxPSI5NyIgeDI9Ijk5IiB5Mj0iMTE1IiBzdHJva2U9IiNjY2MiIHN0cm9rZS13aWR0aD0iMC41IiBzdHJva2UtZGFzaGFycmF5PSIzIDMiPjwvbGluZT4KPGxpbmUgeDE9IjI2NyIgeTE9Ijk3IiB4Mj0iMjY3IiB5Mj0iMTE1IiBzdHJva2U9IiNjY2MiIHN0cm9rZS13aWR0aD0iMC41IiBzdHJva2UtZGFzaGFycmF5PSIzIDMiPjwvbGluZT4KPGxpbmUgeDE9IjQzNSIgeTE9Ijk3IiB4Mj0iNDM1IiB5Mj0iMTE1IiBzdHJva2U9IiNjY2MiIHN0cm9rZS13aWR0aD0iMC41IiBzdHJva2UtZGFzaGFycmF5PSIzIDMiPjwvbGluZT4KPGxpbmUgeDE9IjU5MiIgeTE9Ijk3IiB4Mj0iNTkyIiB5Mj0iMTE1IiBzdHJva2U9IiNjY2MiIHN0cm9rZS13aWR0aD0iMC41IiBzdHJva2UtZGFzaGFycmF5PSIzIDMiPjwvbGluZT4KPHRleHQgeD0iOTkiIHk9IjEyOCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1zaXplPSIxMSIgZmlsbD0iIzg4OCI+U1RMICsgU05BSVZFICsgRHJpZnQ8L3RleHQ+Cjx0ZXh0IHg9IjI2NyIgeT0iMTI4IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXNpemU9IjExIiBmaWxsPSIjODg4Ij5TVEwgKyBFVFMgLyBBUklNQTwvdGV4dD4KPHRleHQgeD0iNDM1IiB5PSIxMjgiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTEiIGZpbGw9IiM4ODgiPkFSSU1BKHkgfiB4cmVnKTwvdGV4dD4KPHRleHQgeD0iNTkyIiB5PSIxMjgiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTEiIGZpbGw9IiM4ODgiPlByb3BoZXQgKyBlbnNlbWJsZXM8L3RleHQ+CjxsaW5lIHgxPSIzMCIgeTE9IjE0OCIgeDI9IjY1MCIgeTI9IjE0OCIgc3Ryb2tlPSIjZGRkIiBzdHJva2Utd2lkdGg9IjAuNSI+PC9saW5lPgo8dGV4dCB4PSI5OSIgeT0iMTY4IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXNpemU9IjExIiBmaWxsPSIjYWFhIiBmb250LXN0eWxlPSJpdGFsaWMiPlVuZGVyc3RhbmQgdGhlIHNlcmllczwvdGV4dD4KPHRleHQgeD0iMjY3IiB5PSIxNjgiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTEiIGZpbGw9IiNhYWEiIGZvbnQtc3R5bGU9Iml0YWxpYyI+U21hcnRlciB0cmVuZC9jeWNsZTwvdGV4dD4KPHRleHQgeD0iNDM1IiB5PSIxNjgiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTEiIGZpbGw9IiNhYWEiIGZvbnQtc3R5bGU9Iml0YWxpYyI+RXh0ZXJuYWwgY29udGV4dDwvdGV4dD4KPHRleHQgeD0iNTkyIiB5PSIxNjgiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMTEiIGZpbGw9IiNhYWEiIGZvbnQtc3R5bGU9Iml0YWxpYyI+UHJvZHVjdGlvbi1yZWFkeTwvdGV4dD4KPC9zdmc+)

> **TIP:**
>
> Use the **sidebar** to move lesson-by-lesson through each module. Each lesson includes explanations, worked examples in R, and exercises to reinforce the ideas.

## Prerequisites and setup

Before starting, make sure you can open the course **folder** as a project in Positron, run an `{r}` code chunk, and install packages in R. Work through [Setup](../../docs/more/r-tools/setup.llms.md) first if any of that is unfamiliar — it walks you through installing R and Positron and getting your packages ready. [Module 1 — Introduction](../../docs/modules/module_1/00_intro/intro.llms.md) then covers the course workflow and expectations.

## Course map

### Module 1: Forecasting models based on decomposition methods

Build the fundamentals: time series data structures, transformations, decomposition, and your first complete forecast. You’ll establish a benchmark model that every later module will try to beat.

- [1.0 Introduction](../../docs/modules/module_1/00_intro/intro.llms.md)
- [1.1 R, tsibble, and Time Series](../../docs/modules/module_1/01_time_series/r_time_series.llms.md)
- [1.2 Time Series Decomposition](../../docs/modules/module_1/02_ts_dcmp/ts_dcmp.llms.md)
- [1.3 Forecasting Foundations](../../docs/modules/module_1/03_fcst/forecasting.llms.md)
- [1.4 Model Diagnostics and Advanced Forecasting](../../docs/modules/module_1/04_model_diagnostics/model_diagnostics.llms.md)

*Once you have a working baseline, Module 2 replaces its naive components with smarter statistical filters →*

------------------------------------------------------------------------

### Module 2: Adding ETS and ARIMA filters

Replace the benchmark components with exponential smoothing and ARIMA models. Learn to identify and correct non-stationarity, and combine decomposition with full statistical models.

- [2.1 Exponential Smoothing](../../docs/modules/module_2/01_ets/ets.llms.md)
- [2.2 Stationarity & Differencing](../../docs/modules/module_2/02_stationarity/stationarity.llms.md)
- [2.3 ARIMA Models](../../docs/modules/module_2/03_arima/arima.llms.md)
- [2.4 Modular Forecasting: Mixing ETS and ARIMA](../../docs/modules/module_2/04_modular_fcst/modular_forecasting.llms.md)

*Your model now handles trend and autocorrelation well — Module 3 adds external information from outside the series →*

------------------------------------------------------------------------

### Module 3: Regression and exogenous variables

Incorporate external drivers and handle real data challenges. You’ll move from clean regression setups to dynamic models that combine regression with ARIMA errors, and close with Prophet as a practical industry tool.

- [3.1 Practical Issues](../../docs/modules/module_3/01_practical_issues/practical_issues.llms.md)
- [3.2 Linear Regression Models](../../docs/modules/module_3/02_regression/regression.llms.md)
- [3.3 Dynamic & Harmonic Regression](../../docs/modules/module_3/03_dynamic/dynamic_regression.llms.md)
- [3.4 Prophet](../../docs/modules/module_3/04_prophet/prophet.llms.md)

*With external variables in the model, Module 4 focuses on making everything robust and production-ready →*

------------------------------------------------------------------------

### Module 4: Forecasting at scale

Handle complexity: multiple seasonal patterns, uncertainty quantification, and forecast combinations. The final module ties everything together into a complete, production-aware workflow.

- [4.1 Complex Seasonality](../../docs/modules/module_4/01_complex_seasonality/complex_seasonality.llms.md)
- [4.2 Bootstrapping, Bagging & Model Combinations](../../docs/modules/module_4/02_bootstrap_combinations/bootstrap_combinations.llms.md)
- [4.3 Time Series Cross-Validation](../../docs/modules/module_4/03_cv/ts_cv.llms.md)
- [4.4 Hierarchical & Grouped Forecasting](../../docs/modules/module_4/04_hierarchical/hierarchical.llms.md)

*Complete Modules 1–3 before starting here.*

------------------------------------------------------------------------

## Recommended study loop

1.  **Read** the lesson — focus on *why* the method works and how it builds on what came before.
2.  **Run** the code and verify the outputs on your machine.
3.  **Tweak** one assumption (horizon, transformation, window) and observe what changes.
4.  **Practice** with the matching exercise set in the [Exercises](../../docs/exercises/index.llms.md) section.

Back to top
