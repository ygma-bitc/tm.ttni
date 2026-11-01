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
    tm_t_ttni(label = "TTNI Demo")
  )

  expect_s3_class(mod, "teal_module")
  expect_equal(mod$label, "TTNI Demo")
  expect_true(all(c("ADSL", "ADTTE") %in% mod$datanames))

  arm <- mod$ui_args$arm_var
  pop <- mod$ui_args$population_var
  expect_s3_class(arm, "picks")
  expect_identical(arm, mod$server_args$arm_var)
  expect_identical(arm$datasets$selected, "ADSL")
  expect_identical(arm$variables$selected, "TRT01A")
  expect_false(teal.picks::is_pick_multiple(arm$variables))
  expect_s3_class(pop, "picks")
  expect_identical(pop, mod$server_args$population_var)
  expect_identical(pop$datasets$selected, "ADSL")
  expect_identical(pop$variables$choices, c("SAFFL", "ITTFL"))
  expect_identical(pop$variables$selected, "SAFFL")
  expect_false(teal.picks::is_pick_multiple(pop$variables))
  expect_null(arm$values)
  expect_null(pop$values)
})

test_that("tm_t_ttni() defaults cat to a single-PARAMCD picks object", {
  mod <- expect_silent(tm_t_ttni(label = "TTNI Demo"))
  cat <- mod$server_args$tte_cat

  expect_s3_class(cat, "picks")
  expect_identical(mod$ui_args$tte_cat, cat)
  expect_identical(cat$datasets$selected, "ADTTE")
  expect_identical(cat$variables$selected, "PARAMCD")
  expect_false(teal.picks::is_pick_multiple(cat$variables))
  expect_true(teal.picks::is_pick_fixed(cat$variables))
  expect_identical(cat$values$selected, "TTNI")
  expect_false(teal.picks::is_pick_multiple(cat$values))
})

test_that("default picks resolves to one PARAMCD string", {
  mod <- tm_t_ttni()
  data <- make_synthetic_ttni_data("two_arm", n_per_arm = 8L, seed = 1L)
  td <- teal.data::teal_data(ADSL = data$ADSL, ADTTE = data$ADTTE)
  resolved <- teal.picks::resolver(mod$server_args$tte_cat, td)
  sel <- as.character(resolved$values$selected)

  expect_length(sel, 1L)
  expect_identical(sel, "TTNI")
  expect_true(sel %in% data$ADTTE$PARAMCD)
})

test_that("tm_t_ttni() uses tte_name and paramcd in the default picks", {
  mod <- expect_silent(tm_t_ttni(tte_name = "ADTTE_OPEN", paramcd = "OS"))
  cat <- mod$server_args$tte_cat

  expect_identical(cat$datasets$selected, "ADTTE_OPEN")
  expect_identical(cat$datasets$choices, "ADTTE_OPEN")
  expect_identical(cat$values$selected, "OS")
  expect_true("ADTTE_OPEN" %in% mod$datanames)
})

test_that("tm_t_ttni() accepts an explicit picks object", {
  picks <- teal.picks::picks(
    teal.picks::datasets("ADTTE", "ADTTE"),
    teal.picks::variables("PARAMCD", "PARAMCD", multiple = FALSE, fixed = TRUE),
    teal.picks::values(c("TTNI", "OS"), "OS", multiple = FALSE)
  )
  mod <- expect_silent(tm_t_ttni(cat = picks))
  expect_identical(mod$server_args$tte_cat$values$selected, "OS")
  expect_identical(mod$server_args$tte_cat$values$choices, c("TTNI", "OS"))
})

test_that("tm_t_ttni() deprecates choices_selected and converts it", {
  cs <- structure(
    list(choices = c("TTNI", "OS"), selected = "OS", fixed = FALSE),
    class = "choices_selected"
  )
  expect_warning(
    mod <- tm_t_ttni(cat = cs),
    class = "lifecycle_warning_deprecated"
  )
  cat <- mod$server_args$tte_cat
  expect_s3_class(cat, "picks")
  expect_identical(cat$datasets$selected, "ADTTE")
  expect_identical(cat$variables$selected, "PARAMCD")
  expect_false(teal.picks::is_pick_multiple(cat$variables))
  expect_identical(cat$values$selected, "OS")
  expect_false(teal.picks::is_pick_multiple(cat$values))
})

test_that("tm_t_ttni() converts delayed choices_selected without a static level list", {
  delayed <- structure(
    list(
      data = "ADTTE",
      var_choices = "PARAMCD",
      var_label = "PARAM",
      subset = NULL,
      sep = " - "
    ),
    class = c("delayed_value_choices", "delayed_data", "choices_labeled")
  )
  cs <- structure(
    list(choices = delayed, selected = "TTNI", fixed = FALSE),
    class = c("delayed_choices_selected", "delayed_data", "choices_selected")
  )
  expect_warning(
    mod <- tm_t_ttni(cat = cs, tte_name = "ADTTE_OPEN"),
    class = "lifecycle_warning_deprecated"
  )
  cat <- mod$server_args$tte_cat
  expect_identical(cat$datasets$selected, "ADTTE_OPEN")
  expect_identical(cat$variables$selected, "PARAMCD")
  expect_true(teal.picks::is_pick_fixed(cat$variables))
  expect_identical(cat$values$selected, "TTNI")
  expect_type(cat$values$choices, "closure")
})

test_that("tm_t_ttni() accepts teal.transform choices_selected", {
  skip_if_not_installed("teal.transform")
  cs <- teal.transform::choices_selected(
    choices = teal.transform::value_choices(
      data = "ADTTE",
      var_choices = "PARAMCD",
      var_label = "PARAM"
    ),
    selected = "OS"
  )
  expect_warning(
    mod <- tm_t_ttni(cat = cs),
    class = "lifecycle_warning_deprecated"
  )
  cat <- mod$server_args$tte_cat
  expect_s3_class(cat, "picks")
  expect_identical(cat$values$selected, "OS")
  expect_identical(cat$variables$selected, "PARAMCD")
})

test_that("tm_t_ttni() rejects a non-picks cat", {
  expect_error(
    tm_t_ttni(
      label = "TTNI Demo",
      cat = "TTNI"
    ),
    regexp = "picks|choices_selected"
  )
})

test_that("tm_t_ttni() rejects a picks object that allows multiple values", {
  picks <- teal.picks::picks(
    teal.picks::datasets("ADTTE", "ADTTE"),
    teal.picks::variables("PARAMCD", "PARAMCD", multiple = FALSE, fixed = TRUE),
    teal.picks::values(c("TTNI", "OS"), c("TTNI", "OS"), multiple = TRUE)
  )
  expect_error(tm_t_ttni(cat = picks), regexp = "multiple")
})

test_that("tm_t_ttni() deprecates a character group_vars vector", {
  expect_warning(
    mod <- tm_t_ttni(
      label = "TTNI Demo",
      group_vars = c("Actual Treatment" = "TRT01A", "Sex" = "SEX"),
      adsl_name = "ADSL_OPEN"
    ),
    class = "lifecycle_warning_deprecated"
  )
  arm <- mod$server_args$arm_var
  expect_s3_class(arm, "picks")
  expect_identical(arm$datasets$selected, "ADSL_OPEN")
  expect_identical(arm$variables$choices, c("TRT01A", "SEX"))
  expect_identical(arm$variables$selected, "TRT01A")
  expect_false(teal.picks::is_pick_multiple(arm$variables))
})

test_that("tm_t_ttni() accepts grouping and population picks", {
  arm <- teal.picks::picks(
    teal.picks::datasets("ADSL", "ADSL"),
    teal.picks::variables(c("TRT01A", "COUNTRY"), "COUNTRY", multiple = FALSE)
  )
  pop <- teal.picks::picks(
    teal.picks::datasets("ADSL", "ADSL"),
    teal.picks::variables(c("SAFFL", "ITTFL"), "ITTFL", multiple = FALSE)
  )
  mod <- expect_silent(tm_t_ttni(group_vars = arm, population_var = pop))
  expect_identical(mod$server_args$arm_var$variables$selected, "COUNTRY")
  expect_identical(mod$server_args$population_var$variables$selected, "ITTFL")
})

test_that("tm_t_ttni() deprecates population_var plus population_choices", {
  expect_warning(
    mod <- tm_t_ttni(
      population_var = "ITTFL",
      population_choices = c("Safety (SAFFL)" = "SAFFL", "ITT (ITTFL)" = "ITTFL")
    ),
    class = "lifecycle_warning_deprecated"
  )
  pop <- mod$server_args$population_var
  expect_identical(pop$variables$choices, c("SAFFL", "ITTFL"))
  expect_identical(pop$variables$selected, "ITTFL")
  expect_false(teal.picks::is_pick_multiple(pop$variables))
})

test_that("tm_t_ttni() rejects a non-column group_vars value", {
  expect_error(
    tm_t_ttni(group_vars = 1),
    regexp = "picks|character"
  )
})

test_that("tm_t_ttni() rejects a grouping pick that allows multiple columns", {
  arm <- teal.picks::picks(
    teal.picks::datasets("ADSL", "ADSL"),
    teal.picks::variables(c("TRT01A", "SEX"), c("TRT01A", "SEX"), multiple = TRUE)
  )
  expect_error(tm_t_ttni(group_vars = arm), regexp = "multiple")
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
