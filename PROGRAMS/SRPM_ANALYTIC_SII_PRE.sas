*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_SII_PRE.SAS                                       *;
*   Purpose:  Determine whether each person had history of self-inflicted     *;
*             injury prior to index visit.                                    *;
*******************************************************************************;
options nomprint;

%macro sii_pre;
  %if %sysfunc(exist(temp.sii_pre)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "SII_PRE"
      ;
    quit;

    %put WARNING: Data set TEMP.SII_PRE already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.SII_PRE cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.dx_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.SII_PRE cannot be created!;
      %put ERROR: Required input data set TEMP.DX_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      %make_dx_list(DSI)
      %make_dx_list(PSI)
      %make_dx_list(INJ)
      %make_dx_list(POI)
      %make_dx_list(WOU)
      %make_dx_list(SUI)

      proc sql;
        create table get_sii_dx as
        select p.mrn
          , p.visit_date
          , d.dx
          , d.adate
          , d.enc_id
        from temp.person_dates as p
          inner join temp.dx_subset as d
            on p.mrn = d.mrn 
        where intnx('month', p.visit_date, -60, 's') < d.adate
          and d.adate < p.visit_date
          and compress(d.dx, '.') in (&dx_dsi, &dx_psi, &dx_inj, &dx_poi,
            &dx_wou, &dx_sui)
        order by mrn
          , visit_date
          , enc_id
          , adate desc
        ;
      quit;

      data sum_sii_dx (keep=mrn visit_date adate dsi psi dsv: psv: inj poi wou sui);
        set get_sii_dx;
        by mrn visit_date enc_id descending adate;
        length dsi psi dsv_lac dsv_oth psv_lac psv_oth inj poi wou sui 3;
        retain dsi psi dsv_lac dsv_oth psv_lac psv_oth inj poi wou sui;
        if first.adate then do;
          dsi = 0;
          psi = 0;
          dsv_lac = 0;
          dsv_oth = 0;
          psv_lac = 0;
          psv_oth = 0;
          inj = 0;
          poi = 0;
          wou = 0;
          sui = 0;
        end;
        if compress(dx, '.') in (&dx_dsi) then do;
          dsi = max(dsi, 1);
          if compress(dx, '.') = 'E956' then dsv_lac = max(dsv_lac, 1);
            else if compress(dx, '.') in: ('E953', 'E954', 'E955', 'E957')
              then dsv_oth = max(dsv_oth, 1)
            ;
        end;
        if compress(dx, '.') in (&dx_psi) then do;
          psi = max(psi, 1);
          if compress(dx, '.') = 'E986' then psv_lac = max(psv_lac, 1);
            else if compress(dx, '.') in: ('E983', 'E984', 'E985', 'E987')
              then psv_oth = max(psv_oth, 1)
            ;
        end;
        if compress(dx, '.') in (&dx_poi) then poi = max(poi, 1);
        if compress(dx, '.') in (&dx_wou) then wou = max(wou, 1);
        if compress(dx, '.') in (&dx_inj) then inj = max(inj, 1);
        if compress(dx, '.') in (&dx_sui) then sui = max(sui, 1);
        if last.enc_id then output;
      run;

      data recode_sii_dx;
        set sum_sii_dx;
        length any_sui_att lvi_sui_att ovi_sui_att any_inj_poi 3;
        if dsi = 1 or psi = 1 or (sui = 1 and (poi = 1 or wou = 1))
          then any_sui_att = 1
        ;
        if dsv_lac = 1 or psv_lac = 1 or (sui = 1 and wou = 1)
          then lvi_sui_att = 1
        ;
        if dsv_oth = 1 or psv_oth = 1 then ovi_sui_att = 1;
        if inj = 1 or poi = 1 then any_inj_poi = 1;
      run;

      data temp.sii_pre (keep=mrn visit_date any_sui_att_: lvi_sui_att_:
        ovi_sui_att_: any_inj_poi_:)
      ;
        set recode_sii_dx;
        by mrn visit_date;
        length any_sui_att_pre3m any_sui_att_pre1y any_sui_att_pre5y
          lvi_sui_att_pre3m lvi_sui_att_pre1y lvi_sui_att_pre5y
          ovi_sui_att_pre3m ovi_sui_att_pre1y ovi_sui_att_pre5y
          any_inj_poi_pre3m any_inj_poi_pre1y any_inj_poi_pre5y 3
        ;
        retain any_sui_att_pre3m any_sui_att_pre1y any_sui_att_pre5y
          lvi_sui_att_pre3m lvi_sui_att_pre1y lvi_sui_att_pre5y
          ovi_sui_att_pre3m ovi_sui_att_pre1y ovi_sui_att_pre5y
          any_inj_poi_pre3m any_inj_poi_pre1y any_inj_poi_pre5y
        ;
        if first.visit_date then do;
          any_sui_att_pre3m = 0;
          any_sui_att_pre1y = 0;
          any_sui_att_pre5y = 0;
          lvi_sui_att_pre3m = 0;
          lvi_sui_att_pre1y = 0;
          lvi_sui_att_pre5y = 0;
          ovi_sui_att_pre3m = 0;
          ovi_sui_att_pre1y = 0;
          ovi_sui_att_pre5y = 0;
          any_inj_poi_pre3m = 0;
          any_inj_poi_pre1y = 0;
          any_inj_poi_pre5y = 0;
        end;
        if any_sui_att = 1 then do;
          if intnx('day', visit_date, -90) <= adate < visit_date
            then any_sui_att_pre3m = max(any_sui_att_pre3m, 1)
          ;
            else if intnx('month', visit_date, -12, 's') <= adate
              and adate < intnx('day', visit_date, -90)
              then any_sui_att_pre1y = max(any_sui_att_pre1y, 1)
            ;
            else if intnx('month', visit_date, -60, 's') < adate
              and adate < intnx('month', visit_date, -12, 's')
              then any_sui_att_pre5y = max(any_sui_att_pre5y, 1)
            ;
        end;
        if lvi_sui_att = 1 then do;
          if intnx('day', visit_date, -90) <= adate < visit_date
            then lvi_sui_att_pre3m = max(lvi_sui_att_pre3m, 1)
          ;
            else if intnx('month', visit_date, -12, 's') <= adate
              and adate < intnx('day', visit_date, -90)
              then lvi_sui_att_pre1y = max(lvi_sui_att_pre1y, 1)
            ;
            else if intnx('month', visit_date, -60, 's') < adate
              and adate < intnx('month', visit_date, -12, 's')
              then lvi_sui_att_pre5y = max(lvi_sui_att_pre5y, 1)
            ;
        end;
        if ovi_sui_att = 1 then do;
          if intnx('day', visit_date, -90) <= adate < visit_date
            then ovi_sui_att_pre3m = max(ovi_sui_att_pre3m, 1)
          ;
            else if intnx('month', visit_date, -12, 's') <= adate
              and adate < intnx('day', visit_date, -90)
              then ovi_sui_att_pre1y = max(ovi_sui_att_pre1y, 1)
            ;
            else if intnx('month', visit_date, -60, 's') < adate
              and adate < intnx('month', visit_date, -12, 's')
              then ovi_sui_att_pre5y = max(ovi_sui_att_pre5y, 1)
            ;
        end;
        if any_inj_poi = 1 then do;
          if intnx('day', visit_date, -90) <= adate < visit_date
            then any_inj_poi_pre3m = max(any_inj_poi_pre3m, 1)
          ;
            else if intnx('month', visit_date, -12, 's') <= adate
              and adate < intnx('day', visit_date, -90)
              then any_inj_poi_pre1y = max(any_inj_poi_pre1y, 1)
            ;
            else if intnx('month', visit_date, -60, 's') < adate
              and adate < intnx('month', visit_date, -12, 's')
              then any_inj_poi_pre5y = max(any_inj_poi_pre5y, 1)
            ;
        end;
        if last.visit_date then output;
      run;

      %dsdelete(get_sii_dx|sum_sii_dx|recode_sii_dx)

      options nomprint;
    %end;
%mend sii_pre;

%sii_pre

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
