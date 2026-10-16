# Time-to-event statistics offered in the module

`mean_sd` is a descriptive summary of `AVAL` (one row). The remaining
names are
[`tern::surv_time()`](https://pharmaverse.github.io/tern/latest-tag/reference/survival_time.html)
statistics, shown in tern's native order. `quantiles` and `range` are
labeled `Q1, Q3` and `Min, Max`. Separate `median` / `median_ci` rows
are not offered; use `median_ci_3d` so median and 95% CI stay on one
line.

## Usage

``` r
ttni_surv_time_choices()
```

## Value

A named character vector (`label` = `stat`).
