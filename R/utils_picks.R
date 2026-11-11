#' Drop the teal.picks warning about an eager `selected` and delayed `choices`.
#'
#' The default PARAMCD pick stores `paramcd` as `selected` and lets `values()`
#' resolve the remaining levels from the column at runtime.
#'
#' @keywords internal
#' @noRd
muffle_pick_delayed <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (inherits(w, "pick_delayed")) {
        invokeRestart("muffleWarning")
      }
    }
  )
}


#' Default single-PARAMCD [`teal.picks::picks`] object.
#'
#' `datasets` is `tte_name`. `variables` is fixed to `PARAMCD`.
#' `values$selected` is `paramcd`, with `multiple = FALSE` on both steps.
#'
#' @keywords internal
#' @noRd
default_paramcd_picks <- function(tte_name, paramcd) {
  checkmate::assert_string(tte_name)
  checkmate::assert_string(paramcd)
  muffle_pick_delayed(
    teal.picks::picks(
      teal.picks::datasets(choices = tte_name, selected = tte_name),
      teal.picks::variables(
        choices = "PARAMCD",
        selected = "PARAMCD",
        multiple = FALSE,
        fixed = TRUE
      ),
      teal.picks::values(selected = paramcd, multiple = FALSE)
    )
  )
}


#' Keep a caller-supplied picks object on the single-value PARAMCD contract.
#'
#' @keywords internal
#' @noRd
ensure_paramcd_picks <- function(x, tte_name, paramcd) {
  variables <- x$variables
  values <- x$values
  if (is.null(variables)) {
    variables <- teal.picks::variables(
      choices = "PARAMCD",
      selected = "PARAMCD",
      multiple = FALSE,
      fixed = TRUE
    )
  }
  if (is.null(values)) {
    values <- muffle_pick_delayed(
      teal.picks::values(selected = paramcd, multiple = FALSE)
    )
  }
  if (!identical(attr(values, "multiple", exact = TRUE), FALSE)) {
    stop(
      "`multiple` metadata does not match the requirement for `cat`.",
      " Please set multiple = FALSE in the picks object.",
      call. = FALSE
    )
  }
  if (!is.null(x$datasets) && !is.null(x$values) && !is.null(x$variables)) {
    return(x)
  }
  datasets <- x$datasets
  if (is.null(datasets)) {
    datasets <- teal.picks::datasets(choices = tte_name, selected = tte_name)
  }
  teal.picks::picks(datasets, variables, values)
}


#' Convert a legacy `choices_selected` PARAMCD spec into picks.
#'
#' Only the pieces this module needs are kept: one dataset (`tte_name`),
#' one variable (the `var_choices` attribute, otherwise `PARAMCD`), and one
#' selected value. Delayed choices stay delayed so the levels still come
#' from the data column.
#'
#' @keywords internal
#' @noRd
choices_selected_to_paramcd_picks <- function(x, tte_name) {
  selected <- as.character(unlist(x$selected, use.names = FALSE))
  selected <- selected[!is.na(selected) & nzchar(selected)]
  if (length(selected) != 1L) {
    stop("`cat` must select exactly one PARAMCD.", call. = FALSE)
  }

  variable_name <- attr(x$choices, "var_choices", exact = TRUE)
  if (is.null(variable_name) || !length(variable_name)) {
    variable_name <- "PARAMCD"
  }
  variable_name <- as.character(variable_name[[1L]])
  fixed <- isTRUE(x$fixed)

  if (is.null(x$choices) || inherits(x$choices, "delayed_data")) {
    vals <- muffle_pick_delayed(
      teal.picks::values(selected = selected, multiple = FALSE, fixed = fixed)
    )
  } else {
    choices <- unique(as.character(x$choices))
    choices <- choices[!is.na(choices) & nzchar(choices)]
    if (!selected %in% choices) {
      choices <- c(selected, choices)
    }
    vals <- teal.picks::values(
      choices = choices,
      selected = selected,
      multiple = FALSE,
      fixed = fixed
    )
  }

  teal.picks::picks(
    teal.picks::datasets(choices = tte_name, selected = tte_name),
    teal.picks::variables(
      choices = variable_name,
      selected = variable_name,
      multiple = FALSE,
      fixed = TRUE
    ),
    vals
  )
}


#' One column on one dataset, single selection.
#'
#' A single choice is fixed by `teal.picks`. Several choices stay switchable.
#'
#' @keywords internal
#' @noRd
column_picks <- function(dataname, choices, selected) {
  checkmate::assert_string(dataname)
  choices <- unique(as.character(choices))
  choices <- choices[!is.na(choices) & nzchar(choices)]
  checkmate::assert_character(choices, min.len = 1L, any.missing = FALSE)
  selected <- as.character(selected[[1L]])
  checkmate::assert_string(selected, min.chars = 1L)
  if (!selected %in% choices) {
    choices <- c(selected, choices)
  }
  teal.picks::picks(
    teal.picks::datasets(choices = dataname, selected = dataname),
    teal.picks::variables(
      choices = choices,
      selected = selected,
      multiple = FALSE
    )
  )
}


#' Require a single-column [`teal.picks::picks`] object and attach `dataname` when needed.
#'
#' @keywords internal
#' @noRd
ensure_column_picks <- function(x, dataname, arg_name) {
  if (is.null(x$variables)) {
    stop(sprintf("`%s` must include a variables() step.", arg_name), call. = FALSE)
  }
  if (!identical(attr(x$variables, "multiple", exact = TRUE), FALSE)) {
    stop(
      sprintf("`multiple` metadata does not match the requirement for `%s`.", arg_name),
      " Please set multiple = FALSE in the picks object.",
      call. = FALSE
    )
  }
  if (!is.null(x$datasets)) {
    return(x)
  }
  if (is.null(x$values)) {
    teal.picks::picks(
      teal.picks::datasets(choices = dataname, selected = dataname),
      x$variables
    )
  } else {
    teal.picks::picks(
      teal.picks::datasets(choices = dataname, selected = dataname),
      x$variables,
      x$values
    )
  }
}


#' Coerce a column selector to [`teal.picks::picks`].
#'
#' `NULL` uses `choices` / `selected`. A character vector is deprecated and
#' read as column names (names of the vector are display labels and are dropped).
#'
#' @keywords internal
#' @noRd
migrate_column_selector_to_picks <- function(x, # nolint: object_length_linter.
                                             dataname,
                                             choices,
                                             selected,
                                             arg_name) {
  if (is.null(x)) {
    return(column_picks(dataname, choices, selected))
  }
  if (inherits(x, "picks")) {
    return(ensure_column_picks(x, dataname, arg_name))
  }
  if (is.character(x)) {
    lifecycle::deprecate_warn(
      when = "0.1.0",
      what = I(sprintf("`%s` = 'character vector'", arg_name)),
      with = I("`teal.picks::picks()`"),
      details = paste(
        "Pass `teal.picks::picks()` with `datasets()` and `variables()` (`multiple = FALSE`).",
        "Support for a character vector of column names is deprecated."
      )
    )
    cols <- as.character(x)
    cols <- cols[!is.na(cols) & nzchar(cols)]
    if (length(cols) < 1L) {
      stop(sprintf("`%s` must name at least one column.", arg_name), call. = FALSE)
    }
    return(column_picks(dataname, cols, cols[[1L]]))
  }
  stop(
    sprintf("`%s` must be a `teal.picks::picks()` object or a character vector of column names.", arg_name),
    call. = FALSE
  )
}


#' Build the population-flag column pick.
#'
#' `population_var` may be a picks object or a legacy column name.
#' `population_choices` supplies the legacy choice list.
#'
#' @keywords internal
#' @noRd
migrate_population_to_picks <- function(population_var, population_choices, adsl_name) {
  if (inherits(population_var, "picks")) {
    return(ensure_column_picks(population_var, adsl_name, "population_var"))
  }

  default_choices <- c("SAFFL", "ITTFL")
  if (is.null(population_var) && is.null(population_choices)) {
    return(column_picks(adsl_name, default_choices, "SAFFL"))
  }

  lifecycle::deprecate_warn(
    when = "0.1.0",
    what = I("`population_var` / `population_choices`"),
    with = I("`teal.picks::picks()`"),
    details = paste(
      "Pass `population_var` as `teal.picks::picks()` with `datasets()` and `variables()` (`multiple = FALSE`).",
      "Support for a column name plus `population_choices` is deprecated."
    )
  )

  if (is.character(population_choices)) {
    choices <- as.character(population_choices)
  } else if (is.null(population_choices)) {
    choices <- default_choices
  } else {
    stop("`population_choices` must be a character vector of flag columns.", call. = FALSE)
  }
  choices <- choices[!is.na(choices) & nzchar(choices)]
  if (length(choices) < 1L) {
    stop("`population_choices` must name at least one column.", call. = FALSE)
  }

  selected <- if (is.character(population_var) && length(population_var) == 1L && nzchar(population_var)) {
    population_var
  } else if (is.null(population_var) && "SAFFL" %in% choices) {
    "SAFFL"
  } else if (is.null(population_var)) {
    choices[[1L]]
  } else {
    stop("`population_var` must be a column name or a `teal.picks::picks()` object.", call. = FALSE)
  }
  column_picks(adsl_name, choices, selected)
}


#' Non-missing, non-empty `selected` entries on one teal.picks slot.
#'
#' @keywords internal
#' @noRd
slot_selected <- function(slot) {
  sel <- if (is.null(slot)) character(0) else as.character(slot$selected)
  sel[!is.na(sel) & nzchar(sel)]
}


#' Character column name stored on an unresolved column pick, or `default`.
#'
#' Only a length-1 character selection is returned. A factor, several values,
#' or a missing value stays `default`.
#'
#' @keywords internal
#' @noRd
column_fallback <- function(picks, default) {
  sel <- picks$variables$selected
  one_character <- is.character(sel) && length(sel) == 1L
  if (one_character && length(slot_selected(list(selected = sel))) == 1L) {
    sel
  } else {
    default
  }
}


#' Length-1 column name from a resolved column pick.
#'
#' `NA` and empty strings are dropped. Several remaining values return `fallback`.
#'
#' @keywords internal
#' @noRd
selected_pick_column <- function(resolved, fallback) {
  sel <- slot_selected(resolved$variables)
  if (length(sel) == 1L) sel else fallback
}


#' Badge text for one slot: comma-separated selection, or `"~"` when empty.
#'
#' @keywords internal
#' @noRd
pick_slot_text <- function(slot) {
  sel <- slot_selected(slot)
  if (length(sel)) paste(sel, collapse = ", ") else "~"
}


#' Visible badge text for one teal.picks selector.
#'
#' The upstream badge prints every slot, so the dataset name is prefixed
#' onto the column. There is no argument to drop that slot. The dataset
#' stays on the tooltip, in the same `datasets:` / `variables:` form.
#'
#' @keywords internal
#' @noRd
variable_badge_label <- function(pick) {
  variable <- pick_slot_text(pick$variables)
  dataset <- pick_slot_text(pick$datasets)
  shiny::tags$span(
    title = sprintf("datasets: %s\nvariables: %s", dataset, variable),
    variable
  )
}


#' Whether every step of a picks object is fixed.
#'
#' @keywords internal
#' @noRd
picks_are_fixed <- function(picks) {
  all(vapply(picks, teal.picks::is_pick_fixed, logical(1)))
}


#' Badge container that shows `variable_badge_label()` instead of the
#' upstream summary.
#'
#' @keywords internal
#' @noRd
picks_badge_container <- function(label_id, fixed) {
  force(label_id)
  force(fixed)
  badge_ui <- utils::getFromNamespace(
    if (isTRUE(fixed)) "badge_fixed" else "badge_dropdown",
    "teal.picks"
  )
  function(content, id, label) {
    # `label` is the upstream summary, which prefixes the dataset name.
    badge_ui(
      id = id,
      label = shiny::uiOutput(label_id, inline = TRUE),
      content = content
    )
  }
}


#' Encoding-panel picks control whose badge shows the column name only.
#'
#' @keywords internal
#' @noRd
pick_ui <- function(ns, input_id, picks) {
  teal.picks::picks_ui(
    ns(input_id),
    picks,
    container = picks_badge_container(
      ns(paste0(input_id, "_label")),
      picks_are_fixed(picks)
    )
  )
}


#' Coerce `cat` to one PARAMCD [`teal.picks::picks`] object.
#'
#' `NULL` builds the default. A `picks` object is checked for
#' `multiple = FALSE`. A legacy `choices_selected` is deprecated, then converted.
#'
#' @keywords internal
#' @noRd
migrate_cat_to_picks <- function(cat, tte_name, paramcd) {
  if (is.null(cat)) {
    return(default_paramcd_picks(tte_name, paramcd))
  }
  if (inherits(cat, "picks")) {
    return(ensure_paramcd_picks(cat, tte_name, paramcd))
  }
  if (inherits(cat, "choices_selected")) {
    lifecycle::deprecate_warn(
      when = "0.1.0",
      what = I("`cat` = `choices_selected`"),
      with = I("`teal.picks::picks()`"),
      details = paste(
        "Pass `teal.picks::picks()` with `datasets()`, `variables()`, and `values()`.",
        "Support for legacy `teal.transform::choices_selected()` is deprecated."
      )
    )
    return(choices_selected_to_paramcd_picks(cat, tte_name))
  }
  stop(
    "`cat` must be a `teal.picks::picks()` object or a legacy `choices_selected`.",
    call. = FALSE
  )
}
