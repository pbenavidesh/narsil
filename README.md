# narsil
Website for the TS Forecasting Course at ITESO

## Maintenance

### Prophet is excluded from `renv.lock`

`fable.prophet` and `prophet` are excluded from `renv.lock` (see
`renv/settings.json`). Their Stan dependencies fail to install on CI due to a
TBB binary mismatch between the `rstan` and `RcppParallel` binaries. This is
safe only while every Prophet-using document has a committed `_freeze/`. If you
ever need to force re-execution of `docs/modules/module_3/04_prophet/`, you must
restore these packages first.

The same applies to the `refresh_fred` workflow input:
`module_4/02_bootstrap_combinations` and `module_4/03_cv` are marked
`fred-data: true` **and** load `fable.prophet`, so a `refresh_fred` run deletes
their freeze and will fail at `library(fable.prophet)` unless the packages are
restored for that run.

`rstan`, `rstantools`, `inline`, `loo`, `posterior` and `QuickJSR` are ignored
too — they entered the lockfile only via `prophet`. `StanHeaders`, `BH` and
`RcppParallel` are **not** ignored: `modeltime` needs `StanHeaders`, and
`anytime` (via `timetk`/`tsibble`) needs `BH`.

To work on Prophet material locally, install the packages separately, exactly as
students do:

```r
pak::pak("fable.prophet")
```

### Regenerating the lockfile

`renv::snapshot()` does not prune orphaned transitive dependencies in this
project, so removing a package means adding it to `ignored.packages` rather than
relying on the snapshot to drop it:

```r
renv::settings$ignored.packages(c("..."), persist = TRUE)
renv::snapshot()
```

Bump `cache-version` in `.github/workflows/publish.yml` whenever `renv.lock`
changes, so the CI `renv` cache is invalidated.
