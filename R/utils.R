#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}


#' @keywords internal
assert_required_cols <- function(df, cols, df_name = deparse(substitute(df))) {
  checkmate::assert_data_frame(df)
  checkmate::assert_character(cols, min.len = 1L, any.missing = FALSE)
  checkmate::assert_string(df_name)

  missing_cols <- setdiff(cols, names(df))
  if (length(missing_cols) > 0L) {
    stop(
      sprintf("[%s] Missing required column(s): %s", df_name, paste(missing_cols, collapse = ", ")),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


#' @keywords internal
is_present_chr <- function(x) {
  !is.na(x) & nzchar(trimws(as.character(x)))
}


#' @keywords internal
eq_chr <- function(x, value) {
  toupper(trimws(as.character(x))) == toupper(trimws(as.character(value)))
}


#' @keywords internal
tte_col_or <- function(df, col, default) {
  if (col %in% names(df)) {
    return(df[[col]])
  }
  if (length(default) == nrow(df)) {
    return(default)
  }
  rep(default, nrow(df))
}


#' @keywords internal
tte_to_date <- function(x, origin = "1960-01-01") {
  if (inherits(x, "Date")) {
    return(x)
  }
  if (inherits(x, "POSIXt")) {
    return(as.Date(x))
  }
  if (is.numeric(x)) {
    return(as.Date(x, origin = origin))
  }
  suppressWarnings(as.Date(substr(as.character(x), 1L, 10L)))
}


#' @noRd
convert_aval_to_months <- function(aval, avalu = NULL) {
  aval <- as.numeric(aval)
  if (is.null(avalu)) {
    return(aval)
  }
  unit <- toupper(trimws(as.character(avalu)))
  days <- unit %in% c("D", "DAY", "DAYS")
  aval[days] <- aval[days] / 30.4375
  aval
}


#' @keywords internal
parse_timepoints <- function(x) {
  if (is.numeric(x)) {
    vals <- as.numeric(x)
  } else {
    raw <- unlist(strsplit(as.character(x), "[,\\s]+"), use.names = FALSE)
    vals <- suppressWarnings(as.numeric(raw))
  }

  vals <- sort(unique(vals[!is.na(vals) & vals > 0]))
  if (length(vals) == 0L) {
    stop("No valid positive timepoints were provided.", call. = FALSE)
  }
  vals
}


#' @keywords internal
resolve_desc_levels <- function(x, preferred = character()) {
  present <- unique(as.character(x[is_present_chr(x)]))
  c(intersect(preferred, present), setdiff(present, preferred))
}


#' Default TTE event-reason labels
#'
#' Generic labels used when `EVNTDESC` is missing or to order known reasons.
#' Study-specific wording (for example a named investigational product) should
#' be supplied by the caller, not baked into the package defaults.
#'
#' @return Character vector of preferred event descriptions.
#' @export
default_ttni_event_levels <- function() {
  c(
    "The initiation of subsequent anticancer therapy",
    "First subsequent anticancer therapy",
    "Crossover to investigational product",
    "Death"
  )
}


#' Default TTE censor-reason labels
#'
#' @return Character vector of preferred censoring descriptions.
#' @export
default_ttni_censor_levels <- function() {
  c(
    "Ongoing without an event",
    "Last known alive date",
    "Withdrawal of consent"
  )
}


#' Default TTE footnotes
#'
#' @param compute_hr `logical(1)` Whether inferential statistics are shown.
#' @param conf_type `character(1)` KM confidence-interval type.
#' @return Character vector of footer notes.
#' @export
default_ttni_footnotes <- function(compute_hr = FALSE, conf_type = "log-log") {
  notes <- c(
    paste0(
      "Product-limit (Kaplan-Meier) estimates. Confidence intervals use the ",
      conf_type, " method. Non-estimable values are shown as NE."
    ),
    "Follow-up time uses reverse Kaplan-Meier estimates.",
    "Landmark rates are Kaplan-Meier event-free percentages.",
    "Analysis values stored in days are converted to months (30.4375 days)."
  )

  if (isTRUE(compute_hr)) {
    notes <- c(
      notes,
      "Hazard ratio and 95% CI are from an unstratified Cox model (Efron ties).",
      "p-value is from an unstratified log-rank test.",
      "Inferential statistics are displayed only for two-arm comparisons."
    )
  } else {
    notes <- c(
      notes,
      "Hazard ratio, confidence interval, and p-value are omitted for single-arm or multi-arm (dose-level) designs."
    )
  }

  notes
}


#' @keywords internal
default_tte_title <- function(paramcd = "TTNI") {
  checkmate::assert_string(paramcd)
  if (identical(toupper(paramcd), "TTNI")) {
    "Summary of Time to Next Intervention (TTNI)"
  } else {
    sprintf("Summary of Time-to-Event (%s)", paramcd)
  }
}
