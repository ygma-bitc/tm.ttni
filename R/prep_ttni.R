#' Prepare ADSL / ADTTE records for a TTE table
#'
#' Accepts either a single ADSL-like data frame that already contains TTE
#' variables (`PARAMCD`, `AVAL`, `CNSR`, `EVNTDESC`) or a separate ADTTE
#' data frame joined to ADSL by subject. An empty result after filtering is
#' returned as a structured list (`empty = TRUE`) rather than an error so the
#' teal module can show a no-data message.
#'
#' @param adsl ADSL or combined subject-level TTE data.
#' @param adtte Optional ADTTE data frame. If `NULL`, `adsl` is used as the
#'   TTE source.
#' @param arm_var Treatment / grouping variable.
#' @param ref_arm Optional reference arm for two-arm comparisons.
#' @param paramcd Analysis parameter code.
#' @param subject_var Subject identifier.
#' @param paramcd_var PARAMCD variable name.
#' @param aval_var Analysis value variable.
#' @param cnsr_var Censor variable (`0` = event).
#' @param evntdesc_var Event / censor description variable.
#' @param population_var Optional population flag variable.
#' @param population_value Population flag value to keep.
#'
#' @return A list with analysis data, design metadata, description levels, and
#'   `empty` (`TRUE` when no records remain).
#' @export
prep_ttni_data <- function(adsl,
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
                           population_value = "Y") {
  checkmate::assert_data_frame(adsl)
  checkmate::assert_data_frame(adtte, null.ok = TRUE)
  checkmate::assert_string(arm_var)
  checkmate::assert_string(ref_arm, null.ok = TRUE)
  checkmate::assert_string(paramcd)
  checkmate::assert_string(subject_var)
  checkmate::assert_string(paramcd_var)
  checkmate::assert_string(aval_var)
  checkmate::assert_string(cnsr_var)
  checkmate::assert_string(evntdesc_var)
  checkmate::assert_string(population_var, null.ok = TRUE)

  tte_src <- if (is.null(adtte)) adsl else adtte
  assert_required_cols(tte_src, c(subject_var, paramcd_var, aval_var, cnsr_var), "ADTTE")

  if (paramcd_var %in% names(tte_src)) {
    tte <- tte_src[eq_chr(tte_src[[paramcd_var]], paramcd), , drop = FALSE]
  } else {
    tte <- tte_src
  }

  if (!is.null(population_var) && population_var %in% names(adsl)) {
    keep_id <- adsl[[subject_var]][eq_chr(adsl[[population_var]], population_value)]
    tte <- tte[tte[[subject_var]] %in% keep_id, , drop = FALSE]
    alt_counts <- adsl[eq_chr(adsl[[population_var]], population_value), , drop = FALSE]
  } else {
    alt_counts <- adsl
  }

  if (!arm_var %in% names(tte)) {
    assert_required_cols(adsl, c(subject_var, arm_var), "ADSL")
    arm_map <- unique(adsl[, c(subject_var, arm_var), drop = FALSE])
    tte <- merge(tte, arm_map, by = subject_var, all.x = TRUE, sort = FALSE)
  }

  if (nrow(tte) > 0L && "AVALU" %in% names(tte)) {
    tte[[aval_var]] <- convert_aval_to_months(tte[[aval_var]], tte[["AVALU"]])
    tte[["AVALU"]] <- "MONTHS"
  }

  if (!evntdesc_var %in% names(tte)) {
    tte[[evntdesc_var]] <- ifelse(
      as.integer(tte[[cnsr_var]]) == 0L,
      default_ttni_event_levels()[[1L]],
      default_ttni_censor_levels()[[1L]]
    )
  }

  tte <- tte[
    !is.na(tte[[aval_var]]) & !is.na(tte[[cnsr_var]]) & is_present_chr(tte[[arm_var]]),
    ,
    drop = FALSE
  ]

  empty_result <- function(design) {
    list(
      anl = tte,
      alt_counts_df = alt_counts,
      design = design,
      arm_var = arm_var,
      aval_var = aval_var,
      cnsr_var = cnsr_var,
      evntdesc_var = evntdesc_var,
      event_levels = character(),
      censor_levels = character(),
      paramcd = paramcd,
      empty = TRUE
    )
  }

  if (nrow(tte) == 0L) {
    design_src <- if (arm_var %in% names(alt_counts) && nrow(alt_counts) > 0L) {
      alt_counts
    } else {
      tte
    }
    design <- if (nrow(design_src) == 0L || !arm_var %in% names(design_src)) {
      detect_arm_design(
        data.frame(tmp_arm = character(), stringsAsFactors = FALSE),
        arm_var = "tmp_arm",
        ref_arm = ref_arm
      )
    } else {
      detect_arm_design(design_src, arm_var = arm_var, ref_arm = ref_arm)
    }
    return(empty_result(design))
  }

  design <- detect_arm_design(tte, arm_var = arm_var, ref_arm = ref_arm)
  tte[[arm_var]] <- factor_arm(tte[[arm_var]], design)
  tte$is_event <- as.integer(tte[[cnsr_var]]) == 0L
  tte$is_followup <- as.integer(tte[[cnsr_var]]) == 1L

  if (arm_var %in% names(alt_counts)) {
    alt_counts <- alt_counts[is_present_chr(alt_counts[[arm_var]]), , drop = FALSE]
    alt_counts[[arm_var]] <- factor_arm(alt_counts[[arm_var]], design)
    alt_counts <- alt_counts[alt_counts[[arm_var]] %in% design$arms, , drop = FALSE]
  } else {
    alt_counts <- tte
  }

  event_levels <- resolve_desc_levels(
    tte[[evntdesc_var]][tte$is_event],
    preferred = default_ttni_event_levels()
  )
  censor_levels <- resolve_desc_levels(
    tte[[evntdesc_var]][tte$is_followup],
    preferred = default_ttni_censor_levels()
  )

  list(
    anl = tte,
    alt_counts_df = alt_counts,
    design = design,
    arm_var = arm_var,
    aval_var = aval_var,
    cnsr_var = cnsr_var,
    evntdesc_var = evntdesc_var,
    event_levels = event_levels,
    censor_levels = censor_levels,
    paramcd = paramcd,
    empty = FALSE
  )
}
