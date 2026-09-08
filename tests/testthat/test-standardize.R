test_that("standardize_adsl() fills TRT01A from ARM when needed", {
  raw <- data.frame(
    USUBJID = c("S1", "S1", "S2"),
    ARM = c("Placebo", "Placebo", "Drug"),
    SEX = c("F", "F", "M"),
    stringsAsFactors = FALSE
  )
  out <- standardize_adsl(raw)
  expect_equal(nrow(out), 2L)
  expect_equal(out$TRT01A, c("Placebo", "Drug"))
  expect_true(all(c("SAFFL", "ITTFL") %in% names(out)))
})

test_that("standardize_adtte() converts DAYS and back-fills TRT01A", {
  adsl <- data.frame(
    USUBJID = c("S1", "S2"),
    TRT01A = c("Placebo", "Drug"),
    stringsAsFactors = FALSE
  )
  adtte <- data.frame(
    USUBJID = c("S1", "S2"),
    PARAMCD = c("TTDE", "TTDE"),
    PARAM = "Time to First Dermatologic Event",
    AVAL = c(60, 90),
    AVALU = "DAYS",
    CNSR = c(0L, 1L),
    stringsAsFactors = FALSE
  )

  out <- standardize_adtte(adtte, adsl)
  expect_equal(out$AVALU, c("MONTHS", "MONTHS"))
  expect_equal(out$TRT01A, c("Placebo", "Drug"))
  expect_lt(out$AVAL[[1L]], 3)
})

test_that("standardize_adtte() infers DAYS when AVALU is missing and values are large", {
  adtte <- data.frame(
    USUBJID = c("S1", "S2"),
    PARAMCD = "TTDE",
    AVAL = c(10, 180),
    CNSR = c(0L, 1L),
    stringsAsFactors = FALSE
  )
  out <- standardize_adtte(adtte, default_avalu = "DAYS")
  expect_lt(max(out$AVAL), 7)
  expect_equal(unique(out$AVALU), "MONTHS")
})

test_that("derive_mock_adtte() uses death dates as events", {
  adsl <- data.frame(
    USUBJID = c("S1", "S2"),
    TRTSDT = as.Date(c("2020-01-01", "2020-01-01")),
    DTHFL = c("Y", "N"),
    DTHDT = as.Date(c("2020-04-01", NA)),
    LSTALVDT = as.Date(c("2020-04-01", "2020-07-01")),
    stringsAsFactors = FALSE
  )
  out <- derive_mock_adtte(adsl)
  expect_equal(out$CNSR, c(0L, 1L))
  expect_equal(out$EVNTDESC, c("Death", "Last known alive date"))
  expect_equal(out$PARAMCD, c("OS", "OS"))
})
