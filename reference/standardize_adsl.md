# Standardize an ADSL-like data frame for TTE tables

Harmonizes common CDISC Pilot / `random.cdisc.data` column variants so
[`prep_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/prep_ttni_data.md)
can join treatment and population flags.

## Usage

``` r
standardize_adsl(adsl)
```

## Arguments

- adsl:

  A data frame with at least `USUBJID`.

## Value

A standardized ADSL data frame.
