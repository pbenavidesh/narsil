# Sensitivity check for the tourism reconciliation CV in hierarchical.qmd.
#
# Re-runs the same comparison over 8 rolling origins (training ends
# 2007 Q4, 2009 Q1, ..., 2016 Q3; step = 5 quarters, h = 4) and saves the
# per-origin results to hierarchical_sensitivity.rds, which the HTML-only
# sensitivity note reads. Slow (~8 x 85 ETS fits); run once from the project
# root:
#
#   Rscript docs/modules/module_4/04_hierarchical/_sensitivity_cv.R

library(tidyverse)
library(fpp3)

tourism_hts <- tourism |>
  aggregate_key(State / Region, Trips = sum(Trips))

sens_cv <- tourism_hts |>
  stretch_tsibble(.init = 40, .step = 5, .id = ".id") |>
  filter(.id <= 8)

sens_fold <- function(fold) {
  fold |>
    update_tsibble(key = c(State, Region)) |>
    select(-.id) |>
    model(base = ETS(Trips)) |>
    reconcile(
      bu          = bottom_up(base),
      td          = top_down(base),
      mo          = middle_out(base, split = 1),
      ols         = min_trace(base, method = "ols"),
      wls_struct  = min_trace(base, method = "wls_struct"),
      wls_var     = min_trace(base, method = "wls_var"),
      mint_shrink = min_trace(base, method = "mint_shrink")
    ) |>
    forecast(h = 4) |>
    as_tibble() |>
    mutate(.id = fold$.id[1], origin = max(fold$Quarter))
}

sens_fc <- sens_cv |>
  group_split(.id) |>
  map(sens_fold) |>
  list_rbind()

origins <- distinct(sens_fc, .id, origin)

sens_accu <- sens_fc |>
  select(-origin) |>
  as_fable(index = Quarter, key = c(State, Region, .model, .id),
           distribution = Trips, response = "Trips") |>
  accuracy(tourism_hts, measures = list(MASE = MASE, RMSSE = RMSSE),
           by = c(".model", "State", "Region", ".id")) |>
  mutate(level = case_when(
    is_aggregated(State)  ~ "Total",
    is_aggregated(Region) ~ "State",
    .default = "Region"
  )) |>
  summarise(MASE = mean(MASE), RMSSE = mean(RMSSE), .by = c(.id, level, .model)) |>
  left_join(origins, by = ".id")

# Relative error (%) of two forecasts of the national total at each origin:
# the base forecast of the total, and the sum of the 76 regional base
# forecasts (= bottom-up total). Positive = over-forecast.
total_actual <- tourism_hts |>
  as_tibble() |>
  filter(is_aggregated(State)) |>
  select(Quarter, actual = Trips)

sens_bias <- sens_fc |>
  filter(.model == "base") |>
  mutate(source = case_when(
    is_aggregated(State)   ~ "total_base",
    !is_aggregated(Region) ~ "regions_sum"
  )) |>
  filter(!is.na(source)) |>
  summarise(fc = sum(.mean), .by = c(.id, origin, source, Quarter)) |>
  left_join(total_actual, by = "Quarter") |>
  summarise(bias_pct = 100 * mean(fc - actual) / mean(actual),
            .by = c(.id, origin, source)) |>
  pivot_wider(names_from = source, values_from = bias_pct,
              names_glue = "{source}_bias_pct")

write_rds(
  list(accuracy = sens_accu, bias = sens_bias),
  here::here("docs/modules/module_4/04_hierarchical/hierarchical_sensitivity.rds")
)
