#' Build synthetic ADSL / ADTTE fixtures for TTE demos and tests
#'
#' Returns a subject-level ADSL and a BDS-style ADTTE with two parameters:
#' `TTNI` (time to next intervention) and `OS` (overall survival). The two
#' data frames are distinct objects.
#'
#' @param design `character(1)` Either `"two_arm"` (randomized comparison) or
#'   `"multi_arm"` (three generic arms; no study-specific dose labels).
#' @param n_per_arm `integer(1)` Subjects per arm.
#' @param seed `integer(1)` Random seed.
#'
#' @return A list with `ADSL` and `ADTTE`.
#'
#' @examples
#' data <- make_synthetic_ttni_data(design = "two_arm", seed = 1L)
#' names(data)
#' unique(data$ADTTE$PARAMCD)
#'
#' @export
make_synthetic_ttni_data <- function(design = c("two_arm", "multi_arm"),
                                     n_per_arm = 40L,
                                     seed = 20260823L) {
  design <- match.arg(design)
  checkmate::assert_integerish(n_per_arm, len = 1L, lower = 5L)
  checkmate::assert_integerish(seed, len = 1L)

  if (identical(design, "two_arm")) {
    arms <- c("Placebo", "Investigational")
    ttni_rates <- c(Placebo = 0.055, Investigational = 0.020)
    os_rates <- c(Placebo = 0.018, Investigational = 0.010)
  } else {
    arms <- c("Arm A", "Arm B", "Arm C")
    ttni_rates <- c(
      "Arm A" = 0.045,
      "Arm B" = 0.035,
      "Arm C" = 0.025
    )
    os_rates <- ttni_rates * 0.35
  }

  n_per_arm <- as.integer(n_per_arm)
  set.seed(as.integer(seed))

  sex_levels <- c("F", "M")
  race_levels <- c("Asian", "White", "Black or African American")
  country_levels <- c("CHN", "USA", "AUS")

  adsl_rows <- lapply(seq_along(arms), function(i) {
    arm <- arms[[i]]
    n <- n_per_arm
    start <- as.Date("2024-01-01") + sample.int(30, n, replace = TRUE)
    data.frame(
      STUDYID = "MOCK-TTNI",
      USUBJID = sprintf("MOCK-TTNI-%s-%03d", gsub("[^A-Za-z0-9]+", "", arm), seq_len(n)),
      TRT01A = arm,
      TRT01AN = i,
      SAFFL = "Y",
      ITTFL = "Y",
      APHASE = "PART1",
      SEX = sample(sex_levels, n, replace = TRUE),
      RACE = sample(race_levels, n, replace = TRUE),
      COUNTRY = sample(country_levels, n, replace = TRUE),
      AGE = sample(40:75, n, replace = TRUE),
      TRTSDT = start,
      stringsAsFactors = FALSE
    )
  })

  adsl <- do.call(rbind, adsl_rows)
  rownames(adsl) <- NULL
  adsl$TRT01A <- factor(adsl$TRT01A, levels = arms)

  make_param <- function(paramcd, param, paramn, rates, event_prob, event_desc_fn) {
    rows <- lapply(seq_along(arms), function(i) {
      arm <- arms[[i]]
      idx <- which(as.character(adsl$TRT01A) == arm)
      n <- length(idx)
      time_months <- stats::rexp(n, rate = rates[[arm]])
      time_months <- pmin(pmax(time_months, 0.2), 36)
      is_event <- stats::rbinom(n, 1L, event_prob) == 1L
      desc <- event_desc_fn(is_event, n)
      data.frame(
        STUDYID = adsl$STUDYID[idx],
        USUBJID = adsl$USUBJID[idx],
        PARAM = param,
        PARAMCD = paramcd,
        PARAMN = paramn,
        AVAL = round(time_months, 3),
        AVALU = "MONTHS",
        CNSR = as.integer(!is_event),
        EVNTDESC = desc,
        STARTDT = adsl$TRTSDT[idx],
        ADT = adsl$TRTSDT[idx] + pmax(round(time_months * 30.4375) - 1L, 0L),
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, rows)
  }

  ttni_desc <- function(is_event, n) {
    ifelse(
      is_event,
      ifelse(stats::runif(n) < 0.15, "Death", "The initiation of subsequent anticancer therapy"),
      ifelse(stats::runif(n) < 0.08, "Withdrawal of consent", "Last known alive date")
    )
  }

  os_desc <- function(is_event, n) {
    ifelse(is_event, "Death", "Last known alive date")
  }

  event_prob_ttni <- if (identical(design, "two_arm")) 0.32 else 0.28
  adtte <- rbind(
    make_param("TTNI", "Time to Next Intervention (TTNI)", 1L, ttni_rates, event_prob_ttni, ttni_desc),
    make_param("OS", "Overall Survival", 2L, os_rates, 0.18, os_desc)
  )
  rownames(adtte) <- NULL

  list(ADSL = adsl, ADTTE = adtte)
}
