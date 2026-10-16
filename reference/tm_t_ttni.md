# teal Module: Time to Next Intervention and related TTE tables

Interactive TTE table. Kaplan-Meier summaries are always shown. Hazard
ratio, 95% CI, and log-rank p-value appear only when the selected
grouping variable has exactly two arms. PARAMCD is selected with
`teal.transform`.

## Usage

``` r
tm_t_ttni(
  label = "Time to Next Intervention (TTNI)",
  cat = NULL,
  adsl_name = "ADSL",
  tte_name = "ADTTE",
  paramcd = "TTNI",
  group_vars = c(`Actual Treatment` = "TRT01A"),
  population_var = "SAFFL",
  population_value = "Y",
  population_choices = c(`Safety (SAFFL)` = "SAFFL", `ITT (ITTFL)` = "ITTFL"),
  timepoints = c(3, 6, 12, 18, 24),
  landmark_style = c("detailed", "rate_only"),
  surv_stats = default_ttni_surv_stats(),
  include_followup = TRUE,
  show_total = NULL,
  compute_hr = NULL,
  conf_type = c("log-log", "log", "plain"),
  title = NULL
)
```

## Arguments

- label:

  Module label.

- cat:

  Optional `choices_selected` for PARAMCD. When `NULL`, `paramcd` is
  used as the default choice.

- adsl_name:

  ADSL dataset name in `teal_data`.

- tte_name:

  ADTTE dataset name.

- paramcd:

  Default PARAMCD when `cat` is not supplied.

- group_vars:

  Named character vector of grouping variables.

- population_var:

  Default population flag (`SAFFL` or `ITTFL`).

- population_value:

  Population flag value to keep.

- population_choices:

  Named choices shown in the population selector.

- timepoints:

  Default landmark months.

- landmark_style:

  `"detailed"` or `"rate_only"`.

- surv_stats:

  Initial time-to-event statistics from
  [`ttni_surv_time_choices()`](https://ygma-bitc.github.io/tm.ttni/reference/ttni_surv_time_choices.md).

- include_followup:

  Whether reverse KM follow-up is shown.

- show_total:

  Initial Total-column setting. `NULL` follows design.

- compute_hr:

  Leave `NULL` to auto-detect two-arm only.

- conf_type:

  KM CI type.

- title:

  Table title. `NULL` derives a title from the selected PARAMCD.

## Value

A `teal` module object.

## Examples

``` r
if (interactive()) {
  data <- make_synthetic_ttni_data("two_arm")
  app_data <- teal.data::teal_data(ADSL = data$ADSL, ADTTE = data$ADTTE)
  app <- teal::init(
    data = app_data,
    modules = teal::modules(
      tm_t_ttni(
        label = "TTNI",
        cat = teal.transform::choices_selected(
          choices = teal.transform::value_choices(
            data = "ADTTE",
            var_choices = "PARAMCD",
            var_label = "PARAM"
          ),
          selected = "TTNI"
        )
      )
    )
  )
  shiny::shinyApp(app$ui, app$server)
}
```
