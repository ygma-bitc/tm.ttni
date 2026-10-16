# Derive a simple OS-style ADTTE from ADSL death / last-alive dates

Used when a local CDISC Pilot checkout has ADSL but no ADTTE, or when a
demo needs a second PARAMCD alongside a native TTE dataset.

## Usage

``` r
derive_mock_adtte(adsl, paramcd = "OS", param = "Overall Survival")
```

## Arguments

- adsl:

  Standardized ADSL with `TRTSDT` and either `DTHDT` / `DTHFL` or
  `LSTALVDT`.

- paramcd:

  Parameter code to assign.

- param:

  Parameter label.

## Value

An ADTTE-like data frame.
