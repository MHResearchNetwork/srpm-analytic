*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_MH_RX.SAS                                         *;
*   Purpose:  Check for relevant MH Rx fills prior to index visit.            *;
*******************************************************************************;
options nomprint;

%macro mh_rx;
  %if %sysfunc(exist(temp.mh_rx)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "MH_RX"
      ;
    quit;

    %put WARNING: Data set TEMP.MH_RX already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(input.mhrn2_ndc2015)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_RX cannot be created!;
      %put ERROR: Required input data set INPUT.MHRN2_NDC2015 does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.people)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_RX cannot be created!;
      %put ERROR: Required input data set TEMP.PEOPLE does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_RX cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %do;
      options mprint;

      data relevant_ndc;
        set input.mhrn2_ndc2015 (keep=ndc category active_ingred);
        where lowcase(category) in: ('antidep', 'antipsy', 'ben', 'hyp', 'inj')
          and index(lowcase(category), '1st') = 0
        ;
        if lowcase(category) =: 'antidep' 
          and lowcase(active_ingred) in: ('trazodone', 'amitriptyline', 'doxepin') 
          then delete
        ;
          else if lowcase(category) =: 'inj' 
            and lowcase(active_ingred) not in ('aripiprazole', 'olanzapine', 
            'paliperidone', 'risperidone', 'ziprasidone')
            then delete
          ;
        if lowcase(category) in: ('antidep', 'ben', 'hyp')
          then cat = upcase(substr(category, 1, 1))
        ;
          else cat = 'S';
      run;

      proc sql;
        create table rx_subset as
        select r.mrn, r.rxdate, r.ndc
        from temp.people as p
          inner join &_vdw_rx as r
            on p.mrn = r.mrn
        where intnx('month', p.first_visit, -60, 's') < r.rxdate
          and r.rxdate < p.last_visit
          and r.ndc in (select ndc from relevant_ndc)
        ;
      quit;

      proc sql;
        create table get_pre_rx as
        select p.mrn
          , p.visit_date
          , r.ndc
          , r.rxdate
          , n.cat
        from temp.person_dates as p
          inner join rx_subset as r
            on p.mrn = r.mrn 
          inner join relevant_ndc as n
            on r.ndc = n.ndc
        where intnx('month', p.visit_date, -60, 's') < r.rxdate
          and r.rxdate < p.visit_date
        order by mrn
          , visit_date
          , rxdate
          , ndc
        ;
      quit;

      data recode_pre_rx;
        set get_pre_rx;
        if intnx('day', visit_date, -90) <= rxdate < visit_date 
          then timeframe = 'PRE3M'
        ;
          else if intnx('month', visit_date, -12, 's') <= rxdate
            and rxdate < intnx('day', visit_date, -90) 
            then timeframe = 'PRE1Y'
          ;
          else if intnx('month', visit_date, -60, 's') < rxdate
            and rxdate < intnx('month', visit_date, -12, 's')
            then timeframe = 'PRE5Y'
          ;
        length drug_type $ 7;
        if cat = 'A' then drug_type = 'ANTIDEP';
          else if cat = 'B' then drug_type = 'BENZO';
          else if cat = 'H' then drug_type = 'HYPNO';
          else if cat = 'S' then drug_type = 'SGA';
        var_name = catx('_RX_', drug_type, timeframe);
        length sum_var 3;
        sum_var = 1;
      run;

      proc summary data=recode_pre_rx nway;
        class mrn visit_date var_name;
        var sum_var;
        output out=sum_pre_rx (drop=_type_ _freq_) max=;
      run;

      proc transpose data=sum_pre_rx out=tran_pre_rx (drop=_name_);
        by mrn visit_date;
        var sum_var;
        id var_name;
      run;

      data temp.mh_rx;
        set tran_pre_rx;
        array rx {12} antidep: benzo: hypno: sga:;
        do i = 1 to 12;
          if rx{i} = . then rx{i} = 0;
        end;
        drop i;
      run;

      %dsdelete(relevant_ndc|rx_subset|get_pre_rx)
      %dsdelete(recode_pre_rx|sum_pre_rx|tran_pre_rx)

      options nomprint;
    %end;
%mend mh_rx;

%mh_rx
*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
