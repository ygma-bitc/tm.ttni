# Package index

## Data Preparation

- [`prep_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/prep_ttni_data.md)
  : Prepare ADSL / ADTTE records for a TTE table
- [`standardize_adsl()`](https://ygma-bitc.github.io/tm.ttni/reference/standardize_adsl.md)
  : Standardize an ADSL-like data frame for TTE tables
- [`standardize_adtte()`](https://ygma-bitc.github.io/tm.ttni/reference/standardize_adtte.md)
  : Standardize an ADTTE-like data frame
- [`derive_mock_adtte()`](https://ygma-bitc.github.io/tm.ttni/reference/derive_mock_adtte.md)
  : Derive a simple OS-style ADTTE from ADSL death / last-alive dates

## Tables

- [`build_ttni_table()`](https://ygma-bitc.github.io/tm.ttni/reference/build_ttni_table.md)
  : Build a TTE / TTNI summary table
- [`detect_arm_design()`](https://ygma-bitc.github.io/tm.ttni/reference/detect_arm_design.md)
  : Detect whether a TTE table should use two-arm inferential statistics
- [`ttni_surv_time_choices()`](https://ygma-bitc.github.io/tm.ttni/reference/ttni_surv_time_choices.md)
  : Time-to-event statistics offered in the module
- [`default_ttni_surv_stats()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_surv_stats.md)
  : Default time-to-event statistics shown in the module
- [`default_ttni_event_levels()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_event_levels.md)
  : Default TTE event-reason labels
- [`default_ttni_censor_levels()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_censor_levels.md)
  : Default TTE censor-reason labels
- [`default_ttni_footnotes()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_footnotes.md)
  : Default TTE footnotes

## Teal Modules

- [`tm_t_ttni()`](https://ygma-bitc.github.io/tm.ttni/reference/tm_t_ttni.md)
  : teal Module: Time to Next Intervention and related TTE tables

## Synthetic Data

- [`make_synthetic_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/make_synthetic_ttni_data.md)
  : Build synthetic ADSL / ADTTE fixtures for TTE demos and tests
