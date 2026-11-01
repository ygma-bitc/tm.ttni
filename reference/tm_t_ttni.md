# teal Module: Time to Next Intervention and related TTE tables

Interactive TTE table. Kaplan-Meier summaries are always shown. Hazard
ratio, 95% CI, and log-rank p-value appear only when the selected
grouping variable has exactly two arms. PARAMCD, the grouping variable,
and the population flag are selected with `teal.picks`.

## Usage

``` r
tm_t_ttni(
  label = "Time to Next Intervention (TTNI)",
  cat = NULL,
  adsl_name = "ADSL",
  tte_name = "ADTTE",
  paramcd = "TTNI",
  group_vars = NULL,
  population_var = NULL,
  population_value = "Y",
  population_choices = NULL,
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

  (`picks` or legacy `choices_selected`) PARAMCD selector. When `NULL`,
  a
  [`teal.picks::picks()`](https://rdrr.io/pkg/teal.picks/man/picks.html)
  object is built: `datasets` is `tte_name`, `variables` is fixed to
  `PARAMCD` with `multiple = FALSE`, and `values` selects `paramcd` with
  `multiple = FALSE`. A
  [`teal.transform::choices_selected`](https://rdrr.io/pkg/teal.transform/man/choices_selected.html)
  object is still accepted, with a deprecation warning, and converted to
  that picks shape.

- adsl_name:

  ADSL dataset name in `teal_data`.

- tte_name:

  ADTTE dataset name.

- paramcd:

  Default PARAMCD stored in `values$selected` when `cat` is `NULL`.

- group_vars:

  (`picks` or legacy character) grouping column. When `NULL`, `datasets`
  is `adsl_name` and `variables` is `TRT01A` (`multiple = FALSE`). A
  character vector of column names is still accepted, with a deprecation
  warning. Names on that vector were display labels and are dropped.

- population_var:

  (`picks` or legacy character) population-flag column. When `NULL` and
  `population_choices` is `NULL`, `datasets` is `adsl_name` and
  `variables` offers `SAFFL` and `ITTFL`, with `SAFFL` selected
  (`multiple = FALSE`).

- population_value:

  Population flag value to keep.

- population_choices:

  Legacy character vector of flag columns. Ignored when `population_var`
  is a `picks` object. Passing either this or a character
  `population_var` signals a deprecation warning.

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
  paramcd_choices <- unique(as.character(data$ADTTE$PARAMCD))
  app <- teal::init(
    data = app_data,
    modules = teal::modules(
      tm_t_ttni(
        label = "TTNI",
        cat = teal.picks::picks(
          teal.picks::datasets(choices = "ADTTE", selected = "ADTTE"),
          teal.picks::variables(
            choices = "PARAMCD",
            selected = "PARAMCD",
            multiple = FALSE,
            fixed = TRUE
          ),
          teal.picks::values(
            choices = paramcd_choices,
            selected = "TTNI",
            multiple = FALSE
          )
        ),
        group_vars = teal.picks::picks(
          teal.picks::datasets(choices = "ADSL", selected = "ADSL"),
          teal.picks::variables(
            choices = c("TRT01A", "SEX"),
            selected = "TRT01A",
            multiple = FALSE
          )
        ),
        population_var = teal.picks::picks(
          teal.picks::datasets(choices = "ADSL", selected = "ADSL"),
          teal.picks::variables(
            choices = c("SAFFL", "ITTFL"),
            selected = "SAFFL",
            multiple = FALSE
          )
        )
      )
    )
  )
  shiny::shinyApp(app$ui, app$server)
}
```
