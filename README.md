# narsil
Website for the TS Forecasting Course at ITESO

## Maintenance

### The Stan stack is excluded from `renv.lock`

The Stan stack (`prophet`, `rstan`, `StanHeaders`, `rstantools`, `QuickJSR`,
`inline`, `loo`, `posterior`) is excluded from `renv.lock` via
`renv/settings.json`. Its PPM binaries fail on CI with a TBB symbol mismatch
between `rstan` and `RcppParallel`:

```
rstan.so: undefined symbol: _ZN3tbb6detail2r17observeERNS0_2d123task_scheduler_observerEb
```

`prophet` entered this project through **`modeltime`**, which declares it in
`Imports` — a hard dependency, not a suggestion. `modeltime` was loaded in
`docs/modules/module_1/00_intro/intro.qmd` but never used (no `modeltime::`, no
`modeltime_*()` call anywhere), so it has been removed from that `p_load()` call
and added to the ignore list.

Excluding `fable.prophet` and `prophet` alone is **not** sufficient: while
`modeltime` remains a dependency, `renv::restore()` resolves its `prophet`
requirement itself and installs an unpinned newer version, reintroducing the
same failure.

This arrangement is safe only while every Prophet-using document has a committed
`_freeze/`. To re-execute `docs/modules/module_3/04_prophet/`, install the
packages locally first.

The same applies to the `refresh_fred` workflow input:
`module_4/02_bootstrap_combinations` and `module_4/03_cv` are marked
`fred-data: true` **and** load `fable.prophet`, so a `refresh_fred` run deletes
their freeze and will fail at `library(fable.prophet)` unless the packages are
restored for that run.

To work on Prophet material locally, install it separately, exactly as students
do:

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

The CI cache key already includes a hash of `renv.lock`, so a changed lockfile
invalidates the cache on its own. Bump `cache-version` in
`.github/workflows/publish.yml` only when you need to force a rebuild for some
other reason.
