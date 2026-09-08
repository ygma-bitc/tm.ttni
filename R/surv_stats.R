#' Time-to-event statistics offered in the module
#'
#' `mean_sd` is a descriptive summary of `AVAL` (one row). The remaining
#' names are `tern::surv_time()` statistics, shown in tern's native order.
#' `quantiles` and `range` are labeled `Q1, Q3` and `Min, Max`. Separate
#' `median` / `median_ci` rows are not offered; use `median_ci_3d` so
#' median and 95% CI stay on one line.
#'
#' @return A named character vector (`label` = `stat`).
#' @export
ttni_surv_time_choices <- function() {
  c(
    "Mean (SD)" = "mean_sd",
    "Median (95% CI)" = "median_ci_3d",
    "Q1, Q3" = "quantiles",
    "25%-ile (95% CI)" = "quantiles_lower",
    "75%-ile (95% CI)" = "quantiles_upper",
    "Min, Max" = "range",
    "Range (event)" = "range_event",
    "Range (censored)" = "range_censor"
  )
}


#' Default time-to-event statistics shown in the module
#'
#' Includes descriptive Mean (SD) of `AVAL` plus Kaplan-Meier median (95% CI),
#' quartiles, and range.
#'
#' @return Character vector of statistic names from [ttni_surv_time_choices()].
#' @export
default_ttni_surv_stats <- function() {
  c("mean_sd", "median_ci_3d", "quantiles", "quantiles_lower", "quantiles_upper", "range")
}


#' Keep requested statistics in catalog order
#'
#' Legacy `median` / `median_ci` requests are folded into `median_ci_3d`.
#'
#' @param stats Character vector of statistic names. `NULL` uses
#'   [default_ttni_surv_stats()].
#' @return Character vector subset of [ttni_surv_time_choices()].
#' @keywords internal
normalize_surv_time_stats <- function(stats = NULL) {
  allowed <- unname(ttni_surv_time_choices())
  if (is.null(stats)) {
    return(default_ttni_surv_stats())
  }
  checkmate::assert_character(stats, min.len = 1L, any.missing = FALSE)
  if (any(stats %in% c("median", "median_ci"))) {
    stats <- c(setdiff(stats, c("median", "median_ci")), "median_ci_3d")
  }
  unknown <- setdiff(stats, allowed)
  if (length(unknown) > 0L) {
    warning(
      sprintf(
        "Unknown time-to-event statistic(s) ignored: %s.",
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  kept <- intersect(allowed, stats)
  if (length(kept) == 0L) {
    stop("Select at least one time-to-event statistic.", call. = FALSE)
  }
  kept
}


#' @keywords internal
.tte_surv_time_formats <- list(
  median_ci = "(xx.x, xx.x)",
  quantiles = "xx.x, xx.x",
  range = "xx.x to xx.x",
  range_event = "xx.x to xx.x",
  range_censor = "xx.x to xx.x",
  quantiles_lower = "xx.x (xx.x - xx.x)",
  quantiles_upper = "xx.x (xx.x - xx.x)",
  median_ci_3d = "xx.x (xx.x - xx.x)"
)


#' @keywords internal
a_tte_mean_sd <- function(x, ...) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(rtables::in_rows(
      "Mean (SD)" = rtables::rcell(c(NA_real_, NA_real_), format = "xx.xx (xx.xx)")
    ))
  }
  sdx <- if (length(x) > 1L) stats::sd(x) else NA_real_
  rtables::in_rows(
    "Mean (SD)" = rtables::rcell(c(mean(x), sdx), format = "xx.xx (xx.xx)")
  )
}


#' @keywords internal
combine_vertical_sections <- function(...) {
  parts <- Filter(Negate(is.null), list(...))
  if (length(parts) == 0L) {
    return(rtables::in_rows())
  }
  if (length(parts) == 1L) {
    return(parts[[1L]])
  }

  values <- do.call(c, lapply(parts, as.list))
  nms <- unlist(lapply(parts, function(p) attr(p, "row_names")), use.names = FALSE)
  labs <- unlist(lapply(parts, function(p) attr(p, "row_labels")), use.names = FALSE)
  cell_fn <- unlist(
    lapply(parts, function(p) lapply(as.list(p), function(z) attr(z, "footnotes"))),
    recursive = FALSE,
    use.names = FALSE
  )

  rtables::in_rows(
    .list = values,
    .names = nms,
    .labels = unname(labs),
    .cell_footnotes = cell_fn
  )
}


#' @keywords internal
a_tte_surv_block <- function(df, .var, is_event, control, surv_stats, ...) {
  mean_part <- NULL
  if ("mean_sd" %in% surv_stats) {
    mean_part <- a_tte_mean_sd(df[[.var]])
  }

  km_stats <- setdiff(surv_stats, "mean_sd")
  km_part <- NULL
  if (length(km_stats) > 0L) {
    km_part <- tern::a_surv_time(
      df,
      .var = .var,
      is_event = is_event,
      control = control,
      .stats = km_stats,
      .formats = .tte_surv_time_formats,
      .labels = list(
        median_ci = "95% CI",
        quantiles = "Q1, Q3",
        range = "Min, Max"
      ),
      .indent_mods = list(median_ci = 1L),
      ref_fn_censor = TRUE
    )
  }

  combine_vertical_sections(mean_part, km_part)
}


#' @keywords internal
add_surv_time_block <- function(lyt,
                                vars,
                                is_event,
                                control,
                                surv_stats,
                                var_labels,
                                table_names) {
  rtables::analyze(
    lyt,
    vars = vars,
    afun = a_tte_surv_block,
    extra_args = list(
      is_event = is_event,
      control = control,
      surv_stats = surv_stats
    ),
    var_labels = var_labels,
    show_labels = "visible",
    table_names = table_names,
    na_str = "NE"
  )
}
