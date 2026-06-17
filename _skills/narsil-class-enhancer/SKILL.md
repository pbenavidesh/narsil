---
name: narsil-class-enhancer
description: >
  Transforms a raw in-class .qmd or pasted R code into a polished,
  publication-ready document for the narsil Quarto course website.
  Use when Pablo uploads or pastes a rough class exercise that needs
  formatting, English prose, complete YAML, code cleanup, missing
  pedagogical steps added, and an exercise section. Triggers on
  phrases like "format this for Narsil", "clean up this class
  exercise", "polish this notebook", "add the exercise section",
  "sube esto a Narsil", "formatea este ejercicio de clase", or any
  request to transform raw class material into a ready-to-publish
  Narsil document. Always produces a single combined file (class
  examples + exercise).
---

# narsil Class Material Enhancer

Transforms a raw in-class `.qmd` (or pasted code) into a
publication-ready `topic-exercise` document for `docs/exercises/posts/`
on the narsil course website.

---

## Overview

The typical input is a `.qmd` written during class — functional code,
minimal prose (often in Spanish), incomplete YAML, no callouts or
annotations, possibly missing pedagogical steps, and no exercise
section. Pablo may or may not describe the homework in the prompt.

The output is a single polished `.qmd` that:

- Has minimal correct YAML (no duplication of `_quarto.yml` globals)
- Has all code following narsil conventions
- Has English prose with callouts and code annotations
- Has any missing pedagogical steps added (split, diagnostics, accuracy)
- Ends with a proposed exercise section for Pablo to validate
- Is ready to copy-paste into `docs/exercises/posts/`

No changes to `_quarto.yml` are needed.

---

## Elicitation

Before starting, check only for what you cannot infer from the file:

1. **Module number** (1–4) — infer from topic if possible; ask if
   genuinely ambiguous.
2. **Verbal context** — if the file has unexplained jumps (e.g., a
   model choice with no motivation), ask before inventing content.

Do **not** ask for the exercise description upfront. Instead, propose
exercises based on the content and ask Pablo to validate (see
[Exercise section](#exercise-section)).

---

## YAML

The `_quarto.yml` already defines globally: `df-print`, `execute`
(echo, warning, freeze), `date-modified`, `format: html` (theme, css,
toc, number-sections, code-fold, code-annotations, etc.), `lightbox`,
`highlight-style`, and `code-overflow`. Do not duplicate any of these.

Use only this minimal frontmatter:

```yaml
---
title: "Title in English"
description: "One-sentence description for the listing card."
date: YYYY-MM-DD
format: html
categories:
  - topic-exercise
  - module-X
---
```

The `format: html` declaration is **required** — without it Quarto
inherits both `html` and `revealjs` from `_quarto.yml` and fails to
render exercise documents.

Add `freeze: false` only when the document calls `tq_get()` or any
live FRED/financial data source. In that case:

```yaml
---
title: "Title in English"
description: "One-sentence description for the listing card."
date: YYYY-MM-DD
freeze: false
format: html
categories:
  - topic-exercise
  - module-X
---
```

### Field rules

**`title`** — translate to English. Concise and descriptive.
Example: "Suavización exponencial" → "ETS Forecasting".

**`description`** — one sentence stating what the student will do.

**`date`** — use the class date if provided; otherwise today's date.

**`categories`** — always `topic-exercise` + the inferred module tag
(`module-1` through `module-4`).

---

## Setup chunk

Replace any bare `library()` call at the top with two chunks.
`message: false` and `warning: false` are set globally in
`_quarto.yml` — do not repeat them in individual chunks.

**Chunk 1 — visible to students**: packages only.

```r
#| label: setup

library(tidyverse)
library(fpp3)
```

Add `tidyquant` and/or `plotly` here if used in student-visible code.

**Chunk 2 — narsil infrastructure**: always `include: false`.

```r
#| label: narsil-setup
#| include: false

source(here::here("R/narsil_theme.R"))
theme_set(theme_narsil())
```

Packages only needed for narsil render chunks (e.g., `plotly` when
used exclusively in `echo: false` chunks) go here instead of chunk 1.

> **Global narsil visibility rule**: No visible chunk (`echo: true`,
> the default) anywhere on the narsil site may call narsil-specific
> functions: `theme_narsil()`, `theme_narsil_dark()`, `scale_narsil()`,
> `scale_narsil_dark()`, `gg_to_plotly_narsil()`, or any standalone
> `theme_narsil()` reset call. All narsil rendering infrastructure must
> live in chunks with `echo: false` or `include: false`.
>
> When a plot in the instructor-provided section (EDA, series overview)
> would be useful for students to replicate, use the **student/render
> pair pattern**:
>
> - **Chunk A** (`eval: false`, no `echo` override → visible): plain
>   ggplot2 code the student can copy and run.
> - **Chunk B** (`echo: false`, `eval: true`): the actual narsil render
>   (base plot + `renderings: [light, dark]` or `scale_narsil()`) that
>   produces the plot shown on the site.
>
> Label chunk B by appending `-render` to chunk A's label.
> Example: `autoplot-student` / `autoplot-render`.

---

## Code cleanup

Apply these fixes to every chunk:

| Issue | Fix |
|---|---|
| `name = value` assignment (e.g., `h = 105`) | `name <- value` |
| `%>%` | `\|>` |
| Spanish variable names | Translate to English (see below) |
| Chunk with no label | Add `#\| label: descriptive-label` |
| Spurious empty `#` header | Remove entirely |
| Bare `library()` call outside setup | Move to setup chunk |

**`plotly`** — no wrapper needed; these documents are HTML-only.

**`code-line-numbers`** — do not add by default. Only when walking
through a chunk step by step with something specific worth emphasizing.

### Comments → annotations

When a chunk contains inline `# comment` style notes, evaluate whether
they are better expressed as numbered code annotations (`#<1>`, `#<2>`).
Convert when the comment explains *what a line does* in a way that
benefits from prose below the chunk. Leave short, obvious comments
(e.g., `# fit model`) as-is or remove them if the annotation covers it.

```r
gold_tsb |>
  fill_gaps() |>           #<1>
  as_tsibble(index = date) #<2>
```
1. Fill implicit gaps introduced by weekends and holidays.
2. Confirm the tsibble structure after gap-filling.

---

## Variable naming

Translate Spanish base names to short English equivalents.
Apply consistently throughout the entire document.

| Suffix | Meaning |
|---|---|
| `_raw` | Raw data from source |
| `_tsb` | tsibble |
| `_train` | Training split |
| `_test` | Test split |
| `_fit` | Fitted mable |
| `_fc` | Forecasts |
| `_aug` | Augmented residuals |
| `_dcmp` | Decomposition |
| `_accu` | Accuracy table |
| `_p` | Base ggplot object (for rendering) |

For the base name, use a short English abbreviation of the series name.
Examples: `millas_tsb` → `vm_tsb` (vehicle miles); `gold_raw` stays
unchanged. Apply model variant suffixes when multiple specs exist:
`vm_fit_ets`, `vm_fit_stl`, etc.

---

## Plot rendering conventions

All HTML plots in narsil use a dual light/dark rendering pattern to
match the Gondor (light) and Mordor (dark) site themes. These helpers
are available after `source(here::here("R/narsil_theme.R"))` in setup.

### Base plot + render chunk pattern

Split every plot into two chunks:

**Chunk A — base plot** (`output: false`, visible to students):

```r
#| label: series_viz
#| output: false

series_p <- data |>
  autoplot(var) +
  labs(title = "...")
```

**Chunk B — render** (`renderings: [light, dark]`, `echo: false`):

```r
#| label: series_viz_render
#| renderings: [light, dark]
#| echo: false

series_p + scale_narsil()
series_p + scale_narsil_dark()
```

Render chunk labels always append `_render` to the base chunk label.

### ggplotly pattern

```r
#| label: series_render
#| renderings: [light, dark]
#| echo: false

ggplotly(series_p + scale_narsil()) |> gg_to_plotly_narsil()
ggplotly(series_p + scale_narsil_dark()) |> gg_to_plotly_narsil(dark = TRUE)
```

### theme() overrides

`scale_narsil()` calls `theme_narsil()` which resets the complete
theme. Re-add any manual `theme()` overrides in the render chunks:

```r
series_p + scale_narsil() + theme(legend.position = "none")
series_p + scale_narsil_dark() + theme(legend.position = "none")
```

### Exceptions

| Case | Pattern |
|---|---|
| `gg_season()` with many years (continuous colour) | `plot_p + theme_narsil()` / `theme_narsil_dark()` |
| `gg_tsdisplay()` (patchwork + S7 conflict) | Single chunk, no renderings |
| Plots with more colour levels than 6-colour palette | `theme_narsil()` / `theme_narsil_dark()` only |

### Non-renderings plots after render chunks

Any plot chunk **without** renderings that appears after a render chunk
in the same document must call `theme_narsil()` as its first line to
reset geom defaults before producing the plot. Always add
`#| results: hide` to suppress the printed theme object — without it,
R prints a 144-element list to the document:

```r
#| label: gg_tsdisplay
#| results: hide

theme_narsil()
aus_production |>
  gg_tsdisplay(Gas, plot_type = "season")
```

`results: hide` suppresses text/print output only — the plot still
renders normally.

---

## Prose and document structure

### Language
All prose is in **English**. Translate Spanish comments and expand
them — a one-line Spanish comment becomes one or two English sentences.

### Top-level structure

1. **Introduction** (2–3 sentences) — what will be covered and the
   pedagogical goal of each example.
2. **[Example 1 title]** — first class example, fully documented.
3. **[Example 2 title]** — second class example (if present).
4. **Exercise** — proposed exercise section.

### Per-example internal flow

Each class example section should include, in order:

1. Brief paragraph on what the series is and what pattern to expect.
2. Data loading and tsibble conversion, with prose explaining any
   cleaning steps (gap filling, date format conversion, etc.).
3. **Train/test split** — if missing, add it. Include a sentence
   stating the chosen horizon and why.
4. **Visualization** — `autoplot()` of the training series. If missing,
   add it. Include a brief interpretive remark.
5. Transformation selection (Box-Cox, log) if applicable — include
   motivation.
6. Model fitting with a callout explaining model choices.
7. Forecasting plot.
8. **Residual diagnostics** — if missing, add `gg_tsresiduals()` for
   the primary model(s). Include a brief interpretive remark on whether
   residuals look like white noise.
9. **Accuracy evaluation** — if missing or incomplete, add
   `accuracy(mable, full_tsibble)`. Always pass the full tsibble (not
   just the test set) so MASE/RMSSE denominators are correct. Note this
   in a `callout-warning` if the call in the original file was
   incorrect.

### Which steps to add vs. note

- **Add silently**: visualization, train/test split, residual
  diagnostics, and accuracy if entirely absent.
- **Note to Pablo**: if the skip seemed intentional (e.g., a series
  with no clear seasonality and `gg_tsresiduals()` was skipped on
  purpose), flag it with a comment in the output rather than adding it
  blindly.

### Code annotations

Add numbered annotations (`#<1>`, `#<2>`) when a chunk has multiple
non-obvious steps. Annotate only the lines that genuinely need
explanation.

### Callouts

Use callouts strategically. No more than two per major section.

| Type | When to use |
|---|---|
| `callout-important` | Key pedagogical point the student must not miss |
| `callout-warning` | Common pitfall (e.g., passing test set to `accuracy()`) |
| `callout-note` | Additional context (e.g., what a FRED ticker means) |
| `callout-tip` | Hints inside the exercise section only |

---

## Exercise section

**Propose, do not wait.** If Pablo has not described the homework,
generate 3–4 exercises based on logical extensions of the class
content and ask Pablo to validate before considering the document
final. State clearly: "Here are the proposed exercises — let me know
if you want to adjust any of them."

If Pablo has already described the homework in the prompt, use that
description to write the exercises.

### Solution policy

**Do not include solution blocks.** These documents are published on
Narsil and are visible to students while homework is active. Omit
`callout-tip collapse="true" ## Solution` entirely. For the scaffolded
Exercise 1, a `callout-tip ## Hint` is allowed; for open exercises, no
hints either.

Pablo can add solutions manually after the submission deadline if
desired.

### Structure

```markdown
# Exercise

[1–2 sentences connecting the exercise to the class examples and
stating the learning objective.]

## Exercise 1 — [short title]

[Scaffolded: provide starting-point code; ask the student to extend
or modify it. A hint callout is allowed here.]

:::{.callout-tip}
## Hint
[hint content]
:::

## Exercise 2 — [short title]

[Open: problem statement only. No hints, no solutions.]

## Exercise 3 — [short title]

[Open.]

## Exercise 4 — [short title]  ← optional

[Open. Higher difficulty — graduate-level stretch goal.]
```

### Exercise design principles

- Exercise 1 should be scaffolded: provide the starting-point code
  (typically the class baseline model) and ask the student to extend
  one specific component.
- Exercises 2–3 should be open and progressively harder.
- Exercise 4, if included, should be a stretch goal appropriate for
  graduate students.
- Always end with a comparison step: students should evaluate their
  models against the class baseline using `accuracy()`.

### `decomposition_model()` exercises

When the class content involves `decomposition_model()`, exercises
should explore the modular substitution principle: any decomposition
component (`season_adjust`, `season_year`, `trend`, etc.) can be
modeled with any compatible method — not just ETS. What is available
depends on which models have been covered so far in the course. Common
substitutions:

- Replace `RW(season_adjust ~ drift())` with `ETS(season_adjust)` or
  `ARIMA(season_adjust)`
- Replace `SNAIVE(season_year)` with `ETS(season_year)` or a seasonal
  ARIMA term
- Mix methods across components (e.g., ARIMA on `season_adjust`,
  SNAIVE on `season_year`)

The key concept to reinforce: `decomposition_model()` is a *wrapper*
that lets you combine any set of models, one per component. The
exercise should make students try multiple combinations and compare
them against the baseline.

---

## Output instructions

1. Output the complete `.qmd` using 4-backtick fences for easy
   copy-paste.
2. State the recommended file path:
   `docs/exercises/posts/ex_module#_short_topic.qmd`
3. List any assumptions made: inferred module, inferred class date,
   variable renames applied, steps added (split/diagnostics/accuracy),
   verbal context inferred.
4. If `freeze: false` was set, remind Pablo to commit the `_freeze/`
   directory after the first local render so GitHub Actions picks it up.
5. If exercises were proposed rather than specified, explicitly ask
   Pablo to validate them before using the document.
