# two-arm TTNI snapshot remains stable

    Code
      print(tbl)
    Output
      Summary of Time to Next Intervention (TTNI)
      Parameter: TTNI
      Design: two-arm; HR vs Placebo
      
      ——————————————————————————————————————————————————————————————————————————————————————
                                                              Placebo        Investigational
                                                               (N=20)            (N=20)     
      ——————————————————————————————————————————————————————————————————————————————————————
      Number of participants with event, n (%)                4 (20.0)          5 (25.0)    
        The initiation of subsequent anticancer therapy       3 (15.0)          4 (20.0)    
        Death                                                 1 (5.0)            1 (5.0)    
      Number of participants censored, n (%)                 16 (80.0)          15 (75.0)   
        Last known alive date                                15 (75.0)          14 (70.0)   
        Withdrawal of consent                                 1 (5.0)            1 (5.0)    
      TTNI (months)                                                                         
        Mean (SD)                                          21.31 (11.79)      23.47 (12.51) 
        Median (95% CI)                                   36.0 (23.8 - NE)   NE (21.0 - NE) 
        Q1, Q3                                                36.0, NE          25.8, NE    
        25%-ile (95% CI)                                  36.0 (17.2 - NE)   25.8 (3.0 - NE)
        75%-ile (95% CI)                                   NE (36.0 - NE)          NE       
        Min, Max                                          1.7 to 36.0 {1}    3.0 to 36.0 {2}
      Comparison vs Placebo                                                                 
        Hazard Ratio                                                              1.01      
        95% CI                                                                (0.27, 3.80)  
        p-value (log-rank)                                                       0.9601     
      6 Months                                                                              
        Patients remaining at risk                               17                18       
        Kaplan-Meier survival rate (%)                         100.00             95.00     
        95% CI                                            (100.00, 100.00)   (69.47, 99.28) 
      ——————————————————————————————————————————————————————————————————————————————————————
      
      {1} - Censored observations: range minimum & maximum
      {2} - Censored observation: range maximum
      ——————————————————————————————————————————————————————————————————————————————————————
      

# multi-arm TTNI snapshot remains stable

    Code
      print(tbl)
    Output
      Summary of Time to Next Intervention (TTNI)
      Parameter: TTNI
      Design: multi_arm; HR not calculated
      
      ———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
                                                               Arm A             Arm B             Arm C              Total      
                                                              (N=20)            (N=20)             (N=20)             (N=60)     
      ———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
      Number of participants with event, n (%)               3 (15.0)          6 (30.0)           2 (10.0)          11 (18.3)    
        The initiation of subsequent anticancer therapy       1 (5.0)          6 (30.0)           2 (10.0)           9 (15.0)    
        Death                                                2 (10.0)           0 (0.0)           0 (0.0)            2 (3.3)     
      Number of participants censored, n (%)                 17 (85.0)         14 (70.0)         18 (90.0)          49 (81.7)    
        Last known alive date                                16 (80.0)         10 (50.0)         18 (90.0)          44 (73.3)    
        Withdrawal of consent                                 1 (5.0)          4 (20.0)           0 (0.0)            5 (8.3)     
      TTNI (months)                                                                                                              
        Mean (SD)                                          21.26 (13.79)     26.31 (12.10)     24.81 (13.56)      24.13 (13.12)  
        Median (95% CI)                                   NE (27.9 - NE)    NE (36.0 - NE)     NE (36.0 - NE)           NE       
        Q1, Q3                                                  NE             36.0, NE              NE              36.0, NE    
        25%-ile (95% CI)                                   NE (1.7 - NE)    36.0 (3.0 - NE)    NE (22.1 - NE)    36.0 (27.9 - NE)
        75%-ile (95% CI)                                        NE                NE                 NE                 NE       
        Min, Max                                          0.6 to 36.0 {1}   1.1 to 36.0 {1}   1.2 to 36.0 {1}    0.6 to 36.0 {1} 
      6 Months                                                                                                                   
        Patients remaining at risk                              16                18                 16                 50       
        Kaplan-Meier survival rate (%)                         94.44             94.74             100.00             96.36      
        95% CI                                            (66.64, 99.20)    (68.12, 99.24)    (100.00, 100.00)    (86.22, 99.08) 
      ———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
      
      {1} - Censored observations: range minimum & maximum
      ———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
      

