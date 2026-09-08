test_that("prep_ttni_data() joins ADSL arms onto a BDS ADTTE", {
  data <- synthetic_ttni_fixture("two_arm")
  prepped <- expect_silent(
    prep_ttni_data(
      adsl = data$ADSL,
      adtte = data$ADTTE,
      paramcd = "TTNI",
      arm_var = "TRT01A",
      ref_arm = "Placebo"
    )
  )

  expect_false(prepped$empty)
  expect_true(all(
    c("anl", "alt_counts_df", "design", "event_levels", "censor_levels") %in% names(prepped)
  ))
  expect_gt(nrow(prepped$anl), 0L)
  expect_true("TRT01A" %in% names(prepped$anl))
  expect_s3_class(prepped$anl$TRT01A, "factor")
  expect_equal(prepped$paramcd, "TTNI")
  expect_equal(prepped$design$design, "two_arm")
  expect_true(all(prepped$anl$PARAMCD == "TTNI"))
})

test_that("prep_ttni_data() selects OS by PARAMCD and is case-insensitive", {
  data <- synthetic_ttni_fixture("two_arm")
  prepped <- prep_ttni_data(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    paramcd = "os"
  )

  expect_false(prepped$empty)
  expect_true(all(toupper(prepped$anl$PARAMCD) == "OS"))
  expect_true(all(prepped$anl$EVNTDESC %in% c("Death", "Last known alive date")))
})

test_that("prep_ttni_data() applies population filters", {
  data <- synthetic_ttni_fixture("two_arm")
  data$ADSL$SAFFL[1:5] <- "N"

  prepped <- prep_ttni_data(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    paramcd = "TTNI"
  )

  expect_false(any(prepped$anl$USUBJID %in% data$ADSL$USUBJID[1:5]))
  expect_equal(nrow(prepped$alt_counts_df), nrow(data$ADSL) - 5L)
})

test_that("prep_ttni_data() returns empty instead of stopping", {
  data <- synthetic_ttni_fixture("two_arm")
  data$ADSL$SAFFL <- "N"

  prepped <- expect_silent(
    prep_ttni_data(
      adsl = data$ADSL,
      adtte = data$ADTTE,
      paramcd = "TTNI"
    )
  )

  expect_true(prepped$empty)
  expect_equal(nrow(prepped$anl), 0L)
  expect_equal(nrow(prepped$alt_counts_df), 0L)
})

test_that("prep_ttni_data() fills EVNTDESC when missing", {
  data <- synthetic_ttni_fixture("two_arm")
  data$ADTTE$EVNTDESC <- NULL

  prepped <- prep_ttni_data(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    paramcd = "TTNI"
  )

  expect_true("EVNTDESC" %in% names(prepped$anl))
  expect_true(all(!is.na(prepped$anl$EVNTDESC) & nzchar(prepped$anl$EVNTDESC)))
})

test_that("prep_ttni_data() converts day-valued AVAL to months", {
  data <- synthetic_ttni_fixture("two_arm")
  data$ADTTE$AVAL <- data$ADTTE$AVAL * 30.4375
  data$ADTTE$AVALU <- "DAYS"

  prepped <- prep_ttni_data(
    adsl = data$ADSL,
    adtte = data$ADTTE,
    paramcd = "TTNI"
  )

  expect_true(all(prepped$anl$AVAL <= 36.5))
  expect_true(all(prepped$anl$AVALU == "MONTHS"))
})
