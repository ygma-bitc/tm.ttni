# tm.ttni

[![R-CMD-check](https://github.com/ygma-bitc/tm.ttni/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ygma-bitc/tm.ttni/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/ygma-bitc/tm.ttni/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/ygma-bitc/tm.ttni/actions/workflows/pkgdown.yaml)

Teal module and reusable table builder for **Time to Next Intervention
(TTNI)** and related time-to-event endpoints.

TTNI is a time-to-event efficacy endpoint (time to next anticancer
intervention), distinct from safety incidence endpoints (such as
TEAE/OSEI).

## Design rule

| Detected arms | KM counts / quartiles / landmarks | HR, 95% CI, log-rank p |
|---------------|-----------------------------------|------------------------|
| 1 arm         | Yes                               | No                     |
| 2 arms        | Yes                               | Yes, vs `ref_arm`      |
| 3+ arms       | Yes, Total column by default      | No                     |

Forcing `compute_hr = TRUE` on a multi-arm data set is ignored with a
warning.

## Install and run

``` r

# from the package root
pkgload::load_all()
shiny::runApp("app.R")
```

Or call the builder without Shiny:

``` r

library(tm.ttni)

two <- make_synthetic_ttni_data("two_arm")
build_ttni_table(two$ADSL, two$ADTTE, ref_arm = "Placebo")

multi <- make_synthetic_ttni_data("multi_arm")
build_ttni_table(multi$ADSL, multi$ADTTE)  # no HR
```

## What is calculated

Always:

- Event n (%) and event-reason breakdown
- Censored n (%) and censor-reason breakdown
- Median, Q1/Q3, 25th / 75th percentiles with 95% CI, Min/Max
- Reverse KM follow-up time
- Landmark KM rates (detailed or rate-only)
- Selectable time-to-event rows
  ([`ttni_surv_time_choices()`](https://ygma-bitc.github.io/tm.ttni/reference/ttni_surv_time_choices.md)):
  descriptive `Mean (SD)` of `AVAL`, plus
  [`tern::surv_time()`](https://pharmaverse.github.io/tern/latest-tag/reference/survival_time.html)
  statistics. Median and 95% CI are one row (`median_ci_3d`); quartiles
  and range print as `Q1, Q3` and `Min, Max`.

The interactive table does **not** print method footnotes by default.
Callers may still pass `footnotes = default_ttni_footnotes()` to
[`build_ttni_table()`](https://ygma-bitc.github.io/tm.ttni/reference/build_ttni_table.md)
when a TFL-style footer is required.

| Topic | Definition |
|:---|:---|
| **Mean (SD)** | Descriptive mean and standard deviation of `AVAL` in the analysis set (includes censored times). This is not a Kaplan-Meier mean. |
| **Kaplan-Meier** | Product-limit estimates. Median and 95% CI use tern `median_ci_3d` on one row. Confidence intervals use the log-log method unless `conf_type` is changed. Non-estimable values are shown as `NE`. |
| **Follow-up time** | Reverse Kaplan-Meier estimates. |
| **Landmark rates** | Kaplan-Meier event-free percentages at the selected months. |
| **Time unit** | `AVAL` stored in days is converted to months (`/ 30.4375`) when `AVALU` is `DAYS`. |
| **Hazard ratio / 95% CI** | Unstratified Cox model (Efron ties); two-arm designs only. |
| **p-value** | Unstratified log-rank test; two-arm designs only. |
| **Min, Max `{1}` / `{2}`** | Observed range of `AVAL`. tern annotations mark a bound that is a censored observation. |

Two-arm only:

- Hazard ratio
- Wald 95% CI
- Log-rank p-value

Not implemented (group-sequential / SAP-specific):

- Repeated confidence intervals

## Data dependencies

| Dataset | Required | Recommended |
|:---|:---|:---|
| **ADSL** | `USUBJID`, arm/group (e.g. `TRT01A`) | `SAFFL`, `ITTFL`, `SEX`, `RACE`, `COUNTRY` |
| **ADTTE** | `USUBJID`, `PARAMCD`, `AVAL`, `CNSR` | `PARAM`, `AVALU`, `EVNTDESC` |

`AVAL` stored in days is converted to months (`/ 30.4375`) when `AVALU`
is `DAYS`. CDISC Pilot `ADTTE` has no `AVALU`; the demo loader treats
those values as days.

## Module architecture

``` text
Layer 1  Arm design     detect_arm_design()
Layer 2  Data adapters  standardize_adsl() / standardize_adtte()
Layer 3  Data prep      prep_ttni_data()   # empty result is not an error
Layer 4  Table builder  build_ttni_table(prepped = ...)
Layer 5  UI / Server    data_extract PARAMCD, shinyvalidate, Show R Code
Layer 6  Entry point    tm_t_ttni() → teal::module()
```

The server returns `table`, `prepped_data`, `no_data`, and
`source_code`.

## Demo data

The example app resolves data in this order:

1.  Existing global `ADSL` / `ADTTE`
2.  Local CDISC Pilot XPTs in `data-raw/` (`adsl.xpt`, `adtte.xpt`)
3.  `random.cdisc.data` (`radsl` / `radtte`) when available
4.  Synthetic fixtures from
    [`make_synthetic_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/make_synthetic_ttni_data.md)

Download the public CDISC Pilot files (do **not** commit them):

``` r

source("data-raw/process_data.R")
```

The demo’s **HR-off** example is the public CDISC Pilot three-arm study
(`PARAMCD = TTDE`; Placebo / Xanomeline High Dose / Xanomeline Low
Dose). Study-specific dose-level labels are not hardcoded; generic arms
are used. The module shows KM summaries without HR on that three-arm
table.

These files are **CDISC clinical test data**. Attribute them to
[cdisc-org/sdtm-adam-pilot-project](https://github.com/cdisc-org/sdtm-adam-pilot-project)
and do not redistribute them for a fee.

## Standalone Usage

[`build_ttni_table()`](https://ygma-bitc.github.io/tm.ttni/reference/build_ttni_table.md)
is the reusable engine. It can be called directly in standalone scripts,
reporting pipelines, or other Shiny applications without requiring the
full teal framework.
