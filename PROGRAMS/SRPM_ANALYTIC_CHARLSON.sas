*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_CHARLSON.SAS                                      *;
*   Purpose:  Pull Charlson comorbidity score and related indicators for year *;
*             prior to each index visit. Code adapted from VDW standard       *;
*             macro %Charlson to run at the person+date level.                *;
*******************************************************************************;
options nomprint;

%macro mod_charlson;
  %if %sysfunc(exist(temp.charlson)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "CHARLSON"
      ;
    quit;

    %put WARNING: Data set TEMP.CHARLSON already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.CHARLSON cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.dx_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.CHARLSON cannot be created!;
      %put ERROR: Required input data set TEMP.DX_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      proc format;
        value $icd9cf
        /* Myocardial infraction */
        '410   '-'410.92', '412   ' = 'mi'
        /* Congestive heart disease */
        '428   '-'428.9 ' = 'chd'
        /* Peripheral vascular disorder */
        '440.20'-'440.24', '440.31'-'440.32', '440.8 ', '440.9 ', '443.9 ',
        '441   '-'441.9 ', '785.4 ', 'V43.4 ', 'v43.4 ' = 'pvd'
        /* Cerebrovascular disease */
          '430   '-'438.9 ' = 'cvd'
        /* Dementia */
        '290   '-'290.9 ' = 'dem'
        /* Chronic pulmonary disease */
        '490   '-'496   ', '500   '-'505   ', '506.4 ' =  'cpd'
        /* Rheumatologic disease */
        '710.0 ', '710.1 ', '710.4 ', '714.0 '-'714.2 ', '714.81', '725   '
        = 'rhd'
        /* Peptic ulcer disease */
        '531   '-'534.91' = 'pud'
        /* Mild liver disease */
        '571.2 ', '571.5 ', '571.6 ', '571.4 '-'571.49' = 'mlivd'
        /* Diabetes */
        '250   '-'250.33', '250.7 '-'250.73' = 'diab'
        /* Diabetes with chronic complications */
        '250.4 '-'250.63' = 'diabc'
        /* Hemiplegia or paraplegia */
        '344.1 ', '342   '-'342.92' = 'plegia'
        /* Renal Disease */
        '582   '-'582.9 ', '583   '-'583.7 ', '585   '-'586   ',
        '588   '-'588.9 ' = 'ren'
        /*Malignancy, including leukemia and lymphoma */
        '140   '-'172.9 ', '174   '-'195.8 ', '200   '-'208.91' = 'malign'
        /* Moderate or severe liver disease */
        '572.2 '-'572.8 ', '456.0 '-'456.21' = 'slivd'
        /* Metastatic solid tumor */
        '196   '-'199.1 ' = 'mst'
        /* AIDS */
        '042   '-'044.9 ' = 'aids'
        /* Other */
         other   = 'other'
        ;
      run;

      proc sql;
        create table charlson_dx as
        select p.mrn
          , p.visit_date
          , d.adate
          , d.dx
          , put(d.dx, $icd9cf.) as coded_dx
        from temp.person_dates as p
          inner join temp.dx_subset as d
            on p.mrn = d.mrn 
        where d.dx_codetype = '09'
          and (p.visit_date - 365) <= d.adate < p.visit_date
          and d.enctype in ('AV', 'IP')
        order by mrn
          , visit_date
        ;

        create table charlson_px as
        select pd.mrn
          , pd.visit_date
          , px.adate
          , px.px
          , case
              when '35355' <= px.px <= '35381' 
                or px.px in ('38.48', '34201', '34203', '35454', '35456',
                '35459', '35470', '35473', '35474', '35482', '35483', '35485',
                '35492', '35493', '35495', '75962', '75992', '35521', '35533', 
                '35541', '35546', '35548', '35549', '35551', '35556', '35558', 
                '35563', '35565', '35566', '35571', '35582', '35583', '35584',
                '35585', '35586', '35587', '35621', '35623', '35641', '35646',
                '35647', '35651', '35654', '35656', '35661', '35663', '35665',
                '35666', '35671', '93668')
                then 'pvd'
              else 'other'
            end as coded_px length=5
        from temp.person_dates as pd
          inner join &_vdw_px as px
            on pd.mrn = px.mrn
        where (pd.visit_date - 365) <= px.adate < pd.visit_date
          and px.enctype in ('AV', 'IP')
        order by mrn
          , visit_date
        ;
      quit;

      %let var_list = mi chd pvd cvd dem cpd rhd pud mlivd diab diabc plegia ren malign slivd mst aids;

      data dx_assign;
        length &var_list 3;
        retain &var_list;
        set charlson_dx;
        by mrn visit_date;
        array comorb (*) &var_list;
        if first.visit_date then do;
          do i = 1 to dim(comorb);
            comorb(i) = 0;
          end;
        end;
        select (coded_dx);
          when ("mi") mi = 1;
          when ("chd") chd = 1;
          when ("pvd") pvd = 1;
          when ("cvd") cvd = 1;
          when ("dem") dem = 1;
          when ("cpd") cpd = 1;
          when ("rhd") rhd = 1;
          when ("pud") pud = 1;
          when ("mlivd") mlivd = 1;
          when ("diab") diab = 1;
          when ("diabc") diabc = 1;
          when ("plegia") plegia = 1;
          when ("ren") ren = 1;
          when ("malign") malign = 1;
          when ("slivd") slivd = 1;
          when ("mst") mst = 1;
          when ("aids") aids = 1;          
          otherwise;
        end;
        if last.visit_date then output;
        keep mrn visit_date &var_list;
      run;

      data px_assign;
        set charlson_px;
        by mrn visit_date;
        retain pvd;
        if first.visit_date then pvd = 0;
        select (coded_px);
           when ('pvd') pvd = 1;
           otherwise;
        end;
        if last.visit_date then output;
        keep mrn visit_date pvd;
      run;

      data dx_px_comb;
        merge dx_assign (in=a rename=(pvd=pvd_dx))  
          px_assign (in=b rename=(pvd=pvd_px))
        ;
        by mrn visit_date;
        if a or b;
        pvd = max(pvd_dx, pvd_px);
        drop pvd_dx pvd_px;
        array comorb (*) &var_list;
        do i=1 to dim(comorb);
          if comorb(i) = . then comorb(i) = 0;
        end;
      run;

      data calc_charlson;
        set dx_px_comb;
        length M1-M3 O1-O2 3;
        M1 = 1;
        M2 = 1;
        M3 = 1;
        O1 = 1;
        O2 = 1;
        if SLIVD = 1 then M1 = 0;
        if DIABC = 1 then M2 = 0;
        if MST = 1 then M3 = 0;
        charlson = sum(MI, CHD, PVD, CVD, DEM, CPD, RHD, PUD, M1*MLIVD, M2*DIAB,
          2*DIABC, 2*PLEGIA, 2*REN, O1*2*M3*MALIGN, 3*SLIVD, O2*6*MST, 6*AIDS) 
        ;
        keep mrn visit_date &var_list charlson;
      run;

      proc sql;
        create table temp.charlson as
        select p.mrn
          , p.visit_date
          %do i = 1 %to 17;
            %let cond = %scan(&var_list, &i);
            , c.&cond as charlson_&cond
          %end;
          , c.charlson as charlson_score
        from temp.person_dates as p
          left join calc_charlson as c
            on p.mrn = c.mrn and p.visit_date = c.visit_date
        ;
      quit;

      %dsdelete(charlson_dx|charlson_px|dx_assign|px_assign)
      %dsdelete(dx_px_comb|calc_charlson)

      options nomprint;
    %end;
%mend mod_charlson;

%mod_charlson

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
