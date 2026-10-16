# Detect whether a TTE table should use two-arm inferential statistics

TTNI can appear in a multi-dose Phase 1/2 study or a two-arm randomized
trial. Hazard ratio, Wald CI, and log-rank p-value are only appropriate
when exactly two treatment arms are present.

## Usage

``` r
detect_arm_design(data, arm_var, ref_arm = NULL)
```

## Arguments

- data:

  A data frame containing the treatment variable.

- arm_var:

  `character(1)` Treatment / grouping variable name.

- ref_arm:

  `character(1)` or `NULL` Reference arm. Defaults to the first factor
  level (or first unique value).

## Value

A list with `n_arms`, `arms`, `ref_arm`, `comp_arms`, `design`
(`single_arm`, `two_arm`, or `multi_arm`), and `compute_hr`.

## Examples

``` r
detect_arm_design(
  data.frame(TRT01A = c("Placebo", "Drug")),
  arm_var = "TRT01A",
  ref_arm = "Placebo"
)
#> $n_arms
#> [1] 2
#> 
#> $arms
#> [1] "Placebo" "Drug"   
#> 
#> $ref_arm
#> [1] "Placebo"
#> 
#> $comp_arms
#> [1] "Drug"
#> 
#> $design
#> [1] "two_arm"
#> 
#> $compute_hr
#> [1] TRUE
#> 
```
