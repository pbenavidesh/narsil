# tsibble: thinking in keys and time

R

An introduction to tsibble and the core ideas of time, keys, and structure in tidyverts-based time series workflows.

Author

Pablo Benavides-Herrera

Modified

June 4, 2026

This document is **optional**, but strongly recommended.

If tidyverse pipelines explain *how data flows*, **tsibble** explains *what kind of data you are working with*.  
For time series, this distinction is essential.

------------------------------------------------------------------------

## 1 Why tsibble exists

Most time series errors come from one simple problem:

> we forget that **time is a structure**, not just a column.

A `tsibble` makes time **explicit**, **checked**, and **enforced**.

Instead of asking: - “do I have a date column?”

we ask: - “what defines time in this data?” - “what uniquely identifies a series?” - “are observations ordered and regular?”

------------------------------------------------------------------------

## 2 From tibble to tsibble

A `tsibble` is a tibble with extra rules.

Conceptually:

- a **tibble** is just rows and columns  
- a **tsibble** is:
  - a table of time-indexed observations
  - with an explicit time variable (**index**)
  - and optional identifiers (**keys**)

> **NOTE:**
>
> A tsibble is still a tibble.  
> All tidyverse verbs work the same way.

------------------------------------------------------------------------

## 3 The two core ideas: index and key

Every tsibble is defined by:

- an **index** → the time variable  
- a **key** → what distinguishes one series from another

### 3.1 Index

The index answers:

> “along which variable does time move forward?”

Examples: - `date` - `year` - `yearweek` - `yearmonth`

### 3.2 Key

The key answers:

> “what defines a unique time series?”

Examples:

- a store  
- a product  
- a sensor  
- a country

A dataset can have: - no key (single series) - one key - multiple keys (hierarchical series)

------------------------------------------------------------------------

## 4 Creating a tsibble

``` r
library(tsibble)

data_ts <- data |>
  as_tsibble(
    index = date,
    key = id
  )
```

Reading this with the pipeline mental model:

> take `data`, **then** declare that `date` is time,  
> **then** declare that `id` identifies each series.

> **TIP:**
>
> Always read `as_tsibble()` as a *declaration*, not a transformation.

------------------------------------------------------------------------

## 5 What tsibble checks for you

When you create a tsibble, R checks that:

- the index is ordered
- each key–index combination is unique
- time moves forward consistently

If something is wrong, **it fails early**.

> **WARNING:**
>
> Errors at `as_tsibble()` time are a feature.  
> They prevent silent mistakes later in modeling and forecasting.

------------------------------------------------------------------------

## 6 Regular vs irregular time

Some series have observations at fixed intervals:

- daily
- monthly
- yearly

Others do not.

A tsibble keeps track of this distinction.

``` r
is_regular(data_ts)
```

If a series is regular, many models become simpler and more efficient.

> **NOTE:**
>
> Regularity is a property of the **index**, not the values.

------------------------------------------------------------------------

## 7 Missing time is different from missing values

A critical distinction in time series:

- missing **values** → `NA`
- missing **time points** → gaps

tsibble makes this difference explicit.

``` r
data_ts |>
  has_gaps()
```

To fill missing time points:

``` r
data_ts |>
  fill_gaps()
```

> **TIP:**
>
> Do not confuse “no observation” with “observation equals NA”.

------------------------------------------------------------------------

## 8 tsibble and tidyverse pipelines

Because tsibble extends tibble, pipelines feel natural:

``` r
data |>
  as_tsibble(index = date, key = id) |>
  filter(date >= yearmonth("2019 Jan")) |>
  group_by(id) |>
  summarise(mean_value = mean(value, na.rm = TRUE))
```

The difference is not syntax — it is **semantics**.

------------------------------------------------------------------------

## 9 Why models require tsibbles

In tidyverts:

- models expect a clear notion of time
- forecasts depend on index behavior
- keys define independent series

Without a tsibble, the model cannot know:

- what “next” means
- how many steps ahead to forecast
- whether series are independent

> **NOTE:**
>
> tsibble is the contract between your data and the forecasting models.

------------------------------------------------------------------------

## 10 Common mistakes

### 10.1 Forgetting the key

``` r
as_tsibble(data, index = date)
```

This creates a **single series**, even if multiple series are present.

### 10.2 Using the wrong index

Using an identifier as time will often succeed syntactically, but fail conceptually.

> **WARNING:**
>
> If your forecasts look strange, always check the index and key first.

------------------------------------------------------------------------

## 11 How this fits in the course

Throughout the course:

- all time series data will be stored as tsibbles
- models will assume valid indices and keys
- diagnostics rely on tsibble structure

If something breaks early, it usually means the data structure is wrong — not the model.

------------------------------------------------------------------------

> **NOTE:**
>
> - For the conceptual foundations of tidy data and tibbles, see  
>   [*R for Data Science (2e)* — **Tibbles**](https://r4ds.hadley.nz/tibbles.html).
> - For joins and keys, which strongly relate to tsibble keys, see  
>   [*R for Data Science (2e)* — **Joins**](https://r4ds.hadley.nz/joins.html). For the full tsibble framework and design philosophy, see the  
>   [*tsibble package documentation*](https://tsibble.tidyverts.org/).

------------------------------------------------------------------------

## 12 Final takeaway

> **TIP:**
>
> If tidyverse pipelines describe **how data changes**,  
> tsibbles describe **what kind of time-based data you have**.

Get the structure right, and the models will make sense.

Back to top
