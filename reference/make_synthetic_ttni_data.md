# Build synthetic ADSL / ADTTE fixtures for TTE demos and tests

Returns a subject-level ADSL and a BDS-style ADTTE with two parameters:
`TTNI` (time to next intervention) and `OS` (overall survival). The two
data frames are distinct objects.

## Usage

``` r
make_synthetic_ttni_data(
  design = c("two_arm", "multi_arm"),
  n_per_arm = 40L,
  seed = 20260823L
)
```

## Arguments

- design:

  `character(1)` Either `"two_arm"` (randomized comparison) or
  `"multi_arm"` (three generic arms; no study-specific dose labels).

- n_per_arm:

  `integer(1)` Subjects per arm.

- seed:

  `integer(1)` Random seed.

## Value

A list with `ADSL` and `ADTTE`.

## Examples

``` r
data <- make_synthetic_ttni_data(design = "two_arm", seed = 1L)
names(data)
#> [1] "ADSL"  "ADTTE"
unique(data$ADTTE$PARAMCD)
#> [1] "TTNI" "OS"  
```
