test_that("detect_arm_design() classifies single, two, and multi-arm data", {
  one <- detect_arm_design(data.frame(TRT01A = rep("A", 5)), arm_var = "TRT01A")
  expect_equal(one$design, "single_arm")
  expect_false(one$compute_hr)

  two <- detect_arm_design(
    data.frame(TRT01A = c("Placebo", "Drug")),
    arm_var = "TRT01A",
    ref_arm = "Placebo"
  )
  expect_equal(two$design, "two_arm")
  expect_true(two$compute_hr)
  expect_equal(two$ref_arm, "Placebo")
  expect_equal(two$comp_arms, "Drug")

  multi <- detect_arm_design(
    data.frame(TRT01A = c("Arm A", "Arm B", "Arm C")),
    arm_var = "TRT01A"
  )
  expect_equal(multi$design, "multi_arm")
  expect_false(multi$compute_hr)
  expect_equal(multi$n_arms, 3L)
})

test_that("detect_arm_design() handles an empty data frame", {
  empty <- detect_arm_design(data.frame(TRT01A = character()), arm_var = "TRT01A")
  expect_equal(empty$n_arms, 0L)
  expect_false(empty$compute_hr)
  expect_equal(empty$design, "single_arm")
})

test_that("resolve_compute_hr() ignores HR requests on multi-arm data", {
  multi <- detect_arm_design(
    data.frame(TRT01A = c("A", "B", "C")),
    arm_var = "TRT01A"
  )
  expect_warning(
    expect_false(tm.ttni:::resolve_compute_hr(multi, compute_hr = TRUE)),
    regexp = "only for two-arm"
  )
  expect_true(tm.ttni:::resolve_compute_hr(detect_arm_design(
    data.frame(TRT01A = c("A", "B")),
    arm_var = "TRT01A"
  )))
})
