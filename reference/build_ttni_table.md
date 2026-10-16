# Build a TTE / TTNI summary table

Uses `tern` Kaplan-Meier layout functions for both multi-arm
(dose-level) and two-arm designs. Hazard ratio, 95% CI, and log-rank
p-value are added only when exactly two arms are present.

## Usage

``` r
build_ttni_table(
  adsl = NULL,
  adtte = NULL,
  arm_var = "TRT01A",
  ref_arm = NULL,
  paramcd = "TTNI",
  timepoints = c(3, 6, 12, 18, 24),
  show_total = NULL,
  include_followup = TRUE,
  surv_stats = NULL,
  landmark_style = c("detailed", "rate_only"),
  conf_type = c("log-log", "log", "plain"),
  conf_level = 0.95,
  compute_hr = NULL,
  title = NULL,
  footnotes = NULL,
  prepped = NULL,
  ...
)
```

## Arguments

- adsl:

  ADSL or combined TTE data. Ignored when `prepped` is supplied.

- adtte:

  Optional ADTTE data frame.

- arm_var:

  Treatment / grouping variable.

- ref_arm:

  Reference arm used for two-arm HR calculations.

- paramcd:

  Analysis parameter code.

- timepoints:

  Landmark months.

- show_total:

  Whether to add a Total column. Defaults to `TRUE` for multi-arm
  designs and `FALSE` for two-arm designs.

- include_followup:

  Whether to include reverse KM follow-up time.

- surv_stats:

  Time-to-event statistics from
  [`ttni_surv_time_choices()`](https://ygma-bitc.github.io/tm.ttni/reference/ttni_surv_time_choices.md).
  `NULL` uses
  [`default_ttni_surv_stats()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_surv_stats.md).
  `mean_sd` is a descriptive Mean (SD) of `AVAL`; the rest are
  [`tern::surv_time()`](https://pharmaverse.github.io/tern/latest-tag/reference/survival_time.html)
  statistics. Legacy `median` / `median_ci` requests are folded into one
  `median_ci_3d` row. The same selection is used for follow-up time when
  `include_followup` is `TRUE`.

- landmark_style:

  `"detailed"` includes patients remaining at risk; `"rate_only"` shows
  rate (95% CI) only.

- conf_type:

  KM CI type passed to
  [`tern::control_surv_time()`](https://pharmaverse.github.io/tern/latest-tag/reference/control_surv_time.html).

- conf_level:

  Confidence level.

- compute_hr:

  `NULL` to auto-detect (two-arm only), or a flag. A request of `TRUE`
  on a multi-arm data set is ignored with a warning.

- title:

  Table title. `NULL` derives a title from `paramcd`.

- footnotes:

  Optional method footnotes. `NULL` (default) omits them so the
  interactive table stays compact; definitions live in the README. Pass
  [`default_ttni_footnotes()`](https://ygma-bitc.github.io/tm.ttni/reference/default_ttni_footnotes.md)
  when a TFL-style footer is required.

- prepped:

  Optional list from
  [`prep_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/prep_ttni_data.md).
  When supplied, raw `adsl` / `adtte` are not re-prepared.

- ...:

  Passed to
  [`prep_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/prep_ttni_data.md)
  when `prepped` is `NULL`.

## Value

An `rtables` `VTableTree`.

## Details

Pass either raw `adsl` / `adtte` or a list returned by
[`prep_ttni_data()`](https://ygma-bitc.github.io/tm.ttni/reference/prep_ttni_data.md)
via `prepped` so the teal server can prepare data once.

## Examples

``` r
two_arm <- make_synthetic_ttni_data("two_arm", seed = 1L)
build_ttni_table(two_arm$ADSL, two_arm$ADTTE, ref_arm = "Placebo")
#> Summary of Time to Next Intervention (TTNI)
#> Parameter: TTNI
#> Design: two-arm; HR vs Placebo
#> 
#> ———————————————————————————————————————————————————————————————————————————————————————————
#>                                                          Placebo          Investigational  
#>                                                           (N=40)               (N=40)      
#> ———————————————————————————————————————————————————————————————————————————————————————————
#> Number of participants with event, n (%)                15 (37.5)            15 (37.5)     
#>   The initiation of subsequent anticancer therapy       14 (35.0)            14 (35.0)     
#>   Death                                                  1 (2.5)              1 (2.5)      
#> Number of participants censored, n (%)                  25 (62.5)            25 (62.5)     
#>   Last known alive date                                 24 (60.0)            19 (47.5)     
#>   Withdrawal of consent                                  1 (2.5)              6 (15.0)     
#> TTNI (months)                                                                              
#>   Mean (SD)                                           15.65 (12.01)        27.35 (11.02)   
#>   Median (95% CI)                                   35.7 (18.8 - 36.0)    36.0 (36.0 - NE) 
#>   Q1, Q3                                                18.8, 36.0            36.0, NE     
#>   25%-ile (95% CI)                                  18.8 (5.6 - 26.3)    36.0 (21.5 - 36.0)
#>   75%-ile (95% CI)                                   36.0 (35.7 - NE)            NE        
#>   Min, Max                                           0.2 to 36.0 {1}      4.2 to 36.0 {1}  
#> TTNI Follow-up Time (months)                                                               
#>   Mean (SD)                                           15.65 (12.01)        27.35 (11.02)   
#>   Median (95% CI)                                   19.3 (9.6 - 34.3)    36.0 (36.0 - 36.0)
#>   Q1, Q3                                                7.6, 36.0             21.2, NE     
#>   25%-ile (95% CI)                                   7.6 (4.1 - 12.0)    21.2 (10.4 - 36.0)
#>   75%-ile (95% CI)                                   36.0 (22.6 - NE)      NE (36.0 - NE)  
#>   Min, Max                                           0.2 to 36.0 {2}      4.2 to 36.0 {2}  
#> Comparison vs Placebo                                                                      
#>   Hazard Ratio                                                                  0.36       
#>   95% CI                                                                    (0.17, 0.76)   
#>   p-value (log-rank)                                                           0.0045      
#> 3 Months                                                                                   
#>   Patients remaining at risk                                36                   40        
#>   Kaplan-Meier survival rate (%)                          100.00               100.00      
#>   95% CI                                             (100.00, 100.00)     (100.00, 100.00) 
#> 6 Months                                                                                   
#>   Patients remaining at risk                                28                   38        
#>   Kaplan-Meier survival rate (%)                          90.94                100.00      
#>   95% CI                                              (74.38, 97.00)      (100.00, 100.00) 
#> 12 Months                                                                                  
#>   Patients remaining at risk                                19                   33        
#>   Kaplan-Meier survival rate (%)                          80.10                100.00      
#>   95% CI                                              (60.56, 90.65)      (100.00, 100.00) 
#> 18 Months                                                                                  
#>   Patients remaining at risk                                16                   29        
#>   Kaplan-Meier survival rate (%)                          75.39                93.65       
#>   95% CI                                              (54.45, 87.70)       (76.90, 98.37)  
#> 24 Months                                                                                  
#>   Patients remaining at risk                                10                   26        
#>   Kaplan-Meier survival rate (%)                          59.97                86.96       
#>   95% CI                                              (36.95, 76.90)       (68.85, 94.90)  
#> ———————————————————————————————————————————————————————————————————————————————————————————
#> 
#> {1} - Censored observations: range minimum & maximum
#> {2} - Censored observation: range maximum
#> ———————————————————————————————————————————————————————————————————————————————————————————
#> 

multi <- make_synthetic_ttni_data("multi_arm", seed = 1L)
build_ttni_table(multi$ADSL, multi$ADTTE, show_total = TRUE)
#> Summary of Time to Next Intervention (TTNI)
#> Parameter: TTNI
#> Design: multi_arm; HR not calculated
#> 
#> —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#>                                                           Arm A                Arm B                Arm C                Total       
#>                                                           (N=40)               (N=40)               (N=40)              (N=120)      
#> —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#> Number of participants with event, n (%)                14 (35.0)            10 (25.0)            12 (30.0)            36 (30.0)     
#>   The initiation of subsequent anticancer therapy        8 (20.0)             9 (22.5)            11 (27.5)            28 (23.3)     
#>   Death                                                  6 (15.0)             1 (2.5)              1 (2.5)              8 (6.7)      
#> Number of participants censored, n (%)                  26 (65.0)            30 (75.0)            28 (70.0)            84 (70.0)     
#>   Last known alive date                                 25 (62.5)            29 (72.5)            24 (60.0)            78 (65.0)     
#>   Withdrawal of consent                                  1 (2.5)              1 (2.5)              4 (10.0)             6 (5.0)      
#> TTNI (months)                                                                                                                        
#>   Mean (SD)                                           14.21 (10.52)        18.19 (12.95)        26.83 (10.53)        19.74 (12.47)   
#>   Median (95% CI)                                   28.8 (16.1 - 36.0)    36.0 (30.5 - NE)      NE (36.0 - NE)      36.0 (36.0 - NE) 
#>   Q1, Q3                                                16.0, 36.0            30.5, NE             36.0, NE             24.8, NE     
#>   25%-ile (95% CI)                                  16.0 (5.4 - 28.8)    30.5 (10.6 - 36.0)   36.0 (19.3 - 36.0)   24.8 (18.0 - 36.0)
#>   75%-ile (95% CI)                                   36.0 (28.8 - NE)      NE (36.0 - NE)             NE                   NE        
#>   Min, Max                                           0.5 to 36.0 {1}      0.3 to 36.0 {1}      5.3 to 36.0 {1}      0.3 to 36.0 {1}  
#> TTNI Follow-up Time (months)                                                                                                         
#>   Mean (SD)                                           14.21 (10.52)        18.19 (12.95)        26.83 (10.53)        19.74 (12.47)   
#>   Median (95% CI)                                   19.2 (10.3 - 24.6)   21.6 (11.2 - 35.0)   36.0 (27.0 - 36.0)   24.1 (20.4 - 31.4)
#>   Q1, Q3                                                9.4, 25.8            7.8, 36.0            21.0, 36.0           10.7, 36.0    
#>   25%-ile (95% CI)                                   9.4 (3.7 - 10.9)     7.8 (2.5 - 15.8)    21.0 (10.5 - 31.4)   10.7 (7.8 - 15.8) 
#>   75%-ile (95% CI)                                   25.8 (24.1 - NE)    36.0 (23.5 - 36.0)    36.0 (36.0 - NE)    36.0 (36.0 - 36.0)
#>   Min, Max                                           0.5 to 36.0 {2}      0.3 to 36.0 {2}      5.3 to 36.0 {2}      0.3 to 36.0 {2}  
#> 3 Months                                                                                                                             
#>   Patients remaining at risk                                34                   33                   40                  107        
#>   Kaplan-Meier survival rate (%)                          94.44                97.30                100.00               97.33       
#>   95% CI                                              (79.57, 98.58)       (82.32, 99.61)      (100.00, 100.00)      (91.95, 99.13)  
#> 6 Months                                                                                                                             
#>   Patients remaining at risk                                29                   30                   38                   97        
#>   Kaplan-Meier survival rate (%)                          85.84                94.26                100.00               93.59       
#>   95% CI                                              (69.24, 93.86)       (78.87, 98.54)      (100.00, 100.00)      (87.02, 96.89)  
#> 12 Months                                                                                                                            
#>   Patients remaining at risk                                18                   23                   34                   75        
#>   Kaplan-Meier survival rate (%)                          78.95                90.77                100.00               90.37       
#>   95% CI                                              (60.61, 89.45)       (73.83, 96.95)      (100.00, 100.00)      (82.79, 94.72)  
#> 18 Months                                                                                                                            
#>   Patients remaining at risk                                13                   20                   32                   65        
#>   Kaplan-Meier survival rate (%)                          64.69                86.82                96.97                84.06       
#>   95% CI                                              (43.04, 79.85)       (68.20, 94.91)       (80.37, 99.57)       (74.76, 90.15)  
#> 24 Months                                                                                                                            
#>   Patients remaining at risk                                11                   12                   24                   47        
#>   Kaplan-Meier survival rate (%)                          64.69                78.14                87.56                77.39       
#>   95% CI                                              (43.04, 79.85)       (57.04, 89.73)       (70.15, 95.15)       (66.91, 84.92)  
#> —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#> 
#> {1} - Censored observations: range minimum & maximum
#> {2} - Censored observation: range maximum
#> —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#> 
```
