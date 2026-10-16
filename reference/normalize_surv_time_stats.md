# Keep requested statistics in catalog order

Legacy `median` / `median_ci` requests are folded into `median_ci_3d`.

## Usage

``` r
normalize_surv_time_stats(stats = NULL)
```

## Arguments

- stats:

  Character vector of statistic names. `NULL` uses
  [`default_ttni_surv_stats()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_surv_stats.md).

## Value

Character vector subset of
[`ttni_surv_time_choices()`](https://ygma-bitc.github.io/tm.ttni/reference/ttni_surv_time_choices.md).
