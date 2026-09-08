#' Detect whether a TTE table should use two-arm inferential statistics
#'
#' TTNI can appear in a multi-dose Phase 1/2 study or a two-arm randomized
#' trial. Hazard ratio, Wald CI, and log-rank p-value are only appropriate
#' when exactly two treatment arms are present.
#'
#' @param data A data frame containing the treatment variable.
#' @param arm_var `character(1)` Treatment / grouping variable name.
#' @param ref_arm `character(1)` or `NULL` Reference arm. Defaults to the
#'   first factor level (or first unique value).
#'
#' @return A list with `n_arms`, `arms`, `ref_arm`, `comp_arms`, `design`
#'   (`single_arm`, `two_arm`, or `multi_arm`), and `compute_hr`.
#'
#' @examples
#' detect_arm_design(
#'   data.frame(TRT01A = c("Placebo", "Drug")),
#'   arm_var = "TRT01A",
#'   ref_arm = "Placebo"
#' )
#'
#' @export
detect_arm_design <- function(data, arm_var, ref_arm = NULL) {
  checkmate::assert_data_frame(data)
  checkmate::assert_string(arm_var)
  checkmate::assert_string(ref_arm, null.ok = TRUE)
  assert_required_cols(data, arm_var)

  if (nrow(data) == 0L) {
    return(list(
      n_arms = 0L,
      arms = character(),
      ref_arm = if (is.null(ref_arm) || !nzchar(ref_arm)) NA_character_ else ref_arm,
      comp_arms = character(),
      design = "single_arm",
      compute_hr = FALSE
    ))
  }

  arm_raw <- data[[arm_var]]
  if (is.factor(arm_raw)) {
    arms <- levels(droplevels(arm_raw))
    arms <- arms[is_present_chr(arms) & arms %in% as.character(arm_raw)]
  } else {
    arms <- unique(as.character(arm_raw))
    arms <- arms[is_present_chr(arms)]
  }

  n_arms <- length(arms)
  design <- if (n_arms <= 1L) {
    "single_arm"
  } else if (n_arms == 2L) {
    "two_arm"
  } else {
    "multi_arm"
  }

  if (is.null(ref_arm) || !nzchar(ref_arm)) {
    ref_arm <- if (n_arms >= 1L) arms[[1L]] else NA_character_
  } else if (n_arms > 0L && !ref_arm %in% arms) {
    warning(
      sprintf("ref_arm '%s' was not found among treatment levels; using '%s'.", ref_arm, arms[[1L]]),
      call. = FALSE
    )
    ref_arm <- arms[[1L]]
  }

  list(
    n_arms = n_arms,
    arms = arms,
    ref_arm = ref_arm,
    comp_arms = setdiff(arms, ref_arm),
    design = design,
    compute_hr = identical(design, "two_arm")
  )
}


#' @keywords internal
resolve_compute_hr <- function(design, compute_hr = NULL) {
  if (is.null(compute_hr)) {
    return(isTRUE(design$compute_hr))
  }

  checkmate::assert_flag(compute_hr)
  if (isTRUE(compute_hr) && !identical(design$design, "two_arm")) {
    warning(
      "Hazard ratio, CI, and p-value are calculated only for two-arm designs; skipping inferential statistics.",
      call. = FALSE
    )
    return(FALSE)
  }

  isTRUE(compute_hr) && identical(design$design, "two_arm")
}


#' @keywords internal
resolve_show_total <- function(design, show_total = NULL) {
  if (is.null(show_total)) {
    return(identical(design$design, "multi_arm"))
  }
  checkmate::assert_flag(show_total)
  isTRUE(show_total)
}


#' @keywords internal
factor_arm <- function(x, design) {
  arm_levels <- unique(c(design$ref_arm, design$arms))
  arm_levels <- arm_levels[is_present_chr(arm_levels)]
  factor(as.character(x), levels = arm_levels)
}
