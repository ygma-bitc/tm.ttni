synthetic_ttni_fixture <- function(design = "two_arm", ...) {
  make_synthetic_ttni_data(design = design, n_per_arm = 20L, seed = 42L, ...)
}

printed_table <- function(tbl) {
  paste(utils::capture.output(suppressMessages(print(tbl))), collapse = "\n")
}
