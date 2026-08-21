---
name: narsil-doc-creator
description: >
  Creates new .qmd documents for the narsil Quarto course website
  (https://github.com/pbenavidesh/narsil). Use this skill whenever
  the user asks to create, add, or generate a new document for the
  "More" section or the "Exercises" section of the course. Triggers
  on phrases like "create a More document about X", "add a module 2
  exercise", "new tidyquant tutorial", "create the module 3 review",
  "write a stats refresher on X", "add a class notebook for session Y",
  or any request to add supplementary or exercise content to the
  narsil website. Also triggers when the user says "crea un documento
  de More", "agrega un ejercicio", or similar in Spanish.
---

# narsil Document Creator

Creates well-structured `.qmd` files for two sections of the narsil
course website: **More** (supplementary tutorials and references) and
**Exercises** (class notebooks, topic exercises, and module reviews).

No changes to `_quarto.yml` are needed — both sections use
auto-discovery via Quarto listings.

---

## Repo and site URLs

- Repo: https://github.com/pbenavidesh/narsil
- Published site: https://pbenavidesh.github.io/narsil/

---

## Directory structure

```
docs/
  more/
    r-tools/           # R packages, tidyverse workflows, cheatsheets
    stats/             # Statistical prerequisites and refreshers
    elendil-ta/        # The course AI teaching assistant — do not add files here
    index.qmd          # Listing page — do not modify
  exercises/
    module_1/
    module_2/
    module_3/
    module_4/
    class-notes/       # In-class notebooks (one per session, as needed)
    index.qmd          # Listing page — do not modify
```

### Subdirectory rule

**A subdirectory is not created until it holds three documents.** Below
that threshold, files sit flat at the More root (`docs/more/name.qmd`).
When a topic accumulates a third document, move all three into a new
subfolder in one commit and fix the inbound links.

Only the folders listed above exist. Do not write into a folder that is
not there — place the file at the More root instead and say so in the
output.

---

## Naming convention

All files and R variables use `snake_case`.

| Section | Pattern | Example |
|---|---|---|
| More (any subcategory) | `short_descriptive_name.qmd` | `tidyquant_intro.qmd` |
| Class notebook | `cn_module#_short_topic.qmd` | `cn_module2_ets_basics.qmd` |
| Topic exercise | `ex_module#_short_topic.qmd` | `ex_module2_arima.qmd` |
| Module review | `review_module#.qmd` | `review_module2.qmd` |

---

## Categories

### More documents

Every More document must carry **at least one** category — the listing
page filters on them.

For a document inside a subfolder, use the folder name. For a document
at the More root, use the category that describes it.

```yaml
categories:
  - r-tools  # or: stats, refreshers
```

Valid category values: `r-tools`, `stats`, `refreshers`.

### Exercise documents
Exactly two categories — type + module:

```yaml
categories:
  - class-notebook  # or: topic-exercise, module-review
  - module-2        # module-1 through module-4
```

Valid type values: `class-notebook`, `topic-exercise`, `module-review`
Valid module values: `module-1`, `module-2`, `module-3`, `module-4`

---

## YAML templates

### More document

```yaml
---
title: "Document Title"
description: "One-sentence description shown in the listing card."
date: YYYY-MM-DD
date-modified: last-modified
format:
  html: default
categories:
  - [r-tools | stats | refreshers]
draft: false
---
```

### Exercise document

```yaml
---
title: "Document Title"
description: "One-sentence description shown in the listing card."
date: YYYY-MM-DD
date-modified: last-modified
format:
  html: default
categories:
  - [class-notebook | topic-exercise | module-review]
  - [module-1 | module-2 | module-3 | module-4]
draft: false
---
```

When the document calls `tq_get()` or any live financial/FRED data
source, add `params: fred-data: true`. Do **not** use `freeze: false`
— the site uses `freeze: auto` globally and FRED document invalidation
is controlled via `workflow_dispatch` in GitHub Actions:

```yaml
---
title: "Document Title"
description: "One-sentence description shown in the listing card."
date: YYYY-MM-DD
date-modified: last-modified
params:
  fred-data: true
format:
  html: default
categories:
  - [class-notebook | topic-exercise | module-review]
  - [module-1 | module-2 | module-3 | module-4]
draft: false
---
```

### Module document (dual-format)

Module documents (those under `docs/modules/`) render as both HTML
and RevealJS. Always include both formats explicitly and set
`output-file` for the RevealJS output to avoid naming conflicts:

```yaml
---
title: "Document Title"
format:
  html:
    other-links:
      - text: FPP3 Chapter X
        href: https://otexts.com/fpp3/...
  revealjs:
    output-file: short_name_pres.html
---
```

> **Critical rule**: Every `.qmd` in the narsil project must declare
> `format:` explicitly. Without it, Quarto inherits both `html` and
> `revealjs` from `_quarto.yml` and the build fails when trying to
> move the RevealJS output to `_site/`. Non-module documents (More,
> Exercises) must always use `format: html: default` only.

---

## Standard setup chunk

The repo convention is a **hidden `pkgs` chunk** plus, when there is
something worth naming, a **visible `pkgs_special` chunk**. There is no
`narsil-setup` chunk anywhere in the project.

### The hidden `pkgs` chunk

Always `include: false`. It carries the routine `library()` calls —
the ones every document loads and no student needs to be told about —
together with the theme setup.

```r
#| label: pkgs
#| message: false
#| include: false

library(tidyverse)
library(fpp3)

source(here::here("R/narsil_theme.R"))
theme_set(theme_narsil())
```

`fpp3` belongs here whenever the document touches `tsibble`, `fable`,
or `feasts`. Add `patchwork` here too — it is infrastructure, not
content. `message: false` is repeated on this chunk in every module
file; keep it for consistency even though the global option covers it.

### The visible `pkgs_special` chunk

Only for packages worth naming to students: the ones they must install
themselves, or whose presence explains something about the document.
Each `library()` line carries a `#<N>` annotation saying why.

```r
#| label: pkgs_special
#| message: false

library(plotly)    #<1>
library(tidyquant) #<2>
```
1. For interactive plots.
2. For retrieving `mexretail` from FRED.

Omit this chunk entirely when there is nothing special to name — do
not pad it with `tidyverse` and `fpp3` just to have a visible chunk.

In **module documents** (dual-format), wrap `pkgs_special` in
`:::{.content-visible unless-format="revealjs"}` so the package list
does not consume a slide. In **More and Exercise documents** there is
no revealjs output, so no wrapper.

Packages needed only inside `echo: false` render chunks go in `pkgs`,
never in `pkgs_special`.

> **Global narsil visibility rule**: No visible chunk (`echo: true`,
> the default) anywhere on the narsil site may call narsil-specific
> functions: `theme_narsil()`, `theme_narsil_dark()`, `scale_narsil()`,
> `scale_narsil_dark()`, `gg_to_plotly_narsil()`, or any standalone
> `theme_narsil()` reset call. All narsil rendering infrastructure must
> live in chunks with `echo: false` or `include: false`.
>
> When a plot in the instructor-provided section would be useful for
> students to replicate, use the **student/render pair pattern**:
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

## R code standards

All R code must follow tidyverse conventions. Base R alternatives
should be avoided unless no tidyverse equivalent exists. Specific rules:

- Always use the native pipe `|>`, never magrittr `%>%`
- Use `dplyr` verbs for data manipulation (`filter`, `mutate`,
  `summarise`, `select`, `arrange`, `left_join`, etc.)
- Use `ggplot2` for all static visualizations
- Use `tsibble` for time series data structures
- Use `fable` for forecasting models
- Use `feasts` for feature extraction and visualization

### Code annotations vs. line highlighting

Use **numbered code annotations** (`#<1>`, `#<2>`, etc.) when you need
to explain what specific lines do in prose below the chunk. These work
in both HTML and RevealJS and render as clickable callouts:

````markdown
```{r}
aus_production |>           #<1>
  filter_index("2000 Q1" ~ .) |>  #<2>
  model(STL(Beer ~ trend() + season())) #<3>
```
1. Start with the full dataset.
2. Keep only observations from Q1 2000 onward.
3. Fit an STL decomposition model.
````

Use **line highlighting** (`code-line-numbers`) when you want to draw
visual attention to specific lines during a walkthrough — without
adding explanatory prose for every line. This is especially effective
in RevealJS slides for step-by-step code reveals, but also works in
HTML (where all specified lines are highlighted simultaneously rather
than sequentially).

**Syntax:**

```r
#| code-line-numbers: "3|5-6|9"
```

- Pipe-separated (`|`) → sequential animation in RevealJS
- Comma-separated (`,`) → simultaneous highlight in both HTML and RevealJS
- Ranges (`5-6`) → highlight a block of consecutive lines
- Combine: `"1,2|5-7|10"` → step 1 highlights lines 1 and 2 together, etc.

**When to use each:**

| Situation | Use |
|---|---|
| Explaining what each line does | Code annotations (`#<1>`) |
| Walking through a chunk step by step in slides | Line highlighting (`code-line-numbers`) |
| Drawing attention to one key line in HTML | Line highlighting with a single range |
| Both explaining and stepping through | Annotations for prose, highlighting for emphasis |

**Do not add `code-line-numbers` to every chunk by default** — use it
only when the highlighting adds genuine pedagogical value.

---

## R variable naming conventions

Use these suffixes consistently in all R code:

| Suffix | Meaning | Example |
|---|---|---|
| `_train` | Training split | `beer_train` |
| `_test` | Test split | `beer_test` |
| `_fit` | Fitted mable | `beer_fit` |
| `_fc` | Forecasts | `beer_fc` |
| `_aug` | Augmented residuals | `beer_aug` |
| `_dcmp` | Decomposition components | `beer_dcmp` |
| `_accu` | Accuracy table | `beer_accu` |

For model variants, append a descriptive suffix:
`beer_fit_ets`, `beer_fit_arima`, `beer_fit_stl`.

Variables used only once inline should not be assigned.
Plot base objects use the `_p` suffix (e.g., `tourism_p`, `dcmp_p`,
`gas_season_p`). See [Plot rendering conventions](#plot-rendering-conventions)
for how these are used in render chunks.

---

## Plot rendering conventions

All HTML plots in narsil use a dual light/dark rendering pattern to
match the Gondor (light) and Mordor (dark) site themes. These helpers
are available after `source(here::here("R/narsil_theme.R"))`.

### Base plot + render chunk pattern

Split every plot into two chunks:

**Chunk A — base plot** (`output: false`, echo visible to students):

```r
#| label: tourism_viz
#| output: false

tourism_p <- tourism |>
  filter(State == "Tasmania") |>
  autoplot(Trips) +
  labs(title = "Tasmanian tourism")
```

**Chunk B — render** (`renderings: [light, dark]`, `echo: false`):

```r
#| label: tourism_viz_render
#| renderings: [light, dark]
#| echo: false

tourism_p + scale_narsil()
tourism_p + scale_narsil_dark()
```

Render chunk labels always append `_render` to the base chunk label.

### Helper functions

| Function | Effect |
|---|---|
| `scale_narsil()` | `theme_narsil()` + `scale_colour_narsil()` — light mode |
| `scale_narsil_dark()` | `theme_narsil_dark()` + `scale_colour_narsil(dark=TRUE)` — dark mode |

### theme() overrides

`scale_narsil()` calls `theme_narsil()` which resets the complete
theme, overriding any `theme()` calls in the base plot. Re-add manual
`theme()` overrides in the render chunks:

```r
tourism_p + scale_narsil() + theme(legend.position = "none")
tourism_p + scale_narsil_dark() + theme(legend.position = "none")
```

### ggplotly pattern

When converting a ggplot to plotly:

```r
#| label: jj_render
#| renderings: [light, dark]
#| echo: false

ggplotly(jj_p + scale_narsil()) |> gg_to_plotly_narsil()
ggplotly(jj_p + scale_narsil_dark()) |> gg_to_plotly_narsil(dark = TRUE)
```

Preserve `dynamicTicks = TRUE` and other `ggplotly()` arguments.

### Exceptions

| Case | Pattern |
|---|---|
| `gg_season()` with many years (continuous colour) | `plot_p + theme_narsil()` / `theme_narsil_dark()` |
| `gg_subseries()`, `gg_tsresiduals()` | `scale_narsil()` / `scale_narsil_dark()` |
| `gg_tsdisplay()` (patchwork + S7 conflict) | Single chunk, no renderings |
| Plots with more colour levels than the 6-colour palette | `theme_narsil()` / `theme_narsil_dark()` only |

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



When referencing a module document, use a relative path with an
explicit placeholder for the anchor:

```markdown
<!-- TODO: verify anchor -->
[Time Series Decomposition](../../modules/module_1/02_ts_dcmp/ts_dcmp.qmd)
```

Module document paths follow this pattern:
`docs/modules/module_#/##_short_name/filename.qmd`

---

## Quarto callouts

Use callouts strategically — not decoratively:

- `callout-tip` — hints, best practices, useful shortcuts
- `callout-note` — additional context or side information
- `callout-warning` — common pitfalls or errors to avoid
- `callout-important` — key concepts the student must not miss

A callout must carry content the surrounding prose does not. A callout
that restates the paragraph above it in a coloured box is decoration.

---

## Prose standard

`docs/more/r-tools/setup.qmd` is the reference: 199 lines, zero tics.
Read it before writing.

### Headers

Every header names the content of its section. Do not use:

- **Rhetorical-question headers** — "Why does this matter?", "What
  problem does this solve?", "Why should you care?"
- **"Why X matters" / "Why X exists" / "Understanding X"** — these are
  AI tics and are rejected on sight.

Write "How KPSS reads its p-value", not "Understanding the KPSS
p-value". Write "What a hypothesis test asks", not "Why hypothesis
testing matters".

### Banned openers, closers, and constructions

- The optional-but-recommended opener: "This document is **optional**,
  but strongly recommended."
- A "Where this shows up in the course" section.
- A "What you do not need yet" section.
- A "Takeaway" / "Key takeaway" / "Final takeaway" closer.
- The antithesis pivot: "X is not Y — it is Z."
- "The key insight is…", "At its core…", "Here's the thing:",
  "Let's dive in."

End the document on its last substantive section or its exercise. Do
not summarise what the reader just read.

---

## Content guidelines by document type

### `stats` and `refreshers` documents

Both categories use the same structure. `stats` covers prerequisites
the course builds on directly; `refreshers` covers concepts the course
*uses* without ever defining them.

**Audience**: assume the student knows nothing about the topic,
even if they theoretically should.

**Structure**:
1. **TL;DR / Quick Reference** — key formula or concept in 2-3 lines,
   at the very top. The student who just needs a reminder stops here.
2. **A motivating section** — connect the concept to forecasting, using
   a concrete case from the course. Head it with the actual content of
   the section, not with a question about its importance. If the
   section is about what a hypothesis test asks, the header says
   "What a hypothesis test asks".
3. **Explanation** — build intuition first, formalism second. Use
   plain language before introducing notation.
4. **R implementation** — practical code with a real dataset and
   numbered annotations. All code must be tidyverse-compatible.
5. **Short exercise** — 1-2 questions without solutions, for
   self-checking.

---

### `quarto` documents

> No `quarto/` folder exists yet. Until three such documents exist, a
> Quarto document sits flat at the More root.

**Audience**: assume no prior Quarto knowledge.

**Structure**:
1. **TL;DR / Quick Reference** — the syntax or option being covered,
   at the top.
2. **The problem it solves** — headed by the problem itself, not by a
   question about it.
3. **Step-by-step walkthrough** — with code examples.
4. **Link to official docs** — always include a reference to the
   relevant Quarto documentation page (https://quarto.org/docs/).

---

### `r-tools` documents

**Audience**: assume the student is new to R and tidyverse,
possibly coming from Python. Do not assume prior R knowledge.

**Structure**:
1. **What is this tool and why use it?** — one short paragraph.
2. **Installation / setup** — if needed.
3. **Tutorial** — narrative walkthrough of the main use cases with
   a real dataset. Code-forward, with numbered annotations.
   All code must follow tidyverse conventions.
4. **Common patterns** — a cookbook section with short self-contained
   snippets for the most frequent tasks.
5. **Cheatsheet link** — if an official Posit cheatsheet exists,
   link to it from https://posit.co/resources/cheatsheets/.

---

### `tidyverse-applied` documents

> No `tidyverse-applied/` folder exists yet. Same rule: flat at the
> More root until there are three.

**Audience**: assume the student is new to R and tidyverse,
possibly coming from Python or base R. Do NOT force a connection
to forecasting — these documents serve other courses and domains.

**Structure**:
1. **Context** — what problem from another course or domain this
   solves, and why the tidyverse approach is better.
2. **The tidyverse approach** — contrast explicitly with whatever
   base R or legacy approach the student may have seen elsewhere.
3. **Walkthrough** — practical code with a dataset relevant to
   the target domain. All code must follow tidyverse conventions.
4. **What changes in practice** — what the student can now do
   differently. Not a "Key takeaways" list.

---

### `forecasting-plus` documents

> No `forecasting-plus/` folder exists yet. Same rule: flat at the
> More root until there are three.

**Audience**: assume the student has completed the relevant course
module. These documents extend, not replace, core content.

**Structure**:
1. **Connection to the course** — explicit link to the module or
   concept being extended. Use a cross-document link with placeholder.
2. **What this tool adds** — what the course module cannot do that
   this tool can.
3. **Walkthrough** — practical code, same dataset as the referenced
   module if possible. All code must follow tidyverse conventions.
4. **Comparison** — brief side-by-side with the course approach.

---

### `class-notebook` documents

Mirrors what was done in class. Code-forward. All code must follow
tidyverse conventions.

**Structure**:
- Setup chunk (hidden)
- Code sections matching the class flow, with numbered annotations
- No solutions
- 2-3 **Reflection questions** at the end — no answers provided.
  Open-ended prompts that invite the student to experiment with
  the code or think critically about the output.

---

### `topic-exercise` documents

Guided practice on a specific topic. Use a dataset different from
the one used in class. All code must follow tidyverse conventions.

**Structure**:
- Brief introduction stating the learning objective
- **Exercise 1** (scaffolded): code partially provided, student
  completes the gaps. Include hint callouts where appropriate:

```markdown
:::{.callout-tip}
## Hint
[hint content here]
:::
```

- **Exercises 2–4** (open): problem statement only, student writes
  all code. No hints.
- Each exercise ends with a collapsed solution:

```markdown
:::{.callout-tip collapse="true"}
## Solution
[solution content here]
:::
```

Total: 3–4 exercises per document.

---

### `module-review` documents

Integrative problem covering the full module. Higher difficulty.
The student must decide what to apply and in what order — not just
how to apply it. All code must follow tidyverse conventions.

**Structure**:
- **Dataset introduction** — a dataset not used in class or
  topic exercises, with enough context for the student to
  understand it.
- **Problem parts a, b, c, d...** — sequential, each building on
  the previous. Parts should span the key topics of the module.
- No hints anywhere.
- Each part ends with a collapsed solution:

```markdown
:::{.callout-tip collapse="true"}
## Solution — Part [X]
[solution content here]
:::
```

---

## Output instructions

1. Generate the complete `.qmd` file content in raw markdown
   using 4-backtick fences for easy copy-pasting.
2. State the exact recommended file path:
   - More: `docs/more/[filename].qmd`, or
     `docs/more/[subfolder]/[filename].qmd` only if that subfolder
     already exists and already holds documents
   - Exercises: `docs/exercises/[folder]/[filename].qmd`
3. No changes to `_quarto.yml` are needed.
