find_pilot_xpt <- function(filename) {
  candidates <- c(
    file.path("data-raw", filename),
    file.path("..", "..", "data-raw", filename)
  )
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    return(NULL)
  }
  normalizePath(existing[[1L]], winslash = "/", mustWork = TRUE)
}

test_that("CDISC Pilot ADTTE builds a multi-arm KM table", {
  skip_if_not_installed("haven")
  adsl_path <- find_pilot_xpt("adsl.xpt")
  adtte_path <- find_pilot_xpt("adtte.xpt")
  skip_if(is.null(adsl_path) || is.null(adtte_path), "CDISC Pilot XPTs are not in data-raw/")

  adsl <- standardize_adsl(haven::read_xpt(adsl_path))
  adtte <- standardize_adtte(haven::read_xpt(adtte_path), adsl, default_avalu = "DAYS")
  paramcd <- if ("TTDE" %in% unique(adtte$PARAMCD)) "TTDE" else as.character(adtte$PARAMCD[[1L]])
  expect_lt(max(adtte$AVAL, na.rm = TRUE), 12)

  tbl <- expect_no_error(
    build_ttni_table(
      adsl = adsl,
      adtte = adtte,
      paramcd = paramcd,
      timepoints = c(3, 6),
      show_total = TRUE,
      include_followup = TRUE
    )
  )

  text <- printed_table(tbl)
  expect_s4_class(tbl, "VTableTree")
  expect_match(text, paste("Parameter:", paramcd), fixed = TRUE)
  expect_match(text, "Number of participants with event")
  expect_match(text, "Kaplan-Meier")
  expect_true(grepl("Placebo|Xanomeline", text))
})

test_that("CDISC Pilot two-arm subset calculates HR", {
  skip_if_not_installed("haven")
  adsl_path <- find_pilot_xpt("adsl.xpt")
  adtte_path <- find_pilot_xpt("adtte.xpt")
  skip_if(is.null(adsl_path) || is.null(adtte_path), "CDISC Pilot XPTs are not in data-raw/")

  adsl <- standardize_adsl(haven::read_xpt(adsl_path))
  arms <- unique(as.character(adsl$TRT01A))
  arms <- arms[!is.na(arms) & nzchar(trimws(arms))]
  skip_if(length(arms) < 2L, "CDISC Pilot ADSL has fewer than 2 arms")

  keep <- arms[c(1L, length(arms))]
  adsl <- adsl[adsl$TRT01A %in% keep, , drop = FALSE]
  adtte <- standardize_adtte(haven::read_xpt(adtte_path), adsl, default_avalu = "DAYS")
  adtte <- adtte[adtte$USUBJID %in% adsl$USUBJID, , drop = FALSE]
  paramcd <- if ("TTDE" %in% unique(adtte$PARAMCD)) "TTDE" else as.character(adtte$PARAMCD[[1L]])

  tbl <- expect_no_error(
    build_ttni_table(
      adsl = adsl,
      adtte = adtte,
      paramcd = paramcd,
      ref_arm = keep[[1L]],
      timepoints = 6,
      include_followup = FALSE
    )
  )

  text <- printed_table(tbl)
  expect_match(text, "Design: two-arm")
  expect_match(text, "Hazard Ratio")
  expect_match(text, "p-value \\(log-rank\\)")
})
