test_that("make_synthetic_ttni_data() returns distinct ADSL and ADTTE", {
  two <- make_synthetic_ttni_data("two_arm", n_per_arm = 10L, seed = 1L)
  multi <- make_synthetic_ttni_data("multi_arm", n_per_arm = 8L, seed = 1L)

  expect_named(two, c("ADSL", "ADTTE"))
  expect_equal(nlevels(two$ADSL$TRT01A), 2L)
  expect_equal(nlevels(multi$ADSL$TRT01A), 3L)
  expect_equal(levels(multi$ADSL$TRT01A), c("Arm A", "Arm B", "Arm C"))
  expect_false(identical(two$ADSL, two$ADTTE))
  expect_false("AVAL" %in% names(two$ADSL))
  expect_true(all(c("AVAL", "AVALU", "CNSR", "EVNTDESC", "PARAMCD", "PARAM") %in% names(two$ADTTE)))
  expect_true(all(c("TTNI", "OS") %in% two$ADTTE$PARAMCD))
  expect_true(all(c("SEX", "RACE", "COUNTRY", "ITTFL") %in% names(two$ADSL)))
})

test_that("tm_t_ttni() returns a teal module", {
  mod <- expect_silent(
    tm_t_ttni(
      label = "TTNI Demo",
      group_vars = c("Actual Treatment" = "TRT01A")
    )
  )

  expect_s3_class(mod, "teal_module")
  expect_equal(mod$label, "TTNI Demo")
  expect_true(all(c("ADSL", "ADTTE") %in% mod$datanames))
})

test_that("tm_t_ttni() validates cat class", {
  expect_error(
    tm_t_ttni(
      label = "TTNI Demo",
      cat = "TTNI"
    ),
    regexp = "choices_selected|Assertion"
  )
})

test_that("tm_t_ttni() validates named group_vars", {
  expect_error(
    tm_t_ttni(
      label = "TTNI Demo",
      group_vars = c("TRT01A")
    ),
    regexp = "named|Assertion"
  )
})

test_that("synthetic fixtures use generic arm names and no specific dose regimens", {
  two <- make_synthetic_ttni_data("two_arm", n_per_arm = 8L, seed = 1L)
  multi <- make_synthetic_ttni_data("multi_arm", n_per_arm = 8L, seed = 1L)
  specific_patterns <- "(?:mg\\s+(?:BID|QD)|\\b\\d+\\s*mg\\b)"
  labels <- c(
    default_ttni_event_levels(),
    as.character(two$ADSL$TRT01A),
    as.character(multi$ADSL$TRT01A),
    unique(as.character(two$ADTTE$EVNTDESC)),
    unique(as.character(multi$ADTTE$EVNTDESC))
  )
  expect_false(any(grepl(specific_patterns, labels, ignore.case = TRUE)))
  expect_equal(levels(two$ADSL$TRT01A), c("Placebo", "Investigational"))
  expect_equal(levels(multi$ADSL$TRT01A), c("Arm A", "Arm B", "Arm C"))
})
