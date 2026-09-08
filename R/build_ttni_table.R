#' @keywords internal
format_count_pct <- function(n, n_col) {
  pct <- if (!is.na(n_col) && n_col > 0) 100 * n / n_col else NA_real_
  rtables::rcell(c(as.integer(n), pct), format = "xx (xx.x)")
}


#' @keywords internal
a_ttni_event_censor <- function(df,
                                .N_col,
                                evntdesc_var,
                                event_levels,
                                censor_levels,
                                ...) {
  is_event <- if ("is_event" %in% names(df)) {
    as.logical(df$is_event)
  } else {
    rep(FALSE, nrow(df))
  }

  n_event <- sum(is_event, na.rm = TRUE)
  n_censor <- sum(!is_event, na.rm = TRUE)
  desc <- as.character(df[[evntdesc_var]])

  rows <- list(
    "Number of participants with event, n (%)" = format_count_pct(n_event, .N_col)
  )
  for (lvl in event_levels) {
    rows[[lvl]] <- format_count_pct(sum(is_event & desc == lvl, na.rm = TRUE), .N_col)
  }

  rows[["Number of participants censored, n (%)"]] <- format_count_pct(n_censor, .N_col)
  for (lvl in censor_levels) {
    rows[[lvl]] <- format_count_pct(sum(!is_event & desc == lvl, na.rm = TRUE), .N_col)
  }

  indent <- c(0L, rep(1L, length(event_levels)), 0L, rep(1L, length(censor_levels)))
  rtables::in_rows(.list = rows, .indent_mods = indent)
}


#' Build a TTE / TTNI summary table
#'
#' Uses `tern` Kaplan-Meier layout functions for both multi-arm (dose-level)
#' and two-arm designs. Hazard ratio, 95% CI, and log-rank p-value are added
#' only when exactly two arms are present.
#'
#' Pass either raw `adsl` / `adtte` or a list returned by [prep_ttni_data()]
#' via `prepped` so the teal server can prepare data once.
#'
#' @param adsl ADSL or combined TTE data. Ignored when `prepped` is supplied.
#' @param adtte Optional ADTTE data frame.
#' @param arm_var Treatment / grouping variable.
#' @param ref_arm Reference arm used for two-arm HR calculations.
#' @param paramcd Analysis parameter code.
#' @param timepoints Landmark months.
#' @param show_total Whether to add a Total column. Defaults to `TRUE` for
#'   multi-arm designs and `FALSE` for two-arm designs.
#' @param include_followup Whether to include reverse KM follow-up time.
#' @param surv_stats Time-to-event statistics from [ttni_surv_time_choices()].
#'   `NULL` uses [default_ttni_surv_stats()]. `mean_sd` is a descriptive
#'   Mean (SD) of `AVAL`; the rest are `tern::surv_time()` statistics.
#'   Legacy `median` / `median_ci` requests are folded into one
#'   `median_ci_3d` row. The same selection is used for follow-up time
#'   when `include_followup` is `TRUE`.
#' @param landmark_style `"detailed"` includes patients remaining at risk;
#'   `"rate_only"` shows rate (95% CI) only.
#' @param conf_type KM CI type passed to `tern::control_surv_time()`.
#' @param conf_level Confidence level.
#' @param compute_hr `NULL` to auto-detect (two-arm only), or a flag. A
#'   request of `TRUE` on a multi-arm data set is ignored with a warning.
#' @param title Table title. `NULL` derives a title from `paramcd`.
#' @param footnotes Optional method footnotes. `NULL` (default) omits them so
#'   the interactive table stays compact; definitions live in the README.
#'   Pass [default_ttni_footnotes()] when a TFL-style footer is required.
#' @param prepped Optional list from [prep_ttni_data()]. When supplied, raw
#'   `adsl` / `adtte` are not re-prepared.
#' @param ... Passed to [prep_ttni_data()] when `prepped` is `NULL`.
#'
#' @return An `rtables` `VTableTree`.
#'
#' @examples
#' two_arm <- make_synthetic_ttni_data("two_arm", seed = 1L)
#' build_ttni_table(two_arm$ADSL, two_arm$ADTTE, ref_arm = "Placebo")
#'
#' multi <- make_synthetic_ttni_data("multi_arm", seed = 1L)
#' build_ttni_table(multi$ADSL, multi$ADTTE, show_total = TRUE)
#'
#' @export
build_ttni_table <- function(adsl = NULL,
                             adtte = NULL,
                             arm_var = "TRT01A",
                             ref_arm = NULL,
                             paramcd = "TTNI",
                             timepoints = c(3, 6, 12, 18, 24),
                             show_total = NULL,
                             include_followup = TRUE,
                             surv_stats = NULL,
                             landmark_style = c("detailed", "rate_only"),
                             conf_type = c("log-log", "log", "plain"),
                             conf_level = 0.95,
                             compute_hr = NULL,
                             title = NULL,
                             footnotes = NULL,
                             prepped = NULL,
                             ...) {
  landmark_style <- match.arg(landmark_style)
  conf_type <- match.arg(conf_type)
  checkmate::assert_number(conf_level, lower = 0, upper = 1)
  checkmate::assert_flag(include_followup)
  checkmate::assert_string(title, null.ok = TRUE)
  checkmate::assert_list(prepped, null.ok = TRUE)
  timepoints <- parse_timepoints(timepoints)
  surv_stats <- normalize_surv_time_stats(surv_stats)

  if (is.null(prepped)) {
    checkmate::assert_data_frame(adsl)
    prepped <- prep_ttni_data(
      adsl = adsl,
      adtte = adtte,
      arm_var = arm_var,
      ref_arm = ref_arm,
      paramcd = paramcd,
      ...
    )
  }

  if (isTRUE(prepped$empty) || NROW(prepped$anl) == 0L) {
    stop("No TTE records remain after filtering PARAMCD / population / treatment.", call. = FALSE)
  }

  design <- prepped$design
  compute_hr <- resolve_compute_hr(design, compute_hr)
  show_total <- resolve_show_total(design, show_total)
  if (is.null(footnotes)) {
    footnotes <- character(0)
  }
  checkmate::assert_character(footnotes, null.ok = FALSE)
  if (is.null(title) || !nzchar(title)) {
    title <- default_tte_title(prepped$paramcd)
  }

  surv_ctrl <- tern::control_surv_time(conf_level = conf_level, conf_type = conf_type)
  tp_ctrl <- tern::control_surv_timepoint(conf_level = conf_level, conf_type = conf_type)
  cox_ctrl <- tern::control_coxph(pval_method = "log-rank", ties = "efron", conf_level = conf_level)

  lyt <- rtables::basic_table()
  if (isTRUE(compute_hr)) {
    lyt <- rtables::split_cols_by(lyt, prepped$arm_var, ref_group = design$ref_arm)
  } else {
    lyt <- rtables::split_cols_by(lyt, prepped$arm_var)
  }
  if (isTRUE(show_total)) {
    lyt <- rtables::add_overall_col(lyt, "Total")
  }
  lyt <- rtables::add_colcounts(lyt)

  lyt <- rtables::analyze(
    lyt,
    vars = prepped$aval_var,
    afun = a_ttni_event_censor,
    extra_args = list(
      evntdesc_var = prepped$evntdesc_var,
      event_levels = prepped$event_levels,
      censor_levels = prepped$censor_levels
    ),
    show_labels = "hidden",
    table_names = "ttni_counts"
  )

  lyt <- add_surv_time_block(
    lyt,
    vars = prepped$aval_var,
    is_event = "is_event",
    control = surv_ctrl,
    surv_stats = surv_stats,
    var_labels = sprintf("%s (months)", prepped$paramcd),
    table_names = "ttni_surv_time"
  )

  if (isTRUE(include_followup)) {
    lyt <- add_surv_time_block(
      lyt,
      vars = prepped$aval_var,
      is_event = "is_followup",
      control = surv_ctrl,
      surv_stats = surv_stats,
      var_labels = sprintf("%s Follow-up Time (months)", prepped$paramcd),
      table_names = "ttni_followup"
    )
  }

  if (isTRUE(compute_hr)) {
    lyt <- tern::coxph_pairwise(
      lyt,
      vars = prepped$aval_var,
      is_event = "is_event",
      control = cox_ctrl,
      na_str = "NE",
      table_names = "ttni_coxph",
      var_labels = sprintf("Comparison vs %s", design$ref_arm),
      .stats = c("hr", "hr_ci", "pvalue"),
      .labels = list(
        hr = "Hazard Ratio",
        hr_ci = "95% CI",
        pvalue = "p-value (log-rank)"
      )
    )
  }

  tp_stats <- if (identical(landmark_style, "rate_only")) {
    c("event_free_rate", "rate_ci")
  } else {
    c("pt_at_risk", "event_free_rate", "rate_ci")
  }

  for (tp in timepoints) {
    lyt <- tern::surv_timepoint(
      lyt,
      vars = prepped$aval_var,
      time_point = tp,
      is_event = "is_event",
      control = tp_ctrl,
      method = "surv",
      na_str = "NE",
      table_names = paste0("ttni_tp_", tp),
      var_labels = "Months",
      .stats = tp_stats,
      .labels = list(
        pt_at_risk = "Patients remaining at risk",
        event_free_rate = "Kaplan-Meier survival rate (%)",
        rate_ci = "95% CI"
      )
    )
  }

  tbl <- rtables::build_table(
    lyt = lyt,
    df = prepped$anl,
    alt_counts_df = prepped$alt_counts_df
  )

  design_note <- if (isTRUE(compute_hr)) {
    sprintf("Design: two-arm; HR vs %s", design$ref_arm)
  } else {
    sprintf("Design: %s; HR not calculated", design$design)
  }

  rtables::main_title(tbl) <- title
  rtables::subtitles(tbl) <- c(
    paste("Parameter:", prepped$paramcd),
    design_note
  )
  if (length(footnotes) > 0L) {
    rtables::main_footer(tbl) <- footnotes
  }
  tbl
}
