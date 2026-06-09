# Pipes and the tidyverse mental model

R

How to think in tidyverse pipelines: understanding pipes, data flow, and readable transformations in R.

Author

Pablo Benavides-Herrera

Modified

June 9, 2026

This document is **optional**, but strongly recommended.

If you are new to R or come from another language, understanding pipes will make the entire course easier, clearer, and more enjoyable.

------------------------------------------------------------------------

## 1 What a pipe really means

In tidyverse-style R, the pipe operator `|>` means:

> “take the result of the previous step and pass it as the input of the next one”

A useful way to read a pipeline is to mentally replace `|>` with the word **“then”**.

For example:

``` r
df |>
  filter(value > 0) |>
  summarise(mean_value = mean(value))
```

can be read as:

> “take `df`, **then** filter rows where `value > 0`, **then** compute the mean of `value`.”

> **TIP:**
>
> If you can read a pipeline out loud using “then” and it still makes sense,  
> you are probably writing clear tidyverse code.

> **NOTE:**
>
> For more on style, including guidance on pipes, see  
> [*R for Data Science (2e)* — **Workflow: code style (Pipes)**](https://r4ds.hadley.nz/workflow-style.html#sec-pipes).

------------------------------------------------------------------------

## 2 Tidyverse code with and without pipes

## Without pipes

``` r
df_filtered <- filter(df, value > 0)
df_transformed <- mutate(df_filtered, log_value = log(value))
df_grouped <- group_by(df_transformed, id)
df_summary <- summarise(df_grouped, mean_value = mean(log_value))
```

- Explicit intermediate objects  
- More typing  
- Easier to lose the “story” of the data

## With pipes

``` r
df |>
  filter(value > 0) |>
  mutate(log_value = log(value)) |>
  group_by(id) |>
  summarise(mean_value = mean(log_value))
```

- One clear data flow  
- No temporary variables  
- Easier to read, explain, and debug

------------------------------------------------------------------------

## 3 The tidyverse mental model

A tidyverse pipeline usually follows this pattern:

- start with a dataset  
- filter rows  
- create or transform variables  
- group the data  
- summarise

This is not a strict rule, but a very common and effective structure.

> **NOTE:**
>
> Most tidyverse verbs return a **new tibble**.  
> The original data is never modified unless you explicitly reassign it.

> **NOTE:**
>
> If you want a broader overview of how the pieces fit together, see  
> [*R for Data Science (2e)* — **Introduction**](https://r4ds.hadley.nz/intro.html).

------------------------------------------------------------------------

## 4 Pipes are not magic

The pipe does **not** change what functions do.  
It only changes **how inputs are passed**.

### 4.1 Without pipes

``` r
summarise(
  group_by(
    mutate(
      filter(df, value > 0),
      log_value = log(value)
    ),
    id
  ),
  mean_value = mean(log_value)
)
```

### 4.2 With pipes

``` r
df |>
  filter(value > 0) |>
  mutate(log_value = log(value)) |>
  group_by(id) |>
  summarise(mean_value = mean(log_value))
```

> **TIP:**
>
> If you can rewrite a pipeline as nested function calls,  
> then the pipeline is doing exactly what you think it is.

------------------------------------------------------------------------

## 5 Pipes and column references

Inside tidyverse verbs, column names are used **directly**.

``` r
df |>
  summarise(mean_value = mean(value, na.rm = TRUE))
```

No `$`, no indexing, no extra syntax.

> **NOTE:**
>
> This works because tidyverse uses **data-masking**:  
> column names are looked up automatically inside the data.

> **TIP:**
>
> You do not need to master these details for this course.
>
> If you are curious about what’s happening under the hood, see  
> [*R for Data Science (2e)* — **Functions**](https://r4ds.hadley.nz/functions.html).

------------------------------------------------------------------------

## 6 Why we avoid `$` in this course

- It breaks the pipeline mental model  
- It mixes different styles of R  
- It becomes confusing with grouped data

For clarity and consistency, we will stick to tidyverse verbs and pipelines.

------------------------------------------------------------------------

## 7 Common pipe mistakes

### 7.1 Breaking the pipeline

``` r
df |>
  filter(value > 0)

mutate(log_value = log(value))
```

The second line does not receive the result of the pipeline.

Correct:

``` r
df |>
  filter(value > 0) |>
  mutate(log_value = log(value))
```

------------------------------------------------------------------------

### 7.2 Forgetting reassignment

``` r
df |>
  mutate(x = x * 2)
```

Nothing changes.

Correct:

``` r
df <- df |>
  mutate(x = x * 2)
```

> **WARNING:**
>
> If you forget to reassign, the pipeline runs but the result is discarded.

------------------------------------------------------------------------

## 8 Pipes and readability

Pipelines are about **clarity**, not cleverness.

Prefer this:

``` r
df |>
  filter(value > 0) |>
  group_by(id) |>
  summarise(mean_value = mean(value))
```

Over this:

``` r
df |> filter(value > 0) |> group_by(id) |> summarise(mean_value = mean(value))
```

> **TIP:**
>
> One verb per line is a good default.

> **NOTE:**
>
> For more examples of `filter()`, `mutate()`, `group_by()`, and `summarise()`, see  
> [*R for Data Science (2e)* — **Data transformation**](https://r4ds.hadley.nz/data-transform.html).

------------------------------------------------------------------------

## 9 When not to use pipes

Pipes work best for **linear transformations**.

They are less useful for:

- complex branching logic  
- deeply nested conditionals  
- non–data-centric code

Even so, in this course we will often prefer pipelines for consistency.

``` r
df |>
  summarise(mean_value = mean(value, na.rm = TRUE))
```

------------------------------------------------------------------------

## 10 Pipes in this course

Throughout the course:

- all data manipulation examples will use pipes  
- tidyverse verbs will be preferred  
- clarity will be valued over clever tricks

If something feels confusing, read the pipeline **top to bottom**, step by step —  
using “then” as you go.

------------------------------------------------------------------------

## 11 Final takeaway

> **TIP:**
>
> If you understand pipes, you understand most of tidyverse-based R.

Everything else in the course builds on this idea.

Back to top
