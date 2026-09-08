test_that("two-arm TTNI table includes HR and p-value", {
  data <- synthetic_ttni_fixture("two_arm")
  tbl <- expect_no_error(
    build_ttni_table(
      adsl = data$ADSL,
      adtte = data$ADTTE,
      ref_arm = "Placebo",
      timepoints = c(6, 12)
    )
  )

  expect_s4_class(tbl, "VTableTree")
  text <- printed_table(tbl)
  expect_match(text, "Hazard Ratio")
  expect_match(text, "p-value \\(log-rank\\)")
  expect_match(text, "Number of participants with event")
  expect_match(text, "Number of participants censored")
  expect_match(text, "Mean \\(SD\\)")
  expect_match(text, "Q1, Q3")
  expect_match(text, "Min, Max")
  expect_match(text, "25%-ile")
  expect_match(text, "Median \\(95% CI\\)")
  expect_false(grepl("Median\\s+\\n\\s+95% CI", text))
  expect_false(grepl("(?m)^\\s*95% CI \\(median\\)", text, perl = TRUE))
  expect_match(text, "Design: two-arm")
  expect_false(grepl("HR not calculated", text))
})

test_that("multi-arm TTNI table omits HR and can show Total", {
  data <- synthetic_ttni_fixture("multi_arm")
  tbl <- expect_no_error(
    build_ttni_table(
      adsl = data$ADSL,
      adtte = data$ADTTE,
      timepoints = c(6, 12),
      show_total = TRUE
    )
  )

  text <- printed_table(tbl)
  expect_false(grepl("Hazard Ratio", text))
  expect_false(grepl("p-value \\(log-rank\\)", text))
  expect_match(text, "HR not calculated")
  expect_match(text, "Total")
  expect_match(text, "Arm A")
  expect_match(text, "TTNI Follow-up Time")
})

test_that("forcing compute_hr on multi-arm data still skips inferential stats", {
  data <- synthetic_ttni_fixture("multi_arm")
  expect_warning(
    tbl <- build_ttni_table(
      adsl = data$ADSL,
      adtte = data$ADTTE,
      timepoints = 6,
      compute_hr = TRUE,
      include_followup = FALSE
    ),
    regexp = "only for two-arm"
  )
  expect_false(grepl("Hazard Ratio", printed_table(tbl)))
})

test_that("rate_only landmark style drops patients-at-risk rows", {
  data <- synthetic_ttni_fixture("two_arm")
  detailed <- printed_table(build_ttni_table(
    data$ADSL,
    data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    landmark_style = "detailed",
    include_followup = FALSE
  ))
  rate_only <- printed_table(build_ttni_table(
    data$ADSL,
    data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    landmark_style = "rate_only",
    include_followup = FALSE
  ))

  expect_match(detailed, "Patients remaining at risk")
  expect_false(grepl("Patients remaining at risk", rate_only))
  expect_match(rate_only, "Kaplan-Meier survival rate")
})

test_that("method footnotes are omitted by default and optional when requested", {
  data <- synthetic_ttni_fixture("two_arm")
  plain <- printed_table(build_ttni_table(
    data$ADSL,
    data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    include_followup = FALSE
  ))
  expect_false(grepl("Product-limit \\(Kaplan-Meier\\)", plain))
  expect_false(grepl("unstratified Cox", plain))

  with_notes <- printed_table(build_ttni_table(
    data$ADSL,
    data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    include_followup = FALSE,
    footnotes = default_ttni_footnotes(compute_hr = TRUE)
  ))
  expect_match(with_notes, "Product-limit \\(Kaplan-Meier\\)")
  expect_match(with_notes, "unstratified Cox")
})

test_that("build_ttni_table() accepts a prepped object without re-reading ADSL", {
  data <- synthetic_ttni_fixture("two_arm")
  prepped <- prep_ttni_data(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    paramcd = "OS",
    ref_arm = "Placebo"
  )

  tbl <- build_ttni_table(prepped = prepped, timepoints = 6, include_followup = FALSE)
  expect_match(printed_table(tbl), "Parameter: OS")
  expect_match(printed_table(tbl), "Hazard Ratio")
})

test_that("surv_stats filter uses catalog labels and native order", {
  data <- synthetic_ttni_fixture("two_arm")
  tbl <- build_ttni_table(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    include_followup = FALSE,
    surv_stats = c("range", "median_ci_3d")
  )
  text <- printed_table(tbl)
  expect_match(text, "Median \\(95% CI\\)")
  expect_match(text, "Min, Max")
  expect_false(grepl("Mean \\(SD\\)", text))
  expect_false(grepl("25%-ile", text))
  expect_false(grepl("Q1, Q3", text))
  expect_lt(regexpr("Median \\(95% CI\\)", text), regexpr("Min, Max", text))
})

test_that("legacy median and median_ci fold into one Median (95% CI) row", {
  data <- synthetic_ttni_fixture("two_arm")
  tbl <- build_ttni_table(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    include_followup = FALSE,
    surv_stats = c("median", "median_ci")
  )
  text <- printed_table(tbl)
  expect_match(text, "Median \\(95% CI\\)")
  expect_false(grepl("Mean \\(SD\\)", text))
  expect_false(grepl("Median\\s+\\n\\s+95% CI", text))
})

test_that("unknown surv_stats are ignored with a warning", {
  data <- synthetic_ttni_fixture("two_arm")
  expect_warning(
    build_ttni_table(
      data$ADSL,
      data$ADTTE,
      ref_arm = "Placebo",
      timepoints = 6,
      include_followup = FALSE,
      surv_stats = c("median_ci_3d", "not_a_stat")
    ),
    regexp = "Unknown time-to-event"
  )
})

test_that("two-arm TTNI snapshot remains stable", {
  data <- synthetic_ttni_fixture("two_arm")
  tbl <- build_ttni_table(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    ref_arm = "Placebo",
    timepoints = 6,
    include_followup = FALSE
  )
  expect_snapshot(print(tbl))
})

test_that("multi-arm TTNI snapshot remains stable", {
  data <- synthetic_ttni_fixture("multi_arm")
  tbl <- build_ttni_table(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    timepoints = 6,
    show_total = TRUE,
    include_followup = FALSE
  )
  expect_snapshot(print(tbl))
})
