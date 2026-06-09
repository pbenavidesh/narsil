# R for Python Users

R

A conceptual introduction to R for students coming from a Python background, focused on mental models, data workflows, and tidyverse-style thinking.

Author

Pablo Benavides-Herrera

Modified

June 9, 2026

This document is **optional**, but highly recommended if you come from a Python background.

The goal is **not** to teach R from scratch.  
The goal is to help you **translate mental models** from Python to R, so that the rest of the course feels natural instead of frustrating.

> **NOTE:**
>
> If you already feel comfortable with R, you can safely skip this document and come back to it only if something feels confusing later on.

------------------------------------------------------------------------

## 1 The main mindset shift

If you come from Python, you are used to thinking in terms of:

- step-by-step instructions  
- objects that are modified in place  
- explicit loops  
- “do this, then do that”

R (especially the tidyverse) encourages a different way of thinking:

- transformations instead of instructions  
- immutable data objects  
- pipelines instead of loops  
- “what happens to the data as it flows”

> **TIP:**
>
> In tidyverse code, try to read pipelines **out loud**.  
> If it sounds like a sentence describing the data, you are probably doing it right.

------------------------------------------------------------------------

## 2 Imperative vs functional style

## Python

``` python
df = df[df["value"] > 0]
df["log_value"] = np.log(df["value"])
df = df.groupby("id").mean()
```

- Each line modifies or reassigns `df`
- State changes over time
- Order matters a lot

## R

``` r
df |>
  filter(value > 0) |>
  mutate(log_value = log(value)) |>
  group_by(id) |>
  summarise(across(everything(), mean))
```

- Each step returns a new object
- No mutation in place
- The pipeline reads top to bottom

> **NOTE:**
>
> Think of `|>` as saying:  
> “take the result so far, **and then** apply the next transformation”.

------------------------------------------------------------------------

## 3 Core object mapping (Python → R)

| Python             | R                   |
|--------------------|---------------------|
| `pandas.DataFrame` | `tibble`            |
| `Series`           | vector              |
| `NaN`              | `NA`                |
| `df.copy()`        | usually unnecessary |
| `for row in df`    | avoid               |
| `df.groupby()`     | `group_by()`        |
| method chaining    | pipe (`|>`)         |
| `df.reset_index()` | rarely needed       |

> **TIP:**
>
> In R, columns are **vectors**, not mini-dataframes.  
> This is one of the biggest conceptual differences — and one of R’s strengths.

------------------------------------------------------------------------

## 4 Mutation: the silent trap for Python users

## Python

``` python
df["x"] = df["x"] * 2
```

This modifies `df` in place.

## R

``` r
df |>
  mutate(x = x * 2)
```

This **does not** modify `df` unless you reassign it.

Correct usage:

``` r
df <- df |>
  mutate(x = x * 2)
```

> **WARNING:**
>
> If you forget to reassign in R, **nothing happens**.  
> This is the most common source of “why didn’t my code work?” for Python users.

------------------------------------------------------------------------

## 5 Loops: just because you can, doesn’t mean you should

## Python

``` r
# Python-style thinking applied to R (not recommended)
for (i in 1:nrow(df)) {
  df$x[i] <- df$x[i] * 2
}
```

## R

``` r
df |>
  mutate(x = x * 2)
```

> **TIP:**
>
> If you feel the urge to write a `for` loop in R, stop and ask:  
> “Is this a vectorized operation?”
>
> In most cases, the answer is **yes**.

------------------------------------------------------------------------

## 6 Indexing: brackets vs verbs

## Python

``` python
df.iloc[0]
df.loc[df["x"] > 0]
```

## R

``` r
df[1, ]
df |>
  filter(x > 0)
```

> **NOTE:**
>
> Base R indexing exists, but in this course we will prefer tidyverse verbs  
> because they are clearer and less error-prone.

------------------------------------------------------------------------

## 7 Equality, assignment, and naming

- `<-` is the standard operator for assignment in this course  
- `=` is used **only** for function arguments
- `==` is for comparison
- Names are case-sensitive
- Avoid spaces in column names (or use backticks)

> **TIP:**
>
> Using `<-` consistently makes it easier to visually distinguish  
> **assignment** from **function arguments**, especially in longer pipelines.

------------------------------------------------------------------------

## 8 Factors: the weird thing you didn’t ask for

R has a special type called `factor` (categorical variable).

Sometimes you will see:

``` r
str(df)
```

and a column is a factor when you expected a string.

> **NOTE:**
>
> For now:
>
> - don’t panic
> - use `as.character()` if needed
> - we will be explicit about factors when they matter

------------------------------------------------------------------------

## 9 What you actually need for this course

You do **not** need to become an R expert.

You need to be comfortable with:

- `tibble`
- `filter()`
- `mutate()`
- `summarise()`
- `group_by()`
- pipes (`|>`)

Everything else is secondary.

------------------------------------------------------------------------

## 10 Final reassurance

> **TIP:**
>
> If you are fluent in Python, you already have the hard skills:
>
> - data thinking
> - debugging intuition
> - abstraction
>
> R is just a different dialect.

Once the mental model clicks, the rest of the course will feel much lighter.

Back to top
