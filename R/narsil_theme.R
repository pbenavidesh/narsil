# narsil_theme.R
# -----------------------------------------------------------------------------
# Shared ggplot2 / plotly theming for the narsil Time Series Forecasting course.
#
# This file defines a single source of truth for the course colour palettes
# (light = "Gondor", dark = "Mordor") and the ggplot2 theme used across all
# course documents, plus helpers for styling plotly figures.
#
# The light palette here must stay in sync with the CSS custom properties
# (--narsil-c1 .. --narsil-c6) defined in scss/narsil.scss.
#
# To use in a .qmd setup chunk:
#   source(here::here("R/narsil_theme.R"))
#   theme_set(theme_narsil())
# -----------------------------------------------------------------------------

# Course colour palettes ------------------------------------------------------
.narsil_pal <- list(
  light = list(
    bg = "#F4F6F9",
    bg_panel = "#E8ECF2",
    fg = "#2A2520",
    grid = "#D5D0C6",
    palette = c(
      "#0072B2",  # Anduin
      "#E69F00",  # Mithril
      "#009E73",  # Ithilien
      "#D55E00",  # Anor
      "#56B4E9",  # Pelargir
      "#CC79A7",  # Númenor
      "#F0E442",  # Rohan
      "#1A7A6E",  # Enedwaith
      "#7B2D8B",  # Rhûn
      "#B8860B"   # Harad
    )
  ),
  dark = list(
    bg = "#2A2A2A",
    bg_panel = "#303030",
    fg = "#E8DDD0",
    grid = "#555566",
    palette = c(
      "#E8651A",  # Orodruin
      "#E2C12B",  # Eye of Sauron
      "#A569BD",  # Morgul
      "#D4548C",  # Palantír
      "#5DADE2",  # Ithildin
      "#AAB7B8",  # Gorgoroth
      "#E8565A",  # Grond
      "#45C4A0",  # Shelob
      "#C084FC",  # Nazgûl
      "#F5C842"   # Smaug
    )
  )
)

narsil_pal <- function(mode = "light") .narsil_pal[[mode]]

# Internal theme builder ------------------------------------------------------
.build_theme <- function(mode, base_size) {
  p <- .narsil_pal[[mode]]

  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = p$bg, colour = NA),
      panel.background = ggplot2::element_rect(fill = p$bg_panel, colour = NA),
      panel.grid.major = ggplot2::element_line(
        colour = p$grid,
        linewidth = 0.4
      ),
      panel.grid.minor = ggplot2::element_line(
        colour = p$grid,
        linewidth = 0.2
      ),
      text = ggplot2::element_text(colour = p$fg),
      axis.text = ggplot2::element_text(colour = p$fg),
      axis.title = ggplot2::element_text(colour = p$fg),
      plot.title = ggplot2::element_text(colour = p$fg, face = "bold"),
      plot.subtitle = ggplot2::element_text(colour = p$fg),
      plot.caption = ggplot2::element_text(colour = p$fg),
      legend.text = ggplot2::element_text(colour = p$fg),
      legend.title = ggplot2::element_text(colour = p$fg, face = "bold"),
      strip.text = ggplot2::element_text(colour = p$fg, face = "bold")
    )
}

# Public theme functions ------------------------------------------------------
theme_narsil <- function(base_size = 12) {
  update_geom_defaults("line",  list(colour = .narsil_pal$light$fg))
  update_geom_defaults("point", list(colour = .narsil_pal$light$fg))
  update_geom_defaults("segment", list(colour = .narsil_pal$light$fg))
  update_geom_defaults("hline",   list(colour = .narsil_pal$light$grid))
  .build_theme("light", base_size)
}

theme_narsil_dark <- function(base_size = 12) {
  update_geom_defaults("line",  list(colour = .narsil_pal$dark$fg))
  update_geom_defaults("point", list(colour = .narsil_pal$dark$fg))
  update_geom_defaults("segment", list(colour = .narsil_pal$dark$fg))
  update_geom_defaults("hline",   list(colour = .narsil_pal$dark$grid))
  .build_theme("dark", base_size)
}

# Colour / fill scales --------------------------------------------------------
scale_colour_narsil <- function(dark = FALSE, ...) {
  ggplot2::scale_colour_manual(
    values = .narsil_pal[[if (dark) "dark" else "light"]]$palette,
    ...
  )
}

scale_fill_narsil <- function(dark = FALSE, ...) {
  ggplot2::scale_fill_manual(
    values = .narsil_pal[[if (dark) "dark" else "light"]]$palette,
    ...
  )
}

scale_color_narsil <- scale_colour_narsil

# ── Render helpers ────────────────────────────────────────────────────────────
# Use these in renderings: [light, dark] chunks instead of calling
# theme_narsil() + scale_colour_narsil() separately.

scale_narsil <- function(...) {
  list(theme_narsil(), scale_colour_narsil(...))
}

scale_narsil_dark <- function(...) {
  list(theme_narsil_dark(), scale_colour_narsil(dark = TRUE, ...))
}

# Paged tables for tidyverts objects ------------------------------------------
# With `df-print: paged`, rmarkdown's paged_table_html() turns every list-like
# column into its pillar type summary. tidyverts columns are vctrs records or
# lists, so the site showed the literal text "<chr*>" instead of aggregate_key()
# keys, "<lst_mdl>" instead of model names, and "<dist>" instead of forecast
# distributions.
#
# These knit_print methods format such columns as text *before* handing the
# table to rmarkdown's own data.frame printer, so the paged look is unchanged.
# No HTML escaping is needed: pagedtable.js inserts cells with
# createTextNode(), so "<aggregated>" displays verbatim.
#
# Pass-through (identical to rmarkdown's default) when the chunk sets
# `paged.print: false`, when output is not HTML, or when the table has no
# columns that need formatting.

.narsil_needs_format <- function(col) {
  is.list(col) && !is.data.frame(col) && !identical(class(col), "list") &&
    !inherits(col, "vctrs_list_of")
}

# Formatted columns show as <chr> in the paged header; the cell text matches
# what the console prints (e.g. "<aggregated>", "<ETS(A,N,A)>", "N(701, 7651)").
.narsil_paged_prep <- function(x) {
  df <- tibble::as_tibble(x)
  fmt <- vapply(df, .narsil_needs_format, logical(1))
  df[fmt] <- lapply(df[fmt], function(col) trimws(gsub("\\s+", " ", format(col))))
  as.data.frame(df)
}

.narsil_knit_print_paged <- function(x, ...) {
  if (isFALSE(knitr::opts_current$get("paged.print")) ||
      !knitr::is_html_output() ||
      !any(vapply(x, .narsil_needs_format, logical(1)))) {
    return(NextMethod())
  }
  knitr::knit_print(.narsil_paged_prep(x), ...)
}

# tbl_df also covers plain tibbles that carry agg_vec keys, e.g. the output of
# accuracy() or as_tibble() on a fable.
if (requireNamespace("knitr", quietly = TRUE)) {
  for (.cls in c("tbl_ts", "fbl_ts", "mdl_df", "tbl_df")) {
    registerS3method("knit_print", .cls, .narsil_knit_print_paged,
                     envir = asNamespace("knitr"))
  }
  rm(.cls)
}

# plotly styling --------------------------------------------------------------
gg_to_plotly_narsil <- function(p, dark = FALSE) {
  pal <- .narsil_pal[[if (dark) "dark" else "light"]]

  plotly::layout(
    p,
    paper_bgcolor = pal$bg,
    plot_bgcolor = pal$bg_panel,
    font = list(color = pal$fg),
    xaxis = list(
      gridcolor = pal$grid,
      linecolor = pal$grid,
      zerolinecolor = pal$grid,
      tickfont = list(color = pal$fg)
    ),
    yaxis = list(
      gridcolor = pal$grid,
      linecolor = pal$grid,
      zerolinecolor = pal$grid,
      tickfont = list(color = pal$fg)
    ),
    legend = list(font = list(color = pal$fg))
  )
}
