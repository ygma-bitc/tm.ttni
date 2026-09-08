#' Standardize an ADSL-like data frame for TTE tables
#'
#' Harmonizes common CDISC Pilot / `random.cdisc.data` column variants so
#' [prep_ttni_data()] can join treatment and population flags.
#'
#' @param adsl A data frame with at least `USUBJID`.
#' @return A standardized ADSL data frame.
#' @export
standardize_adsl <- function(adsl) {
  checkmate::assert_data_frame(adsl)
  assert_required_cols(adsl, "USUBJID")

  trt01a <- if ("TRT01A" %in% names(adsl)) {
    adsl[["TRT01A"]]
  } else if ("ARM" %in% names(adsl)) {
    adsl[["ARM"]]
  } else {
    rep("Treatment A", nrow(adsl))
  }

  out <- adsl
  out$STUDYID <- as.character(tte_col_or(adsl, "STUDYID", "MOCK-STUDY"))
  out$USUBJID <- as.character(adsl$USUBJID)
  out$TRT01A <- as.character(trt01a)
  out$SAFFL <- as.character(tte_col_or(adsl, "SAFFL", "Y"))
  out$ITTFL <- as.character(tte_col_or(adsl, "ITTFL", out$SAFFL))
  out$SEX <- as.character(tte_col_or(adsl, "SEX", NA_character_))
  out$RACE <- as.character(tte_col_or(adsl, "RACE", NA_character_))
  out$COUNTRY <- as.character(tte_col_or(adsl, "COUNTRY", NA_character_))
  if ("TRTSDT" %in% names(adsl)) {
    out$TRTSDT <- tte_to_date(adsl$TRTSDT)
  }
  if ("TRTEDT" %in% names(adsl)) {
    out$TRTEDT <- tte_to_date(adsl$TRTEDT)
  }
  if ("LSTALVDT" %in% names(adsl)) {
    out$LSTALVDT <- tte_to_date(adsl$LSTALVDT)
  }
  if ("DTHDT" %in% names(adsl)) {
    out$DTHDT <- tte_to_date(adsl$DTHDT)
  }
  if ("DTHFL" %in% names(adsl)) {
    out$DTHFL <- as.character(adsl$DTHFL)
  }

  out[!duplicated(out$USUBJID), , drop = FALSE]
}


#' Standardize an ADTTE-like data frame
#'
#' Ensures `PARAMCD` / `PARAM` / `AVAL` / `CNSR` exist and converts day-valued
#' `AVAL` to months when `AVALU` is `DAYS`.
#'
#' @param adtte A data frame with at least `USUBJID` and a time-to-event value.
#' @param adsl Optional standardized ADSL used to back-fill `TRT01A`.
#' @param default_avalu Unit used when `AVALU` is missing. `NULL` infers
#'   `DAYS` when the maximum `AVAL` exceeds 60, otherwise `MONTHS`.
#' @return A standardized ADTTE data frame.
#' @export
standardize_adtte <- function(adtte, adsl = NULL, default_avalu = NULL) {
  checkmate::assert_data_frame(adtte)
  checkmate::assert_data_frame(adsl, null.ok = TRUE)
  checkmate::assert_string(default_avalu, null.ok = TRUE)
  assert_required_cols(adtte, "USUBJID")

  aval_var <- if ("AVAL" %in% names(adtte)) {
    "AVAL"
  } else if ("AVALC" %in% names(adtte) && is.numeric(suppressWarnings(as.numeric(adtte$AVALC)))) {
    "AVALC"
  } else {
    stop("[ADTTE] Missing required column(s): AVAL", call. = FALSE)
  }

  out <- adtte
  out$STUDYID <- as.character(tte_col_or(adtte, "STUDYID", "MOCK-STUDY"))
  out$USUBJID <- as.character(adtte$USUBJID)
  out$PARAMCD <- as.character(tte_col_or(adtte, "PARAMCD", "TTE"))
  out$PARAM <- as.character(tte_col_or(adtte, "PARAM", out$PARAMCD))
  out$CNSR <- as.integer(tte_col_or(adtte, "CNSR", 1L))
  if ("AVALU" %in% names(adtte) && any(is_present_chr(adtte$AVALU))) {
    avalu <- adtte$AVALU
  } else if (!is.null(default_avalu)) {
    avalu <- default_avalu
  } else {
    max_aval <- suppressWarnings(max(as.numeric(adtte[[aval_var]]), na.rm = TRUE))
    avalu <- if (is.finite(max_aval) && max_aval > 60) "DAYS" else "MONTHS"
  }
  out$AVAL <- convert_aval_to_months(adtte[[aval_var]], avalu)
  out$AVALU <- "MONTHS"
  if ("EVNTDESC" %in% names(adtte)) {
    out$EVNTDESC <- as.character(adtte$EVNTDESC)
  } else if ("CNSDTDSC" %in% names(adtte)) {
    out$EVNTDESC <- ifelse(
      out$CNSR == 0L,
      default_ttni_event_levels()[[1L]],
      as.character(adtte$CNSDTDSC)
    )
  }
  if ("TRT01A" %in% names(adtte)) {
    out$TRT01A <- as.character(adtte$TRT01A)
  }

  if (!is.null(adsl) && "TRT01A" %in% names(adsl)) {
    arm_map <- unique(adsl[, c("USUBJID", "TRT01A"), drop = FALSE])
    names(arm_map)[2L] <- "TRT01A_ADSL"
    out <- merge(out, arm_map, by = "USUBJID", all.x = TRUE, sort = FALSE)
    if ("TRT01A" %in% names(out)) {
      out$TRT01A <- ifelse(is_present_chr(out$TRT01A), out$TRT01A, out$TRT01A_ADSL)
    } else {
      out$TRT01A <- out$TRT01A_ADSL
    }
    out$TRT01A_ADSL <- NULL
  }

  out
}


#' Derive a simple OS-style ADTTE from ADSL death / last-alive dates
#'
#' Used when a local CDISC Pilot checkout has ADSL but no ADTTE, or when a
#' demo needs a second PARAMCD alongside a native TTE dataset.
#'
#' @param adsl Standardized ADSL with `TRTSDT` and either `DTHDT` / `DTHFL`
#'   or `LSTALVDT`.
#' @param paramcd Parameter code to assign.
#' @param param Parameter label.
#' @return An ADTTE-like data frame.
#' @export
derive_mock_adtte <- function(adsl,
                              paramcd = "OS",
                              param = "Overall Survival") {
  checkmate::assert_data_frame(adsl)
  assert_required_cols(adsl, c("USUBJID", "TRTSDT"))
  checkmate::assert_string(paramcd)
  checkmate::assert_string(param)

  trtsdt <- tte_to_date(adsl$TRTSDT)
  dthfl <- if ("DTHFL" %in% names(adsl)) eq_chr(adsl$DTHFL, "Y") else rep(FALSE, nrow(adsl))
  dthdt <- if ("DTHDT" %in% names(adsl)) tte_to_date(adsl$DTHDT) else as.Date(rep(NA, nrow(adsl)))
  lstalvdt <- if ("LSTALVDT" %in% names(adsl)) {
    tte_to_date(adsl$LSTALVDT)
  } else if ("TRTEDT" %in% names(adsl)) {
    tte_to_date(adsl$TRTEDT)
  } else {
    trtsdt + 180L
  }

  is_event <- dthfl & !is.na(dthdt)
  adt <- as.Date(ifelse(is_event, dthdt, lstalvdt), origin = "1970-01-01")
  aval <- as.numeric(adt - trtsdt + 1L) / 30.4375

  data.frame(
    STUDYID = as.character(tte_col_or(adsl, "STUDYID", "MOCK-STUDY")),
    USUBJID = as.character(adsl$USUBJID),
    PARAMCD = paramcd,
    PARAM = param,
    PARAMN = 99L,
    AVAL = aval,
    AVALU = "MONTHS",
    CNSR = as.integer(!is_event),
    EVNTDESC = ifelse(is_event, "Death", "Last known alive date"),
    STARTDT = trtsdt,
    ADT = adt,
    stringsAsFactors = FALSE
  )
}
