#' @keywords internal
build_reproducible_code_text <- function(adsl_name,
                                         tte_name,
                                         paramcd,
                                         arm_var,
                                         ref_arm,
                                         population_var,
                                         timepoints,
                                         landmark_style,
                                         show_total,
                                         include_followup,
                                         surv_stats) {
  tp <- tryCatch(
    paste(parse_timepoints(timepoints), collapse = ", "),
    error = function(e) "6"
  )
  paste(
    sprintf("prepped <- tm.ttni::prep_ttni_data("),
    sprintf("  adsl = %s,", adsl_name),
    sprintf("  adtte = %s,", tte_name),
    sprintf("  arm_var = %s,", deparse(arm_var)),
    sprintf("  ref_arm = %s,", deparse(ref_arm)),
    sprintf("  paramcd = %s,", deparse(paramcd)),
    sprintf("  population_var = %s", deparse(population_var)),
    ")",
    "tm.ttni::build_ttni_table(",
    "  prepped = prepped,",
    sprintf("  timepoints = c(%s),", tp),
    sprintf("  landmark_style = %s,", deparse(landmark_style)),
    sprintf("  show_total = %s,", if (isTRUE(show_total)) "TRUE" else "FALSE"),
    sprintf("  include_followup = %s,", if (isTRUE(include_followup)) "TRUE" else "FALSE"),
    sprintf("  surv_stats = %s", deparse(surv_stats, width.cutoff = 500L)),
    ")",
    sep = "\n"
  )
}


#' @keywords internal
ui_t_ttni <- function(id, ...) {
  ns <- shiny::NS(id)
  a <- list(...)

  shiny::tagList(
    shinyjs::useShinyjs(),
    # teal.picks badges are 130px wide and do not wrap, which clips names here.
    shiny::singleton(
      shiny::tags$head(
        shiny::includeCSS(
          system.file("css", "encoding-picks.css", package = "tm.ttni")
        )
      )
    ),
    teal.widgets::standard_layout(
      output = teal.widgets::white_small_well(
        shiny::uiOutput(ns("table_or_message"))
      ),
      encoding = shiny::tags$div(
        class = "tm-ttni-encoding",
        shiny::tags$label("Encodings", class = "text-primary"),
        shiny::tags$div(
          shiny::tags$label("Select PARAMCD"),
          teal.picks::picks_ui(ns("tte_cat"), a$tte_cat)
        ),
        shiny::tags$div(
          shiny::tags$label("Treatment / group variable"),
          teal.picks::picks_ui(ns("arm_var"), a$arm_var)
        ),
        shiny::selectizeInput(
          inputId = ns("ref_arm"),
          label = "Reference arm (two-arm HR only)",
          choices = NULL,
          multiple = FALSE,
          width = "100%"
        ),
        shiny::tags$div(
          shiny::tags$label("Population flag"),
          teal.picks::picks_ui(ns("population_var"), a$population_var)
        ),
        shiny::uiOutput(ns("design_note")),
        shiny::tags$hr(),
        shiny::textInput(
          inputId = ns("timepoints"),
          label = "Landmark months",
          value = paste(a$timepoints, collapse = ",")
        ),
        shiny::radioButtons(
          inputId = ns("landmark_style"),
          label = "Landmark display",
          choices = c(
            "At risk + rate (95% CI)" = "detailed",
            "Rate (95% CI) only" = "rate_only"
          ),
          selected = a$landmark_style
        ),
        shiny::checkboxInput(
          inputId = ns("show_total"),
          label = "Show Total column",
          value = isTRUE(a$show_total)
        ),
        shiny::checkboxInput(
          inputId = ns("include_followup"),
          label = "Include reverse KM follow-up time",
          value = isTRUE(a$include_followup)
        ),
        shiny::checkboxGroupInput(
          inputId = ns("surv_stats"),
          label = "Time-to-event statistics",
          choices = a$surv_stat_choices,
          selected = a$surv_stats
        )
      ),
      forms = shiny::tagList(
        teal.widgets::verbatim_popup_ui(ns("rcode"), button_label = "Show R Code")
      )
    )
  )
}


#' @keywords internal
srv_t_ttni <- function(id,
                       data,
                       tte_cat,
                       adsl_name = "ADSL",
                       tte_name = "ADTTE",
                       paramcd = "TTNI",
                       arm_var,
                       population_var,
                       population_value = "Y",
                       timepoints = c(3, 6, 12, 18, 24),
                       landmark_style = "detailed",
                       include_followup = TRUE,
                       surv_stats = default_ttni_surv_stats(),
                       show_total = NULL,
                       compute_hr = NULL,
                       conf_type = "log-log",
                       title = NULL) {
  checkmate::assert_class(data, "reactive")

  shiny::moduleServer(id, function(input, output, session) {
    selectors <- teal.picks::picks_srv(
      id = "",
      picks = list(
        tte_cat = tte_cat,
        arm_var = arm_var,
        population_var = population_var
      ),
      data = data
    )

    iv_r <- shiny::reactive({
      iv <- shinyvalidate::InputValidator$new()
      iv$add_rule("surv_stats", ~ if (length(.) == 0L) "Select at least one time-to-event statistic.")
      iv$add_rule("timepoints", function(value) {
        ok <- tryCatch(
          {
            parse_timepoints(value)
            TRUE
          },
          error = function(e) FALSE
        )
        if (!isTRUE(ok)) {
          "Enter at least one positive landmark month (comma-separated)."
        }
      })
      iv$enable()
      iv
    })

    selected_paramcd <- shiny::reactive({
      resolved <- selectors$tte_cat()
      sel <- if (is.null(resolved) || is.null(resolved$values)) {
        character(0)
      } else {
        as.character(resolved$values$selected)
      }
      sel <- sel[!is.na(sel) & nzchar(sel)]
      if (length(sel) == 1L) sel else paramcd
    })

    arm_fallback <- column_fallback(arm_var, "TRT01A")
    population_fallback <- column_fallback(population_var, "SAFFL")

    selected_arm_var <- shiny::reactive({
      selected_pick_column(selectors$arm_var(), arm_fallback)
    })

    selected_population_var <- shiny::reactive({
      selected_pick_column(selectors$population_var(), population_fallback)
    })

    datasets_r <- shiny::reactive({
      req_data <- data()
      shiny::validate(
        shiny::need(adsl_name %in% names(req_data), sprintf("Dataset '%s' is missing.", adsl_name)),
        shiny::need(tte_name %in% names(req_data), sprintf("Dataset '%s' is missing.", tte_name))
      )
      list(adsl = req_data[[adsl_name]], adtte = req_data[[tte_name]])
    })

    shiny::observe({
      ds <- datasets_r()
      arm_name <- selected_arm_var()
      src <- if (!is.null(ds$adsl) && arm_name %in% names(ds$adsl)) ds$adsl else ds$adtte
      shiny::req(arm_name %in% names(src))
      design <- detect_arm_design(src, arm_var = arm_name)
      shiny::updateSelectizeInput(
        session,
        "ref_arm",
        choices = design$arms,
        selected = design$ref_arm
      )
    })

    prepped_r <- shiny::reactive({
      teal::validate_inputs(iv_r())
      ds <- datasets_r()
      arm_name <- selected_arm_var()
      shiny::validate(
        shiny::need(length(arm_name) == 1L && nzchar(arm_name), "Select a treatment / group variable.")
      )
      prep_ttni_data(
        adsl = ds$adsl,
        adtte = ds$adtte,
        arm_var = arm_name,
        ref_arm = input$ref_arm,
        paramcd = selected_paramcd(),
        population_var = selected_population_var(),
        population_value = population_value
      )
    })

    no_data_r <- shiny::reactive({
      prepped <- prepped_r()
      isTRUE(prepped$empty) || NROW(prepped$anl) == 0L
    })

    output$design_note <- shiny::renderUI({
      design <- tryCatch(prepped_r()$design, error = function(e) NULL)
      if (is.null(design) || is.null(design$design)) {
        return(NULL)
      }
      msg <- if (identical(design$design, "two_arm")) {
        sprintf("Detected two-arm design. HR / 95%% CI / log-rank p-value will be shown vs %s.", design$ref_arm)
      } else {
        sprintf(
          "Detected %s design (%d arms). HR / p-value are not calculated.",
          gsub("_", "-", design$design),
          design$n_arms
        )
      }
      shiny::tags$p(class = "help-block", msg)
    })

    table_r <- shiny::reactive({
      shiny::validate(shiny::need(!no_data_r(), "No records available for the selected parameter."))
      tp <- parse_timepoints(input$timepoints %||% timepoints)
      pc <- selected_paramcd()
      resolved_title <- if (is.null(title) || identical(title, default_tte_title("TTNI"))) {
        default_tte_title(pc)
      } else {
        title
      }
      build_ttni_table(
        prepped = prepped_r(),
        timepoints = tp,
        show_total = input$show_total,
        include_followup = isTRUE(input$include_followup),
        surv_stats = input$surv_stats %||% surv_stats,
        landmark_style = input$landmark_style %||% landmark_style,
        conf_type = conf_type,
        compute_hr = compute_hr,
        title = resolved_title
      )
    })

    source_code_r <- shiny::reactive({
      build_reproducible_code_text(
        adsl_name = adsl_name,
        tte_name = tte_name,
        paramcd = selected_paramcd(),
        arm_var = selected_arm_var(),
        ref_arm = input$ref_arm,
        population_var = selected_population_var(),
        timepoints = input$timepoints %||% timepoints,
        landmark_style = input$landmark_style %||% landmark_style,
        show_total = isTRUE(input$show_total),
        include_followup = isTRUE(input$include_followup),
        surv_stats = input$surv_stats %||% surv_stats
      )
    })

    output$table_or_message <- shiny::renderUI({
      if (isTRUE(no_data_r())) {
        return(teal.widgets::white_small_well(
          shiny::div(shiny::tags$strong("No records available for the selected parameter."))
        ))
      }
      teal.widgets::table_with_settings_ui(session$ns("table_out"))
    })

    teal.widgets::table_with_settings_srv(id = "table_out", table_r = table_r)

    teal.widgets::verbatim_popup_srv(
      id = "rcode",
      verbatim_content = source_code_r,
      title = "TTE Summary - R Code"
    )

    list(
      table = table_r,
      prepped_data = prepped_r,
      no_data = no_data_r,
      source_code = source_code_r
    )
  })
}


#' teal Module: Time to Next Intervention and related TTE tables
#'
#' Interactive TTE table. Kaplan-Meier summaries are always shown. Hazard
#' ratio, 95% CI, and log-rank p-value appear only when the selected grouping
#' variable has exactly two arms. PARAMCD, the grouping variable, and the
#' population flag are selected with `teal.picks`.
#'
#' @param label Module label.
#' @param cat (`picks` or legacy `choices_selected`) PARAMCD selector.
#'   When `NULL`, a [`teal.picks::picks()`] object is built: `datasets` is
#'   `tte_name`, `variables` is fixed to `PARAMCD` with `multiple = FALSE`,
#'   and `values` selects `paramcd` with `multiple = FALSE`.
#'   A `teal.transform::choices_selected` object is still accepted, with a
#'   deprecation warning, and converted to that picks shape.
#' @param adsl_name ADSL dataset name in `teal_data`.
#' @param tte_name ADTTE dataset name.
#' @param paramcd Default PARAMCD stored in `values$selected` when `cat` is `NULL`.
#' @param group_vars (`picks` or legacy character) grouping column.
#'   When `NULL`, `datasets` is `adsl_name` and `variables` is `TRT01A`
#'   (`multiple = FALSE`). A character vector of column names is still
#'   accepted, with a deprecation warning. Names on that vector were display
#'   labels and are dropped.
#' @param population_var (`picks` or legacy character) population-flag column.
#'   When `NULL` and `population_choices` is `NULL`, `datasets` is `adsl_name`
#'   and `variables` offers `SAFFL` and `ITTFL`, with `SAFFL` selected
#'   (`multiple = FALSE`).
#' @param population_value Population flag value to keep.
#' @param population_choices Legacy character vector of flag columns. Ignored
#'   when `population_var` is a `picks` object. Passing either this or a
#'   character `population_var` signals a deprecation warning.
#' @param timepoints Default landmark months.
#' @param landmark_style `"detailed"` or `"rate_only"`.
#' @param surv_stats Initial time-to-event statistics from
#'   [ttni_surv_time_choices()].
#' @param include_followup Whether reverse KM follow-up is shown.
#' @param show_total Initial Total-column setting. `NULL` follows design.
#' @param compute_hr Leave `NULL` to auto-detect two-arm only.
#' @param conf_type KM CI type.
#' @param title Table title. `NULL` derives a title from the selected PARAMCD.
#'
#' @return A `teal` module object.
#'
#' @examples
#' if (interactive()) {
#'   data <- make_synthetic_ttni_data("two_arm")
#'   app_data <- teal.data::teal_data(ADSL = data$ADSL, ADTTE = data$ADTTE)
#'   paramcd_choices <- unique(as.character(data$ADTTE$PARAMCD))
#'   app <- teal::init(
#'     data = app_data,
#'     modules = teal::modules(
#'       tm_t_ttni(
#'         label = "TTNI",
#'         cat = teal.picks::picks(
#'           teal.picks::datasets(choices = "ADTTE", selected = "ADTTE"),
#'           teal.picks::variables(
#'             choices = "PARAMCD",
#'             selected = "PARAMCD",
#'             multiple = FALSE,
#'             fixed = TRUE
#'           ),
#'           teal.picks::values(
#'             choices = paramcd_choices,
#'             selected = "TTNI",
#'             multiple = FALSE
#'           )
#'         ),
#'         group_vars = teal.picks::picks(
#'           teal.picks::datasets(choices = "ADSL", selected = "ADSL"),
#'           teal.picks::variables(
#'             choices = c("TRT01A", "SEX"),
#'             selected = "TRT01A",
#'             multiple = FALSE
#'           )
#'         ),
#'         population_var = teal.picks::picks(
#'           teal.picks::datasets(choices = "ADSL", selected = "ADSL"),
#'           teal.picks::variables(
#'             choices = c("SAFFL", "ITTFL"),
#'             selected = "SAFFL",
#'             multiple = FALSE
#'           )
#'         )
#'       )
#'     )
#'   )
#'   shiny::shinyApp(app$ui, app$server)
#' }
#'
#' @export
tm_t_ttni <- function(label = "Time to Next Intervention (TTNI)",
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
                      title = NULL) {
  landmark_style <- match.arg(landmark_style)
  conf_type <- match.arg(conf_type)
  checkmate::assert_string(label)
  checkmate::assert_string(adsl_name)
  checkmate::assert_string(tte_name)
  checkmate::assert_string(paramcd)
  checkmate::assert_string(population_value)
  checkmate::assert_numeric(timepoints, min.len = 1L, lower = 0, finite = TRUE)
  surv_stats <- normalize_surv_time_stats(surv_stats)
  checkmate::assert_flag(include_followup)
  checkmate::assert_flag(show_total, null.ok = TRUE)
  checkmate::assert_flag(compute_hr, null.ok = TRUE)
  checkmate::assert_string(title, null.ok = TRUE)

  cat <- migrate_cat_to_picks(cat, tte_name = tte_name, paramcd = paramcd)
  checkmate::assert_class(cat, "picks")
  group_vars <- migrate_column_selector_to_picks(
    group_vars,
    dataname = adsl_name,
    choices = "TRT01A",
    selected = "TRT01A",
    arg_name = "group_vars"
  )
  population_var <- migrate_population_to_picks(
    population_var,
    population_choices,
    adsl_name = adsl_name
  )
  checkmate::assert_class(group_vars, "picks")
  checkmate::assert_class(population_var, "picks")

  teal::module(
    label = label,
    server = srv_t_ttni,
    ui = ui_t_ttni,
    ui_args = list(
      tte_cat = cat,
      arm_var = group_vars,
      population_var = population_var,
      timepoints = timepoints,
      landmark_style = landmark_style,
      surv_stats = surv_stats,
      surv_stat_choices = ttni_surv_time_choices(),
      include_followup = include_followup,
      show_total = show_total
    ),
    server_args = list(
      tte_cat = cat,
      adsl_name = adsl_name,
      tte_name = tte_name,
      paramcd = paramcd,
      arm_var = group_vars,
      population_var = population_var,
      population_value = population_value,
      timepoints = timepoints,
      landmark_style = landmark_style,
      surv_stats = surv_stats,
      include_followup = include_followup,
      show_total = show_total,
      compute_hr = compute_hr,
      conf_type = conf_type,
      title = title
    ),
    datanames = unique(c(adsl_name, tte_name))
  )
}
