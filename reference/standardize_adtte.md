# Standardize an ADTTE-like data frame

Ensures `PARAMCD` / `PARAM` / `AVAL` / `CNSR` exist and converts
day-valued `AVAL` to months when `AVALU` is `DAYS`.

## Usage

``` r
standardize_adtte(adtte, adsl = NULL, default_avalu = NULL)
```

## Arguments

- adtte:

  A data frame with at least `USUBJID` and a time-to-event value.

- adsl:

  Optional standardized ADSL used to back-fill `TRT01A`.

- default_avalu:

  Unit used when `AVALU` is missing. `NULL` infers `DAYS` when the
  maximum `AVAL` exceeds 60, otherwise `MONTHS`.

## Value

A standardized ADTTE data frame.
