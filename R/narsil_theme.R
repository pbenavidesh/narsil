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
    bg       = "#F5F4EF",
    bg_panel = "#ECEAE3",
    fg       = "#2A2520",
    grid     = "#D5D0C6",
    palette  = c("#1A5276", "#7D6608", "#6C3483", "#009E73", "#D55E00", "#5B8DB8")
  ),
  dark = list(
    bg       = "#222222",
    bg_panel = "#2d2d2d",
    fg       = "#E8DDD0",
    grid     = "#444444",
    palette  = c("#E8651A", "#E2C12B", "#A569BD", "#D4548C", "#5DADE2", "#AAB7B8")
  )
)

# Internal theme builder ------------------------------------------------------
.build_theme <- function(mode, base_size) {
  p <- .narsil_pal[[mode]]

  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = p$bg, colour = NA),
      panel.background = ggplot2::element_rect(fill = p$bg_panel, colour = NA),
      panel.grid.major = ggplot2::element_line(colour = p$grid, linewidth = 0.4),
      panel.grid.minor = ggplot2::element_line(colour = p$grid, linewidth = 0.2),
      text          = ggplot2::element_text(colour = p$fg),
      axis.text     = ggplot2::element_text(colour = p$fg),
      axis.title    = ggplot2::element_text(colour = p$fg),
      plot.title    = ggplot2::element_text(colour = p$fg, face = "bold"),
      plot.subtitle = ggplot2::element_text(colour = p$fg),
      plot.caption  = ggplot2::element_text(colour = p$fg),
      legend.text   = ggplot2::element_text(colour = p$fg),
      legend.title  = ggplot2::element_text(colour = p$fg, face = "bold"),
      strip.text    = ggplot2::element_text(colour = p$fg, face = "bold")
    )
}

# Public theme functions ------------------------------------------------------
theme_narsil <- function(base_size = 12) {
  .build_theme("light", base_size)
}

theme_narsil_dark <- function(base_size = 12) {
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

# plotly styling --------------------------------------------------------------
gg_to_plotly_narsil <- function(p, dark = FALSE) {
  pal <- .narsil_pal[[if (dark) "dark" else "light"]]

  plotly::layout(
    p,
    paper_bgcolor = pal$bg,
    plot_bgcolor  = pal$bg_panel,
    font          = list(color = pal$fg),
    xaxis = list(
      gridcolor     = pal$grid,
      linecolor     = pal$grid,
      zerolinecolor = pal$grid,
      tickfont      = list(color = pal$fg)
    ),
    yaxis = list(
      gridcolor     = pal$grid,
      linecolor     = pal$grid,
      zerolinecolor = pal$grid,
      tickfont      = list(color = pal$fg)
    ),
    legend = list(font = list(color = pal$fg))
  )
}
