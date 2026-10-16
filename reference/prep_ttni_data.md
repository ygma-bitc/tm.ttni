# Prepare ADSL / ADTTE records for a TTE table

Accepts either a single ADSL-like data frame that already contains TTE
variables (`PARAMCD`, `AVAL`, `CNSR`, `EVNTDESC`) or a separate ADTTE
data frame joined to ADSL by subject. An empty result after filtering is
returned as a structured list (`empty = TRUE`) rather than an error so
the teal module can show a no-data message.

## Usage

``` r
prep_ttni_data(
  adsl,
  adtte = NULL,
  arm_var = "TRT01A",
  ref_arm = NULL,
  paramcd = "TTNI",
  subject_var = "USUBJID",
  paramcd_var = "PARAMCD",
  aval_var = "AVAL",
  cnsr_var = "CNSR",
  evntdesc_var = "EVNTDESC",
  population_var = "SAFFL",
  population_value = "Y"
)
```

## Arguments

- adsl:

  ADSL or combined subject-level TTE data.

- adtte:

  Optional ADTTE data frame. If `NULL`, `adsl` is used as the TTE
  source.

- arm_var:

  Treatment / grouping variable.

- ref_arm:

  Optional reference arm for two-arm comparisons.

- paramcd:

  Analysis parameter code.

- subject_var:

  Subject identifier.

- paramcd_var:

  PARAMCD variable name.

- aval_var:

  Analysis value variable.

- cnsr_var:

  Censor variable (`0` = event).

- evntdesc_var:

  Event / censor description variable.

- population_var:

  Optional population flag variable.

- population_value:

  Population flag value to keep.

## Value

A list with analysis data, design metadata, description levels, and
`empty` (`TRUE` when no records remain).
