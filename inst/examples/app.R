# Local teal validation app for tm_t_ttni()
#
# Data priority:
#   1. Existing ADSL / ADTTE objects in the global environment
#   2. Local CDISC Pilot XPTs in data-raw/ (adsl.xpt, adtte.xpt)
#   3. random.cdisc.data::radsl / radtte when available
#   4. Fully synthetic mock data via make_synthetic_ttni_data()
#
# The three-arm (HR off) example is the public CDISC Pilot study
# (Placebo / Xanomeline High Dose / Xanomeline Low Dose).
#
# CDISC Pilot source (attribute to CDISC; do not commit XPTs):
#   https://github.com/cdisc-org/sdtm-adam-pilot-project

suppressPackageStartupMessages({
  library(shiny)
  library(teal)
  library(teal.data)
  library(teal.transform)
  library(tm.ttni)
})

pick_object <- function(...) {
  object_names <- c(...)
  for (nm in object_names) {
    if (exists(nm, envir = .GlobalEnv, inherits = FALSE)) {
      return(get(nm, envir = .GlobalEnv))
    }
  }
  NULL
}

find_data_raw_file <- function(filename) {
  candidates <- c(
    file.path("data-raw", filename),
    file.path("..", "data-raw", filename),
    file.path("..", "..", "data-raw", filename)
  )
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) {
    return(NULL)
  }
  normalizePath(existing[[1L]], winslash = "/", mustWork = TRUE)
}

load_cdisc_pilot_xpt <- function() {
  if (!requireNamespace("haven", quietly = TRUE)) {
    return(NULL)
  }

  adsl_path <- find_data_raw_file("adsl.xpt")
  adtte_path <- find_data_raw_file("adtte.xpt")
  if (is.null(adsl_path)) {
    return(NULL)
  }

  message(
    "Loading CDISC Pilot ADaM XPTs from data-raw/ ",
    "(source: cdisc-org/sdtm-adam-pilot-project; attribute to CDISC)."
  )
  adsl <- standardize_adsl(haven::read_xpt(adsl_path))
  adtte <- if (!is.null(adtte_path)) {
    # CDISC Pilot ADTTE has no AVALU; AVAL is in days (study ~26 weeks).
    standardize_adtte(haven::read_xpt(adtte_path), adsl, default_avalu = "DAYS")
  } else {
    derive_mock_adtte(adsl)
  }
  list(ADSL = adsl, ADTTE = adtte, source = "cdisc-pilot")
}

load_random_cdisc_data <- function() {
  if (!requireNamespace("random.cdisc.data", quietly = TRUE)) {
    return(NULL)
  }

  env <- new.env(parent = emptyenv())
  try(utils::data("radsl", package = "random.cdisc.data", envir = env), silent = TRUE)
  try(utils::data("radtte", package = "random.cdisc.data", envir = env), silent = TRUE)

  if (!exists("radsl", envir = env, inherits = FALSE)) {
    return(NULL)
  }

  adsl <- standardize_adsl(get("radsl", envir = env))
  adtte <- if (exists("radtte", envir = env, inherits = FALSE)) {
    standardize_adtte(get("radtte", envir = env), adsl)
  } else {
    derive_mock_adtte(adsl)
  }
  list(ADSL = adsl, ADTTE = adtte, source = "random.cdisc.data")
}

group_vars_from_adsl <- function(adsl) {
  candidate_group_vars <- c(
    "Actual Treatment" = "TRT01A",
    "Country" = "COUNTRY",
    "Race" = "RACE",
    "Sex" = "SEX"
  )
  keep <- candidate_group_vars[candidate_group_vars %in% names(adsl)]
  if (length(keep) == 0L) {
    keep <- c("Actual Treatment" = "TRT01A")
  }
  keep
}

param_choices <- function(adtte, selected = NULL, dataname = "ADTTE") {
  choices <- teal.transform::value_choices(
    data = dataname,
    var_choices = "PARAMCD",
    var_label = "PARAM"
  )
  if (is.null(selected) || !selected %in% unique(as.character(adtte$PARAMCD))) {
    selected <- as.character(adtte$PARAMCD[[1L]])
  }
  teal.transform::choices_selected(choices = choices, selected = selected)
}

make_tte_module <- function(label,
                            adsl,
                            adtte,
                            adsl_name,
                            tte_name,
                            selected = NULL,
                            timepoints,
                            show_total = NULL) {
  tm_t_ttni(
    label = label,
    adsl_name = adsl_name,
    tte_name = tte_name,
    cat = teal.transform::choices_selected(
      choices = teal.transform::value_choices(
        data = tte_name,
        var_choices = "PARAMCD",
        var_label = "PARAM"
      ),
      selected = selected %||% as.character(adtte$PARAMCD[[1L]])
    ),
    group_vars = group_vars_from_adsl(adsl),
    timepoints = timepoints,
    show_total = show_total
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

real_adsl <- pick_object("ADSL", "adsl")
real_adtte <- pick_object("ADTTE", "adtte", "ADAETTE", "adaette")
data_source <- "global-env"

if (!is.null(real_adsl) && !is.null(real_adtte)) {
  ADSL_OPEN <- standardize_adsl(real_adsl)
  ADTTE_OPEN <- standardize_adtte(real_adtte, ADSL_OPEN)
} else {
  fallback <- load_cdisc_pilot_xpt()
  if (is.null(fallback)) {
    fallback <- load_random_cdisc_data()
  }
  if (is.null(fallback)) {
    ADSL_OPEN <- NULL
    ADTTE_OPEN <- NULL
    data_source <- "synthetic"
  } else {
    ADSL_OPEN <- fallback$ADSL
    ADTTE_OPEN <- fallback$ADTTE
    data_source <- if (!is.null(fallback$source)) fallback$source else "external"
  }
}

two <- make_synthetic_ttni_data(design = "two_arm", n_per_arm = 40L, seed = 20260823L)
two$ADSL$STUDYID <- "TWOARM"
two$ADTTE$STUDYID <- "TWOARM"

data_args <- list(
  ADSL = two$ADSL,
  ADTTE = two$ADTTE
)
modules_list <- list(
  make_tte_module(
    label = "Two-arm synthetic (HR on)",
    adsl = two$ADSL,
    adtte = two$ADTTE,
    adsl_name = "ADSL",
    tte_name = "ADTTE",
    selected = "TTNI",
    timepoints = c(3, 6, 12, 18, 24)
  )
)

if (!is.null(ADSL_OPEN) && !is.null(ADTTE_OPEN)) {
  data_args$ADSL_OPEN <- ADSL_OPEN
  data_args$ADTTE_OPEN <- ADTTE_OPEN
  open_param <- if ("TTDE" %in% unique(as.character(ADTTE_OPEN$PARAMCD))) {
    "TTDE"
  } else {
    as.character(ADTTE_OPEN$PARAMCD[[1L]])
  }
  hr_off_label <- if (identical(data_source, "cdisc-pilot")) {
    "CDISC Pilot three-arm (HR off)"
  } else {
    sprintf("Open TTE data (%s, HR off)", open_param)
  }
  modules_list <- c(
    list(
      make_tte_module(
        label = hr_off_label,
        adsl = ADSL_OPEN,
        adtte = ADTTE_OPEN,
        adsl_name = "ADSL_OPEN",
        tte_name = "ADTTE_OPEN",
        selected = open_param,
        timepoints = c(3, 6, 12),
        show_total = TRUE
      )
    ),
    modules_list
  )
} else {
  # Offline fallback only: generic Arm A/B/C.
  three <- make_synthetic_ttni_data(design = "multi_arm", n_per_arm = 24L, seed = 20260823L)
  data_args$ADSL_THREE <- three$ADSL
  data_args$ADTTE_THREE <- three$ADTTE
  modules_list <- c(
    list(
      make_tte_module(
        label = "Three-arm synthetic (HR off)",
        adsl = three$ADSL,
        adtte = three$ADTTE,
        adsl_name = "ADSL_THREE",
        tte_name = "ADTTE_THREE",
        selected = "TTNI",
        timepoints = c(3, 6, 12),
        show_total = TRUE
      )
    ),
    modules_list
  )
}

message(sprintf("Demo data source (HR-off lane): %s", data_source))

data_args$code <- c(
  "# ADSL / ADTTE prepared for tm_t_ttni()",
  "# Three-arm HR-off example: cdisc-org/sdtm-adam-pilot-project (attribute to CDISC)"
)

app_data <- do.call(teal.data::teal_data, data_args)

app <- teal::init(
  data = app_data,
  modules = do.call(teal::modules, modules_list)
)

shinyApp(ui = app$ui, server = app$server)
