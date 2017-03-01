*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_ATT_POST.SAS                                      *;
*   Purpose:  Determine whether each person attempted suicide post-index.     *;
*******************************************************************************;
options nomprint;

%macro att_post;
  %if %sysfunc(exist(temp.att_post)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ATT_POST"
      ;
    quit;

    %put WARNING: Data set TEMP.ATT_POST already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.ATT_POST cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.dx_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.ATT_POST cannot be created!;
      %put ERROR: Required input data set TEMP.DX_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      %make_dx_list(DSI)
      %make_dx_list(PSI)
      %make_dx_list(POI)
      %make_dx_list(WOU)
      %make_dx_list(SUI)

      proc sql;
        create table get_att_dx as
        select p.mrn
          , p.visit_date
          , d.dx
          , d.adate
          , d.enc_id
          , d.enctype
        from temp.person_dates as p
          inner join temp.dx_subset as d
            on p.mrn = d.mrn 
        where p.visit_date <= d.adate <= '30SEP2015'd
          and compress(d.dx, '.') in (&dx_dsi, &dx_psi, &dx_poi, &dx_wou, &dx_sui)
        order by mrn
          , visit_date
          , enc_id
        ;
      quit;

      data sum_att_dx;
        set get_att_dx;
        by mrn visit_date enc_id;
        length DSI PSI DSV_LAC DSV_OTH PSV_LAC PSV_OTH POI WOU SUI 3;
        retain DSI PSI DSV_LAC DSV_OTH PSV_LAC PSV_OTH POI WOU SUI;
        if first.enc_id then do;
          dsi = 0;
          psi = 0;
          dsv_lac = 0;
          dsv_oth = 0;
          psv_lac = 0;
          psv_oth = 0;
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
        if compress(dx, '.') in (&dx_sui) then sui = max(sui, 1);
        if last.enc_id then output;
      run;

      data recode_att_dx;
        set sum_att_dx;
        length ANY_SUI_ATT LVI_SUI_ATT OVI_SUI_ATT NVI_SUI_ATT 3;
        any_sui_att = 0;
        lvi_sui_att = 0;
        ovi_sui_att = 0;
        nvi_sui_att = 0;
        if dsi = 1 or psi = 1 or (sui = 1 and (poi = 1 or wou = 1))
          then any_sui_att + 1
        ;
        if dsv_lac = 1 or psv_lac = 1 or (sui = 1 and wou = 1)
          then lvi_sui_att + 1
        ;
        if dsv_oth = 1 or psv_oth = 1 then ovi_sui_att + 1;
        if any_sui_att = 1 and lvi_sui_att = 0 and ovi_sui_att = 0
          then nvi_sui_att + 1
        ;
        if any_sui_att = 0 then delete;
        keep mrn visit_date enc_id adate enctype dsi psi dsv_lac dsv_oth
          psv_lac psv_oth poi wou sui any_sui_att lvi_sui_att ovi_sui_att
          nvi_sui_att
        ;
      run;
  
      data temp.att_post;
        set recode_att_dx;
        by mrn visit_date;
        length op_attempt_post ip_attempt_post any_attempt_post
          op_lvi_att_post ip_lvi_att_post any_lvi_att_post
          op_ovi_att_post ip_ovi_att_post any_ovi_att_post
          op_nvi_att_post ip_nvi_att_post any_nvi_att_post 3
          op_attempt_date ip_attempt_date any_attempt_date
          op_lvi_att_date ip_lvi_att_date any_lvi_att_date
          op_ovi_att_date ip_ovi_att_date any_ovi_att_date
          op_nvi_att_date ip_nvi_att_date any_nvi_att_date 8
        ;
        retain op_attempt_post ip_attempt_post any_attempt_post
          op_lvi_att_post ip_lvi_att_post any_lvi_att_post
          op_ovi_att_post ip_ovi_att_post any_ovi_att_post
          op_nvi_att_post ip_nvi_att_post any_nvi_att_post
          op_attempt_date ip_attempt_date any_attempt_date
          op_lvi_att_date ip_lvi_att_date any_lvi_att_date
          op_ovi_att_date ip_ovi_att_date any_ovi_att_date
          op_nvi_att_date ip_nvi_att_date any_nvi_att_date
        ;
        if first.visit_date then do;
          op_attempt_post = 0;
          ip_attempt_post = 0;
          any_attempt_post = 0;
          op_lvi_att_post = 0;
          ip_lvi_att_post = 0;
          any_lvi_att_post = 0;
          op_ovi_att_post = 0;
          ip_ovi_att_post = 0;
          any_ovi_att_post = 0;
          op_nvi_att_post = 0;
          ip_nvi_att_post = 0;
          any_nvi_att_post = 0;
          op_attempt_date = .;
          ip_attempt_date = .;
          any_attempt_date = .;
          op_lvi_att_date = .;
          ip_lvi_att_date = .;
          any_lvi_att_date = .;
          op_ovi_att_date = .;
          ip_ovi_att_date = .;
          any_ovi_att_date = .;
          op_nvi_att_date = .;
          ip_nvi_att_date = .;
          any_nvi_att_date = .;   
        end;
        if any_sui_att = 1 then do;
          any_attempt_post = max(any_attempt_post, 1);
          any_attempt_date = min(any_attempt_date, adate);
          if enctype in ('AV', 'ED') then do;
            op_attempt_post = max(op_attempt_post, 1);
            op_attempt_date = min(op_attempt_date, adate);
          end;
            else if enctype in ('IP', 'IS') then do;
              ip_attempt_post = max(ip_attempt_post, 1);
              ip_attempt_date = min(ip_attempt_date, adate);
            end;
        end;
        if lvi_sui_att = 1 then do;
          any_lvi_att_post = max(any_lvi_att_post, 1);
          any_lvi_att_date = min(any_lvi_att_date, adate);
          if enctype in ('AV', 'ED') then do;
            op_lvi_att_post = max(op_lvi_att_post, 1);
            op_lvi_att_date = min(op_lvi_att_date, adate);
          end;
            else if enctype in ('IP', 'IS') then do;
              ip_lvi_att_post = max(ip_lvi_att_post, 1);
              ip_lvi_att_date = min(ip_lvi_att_date, adate);
            end;
        end;
        if ovi_sui_att = 1 then do;
          any_ovi_att_post = max(any_ovi_att_post, 1);
          any_ovi_att_date = min(any_ovi_att_date, adate);
          if enctype in ('AV', 'ED') then do;
            op_ovi_att_post = max(op_ovi_att_post, 1);
            op_ovi_att_date = min(op_ovi_att_date, adate);
          end;
            else if enctype in ('IP', 'IS') then do;
              ip_ovi_att_post = max(ip_ovi_att_post, 1);
              ip_ovi_att_date = min(ip_ovi_att_date, adate);
            end;
        end;  
        if any_sui_att = 1 and lvi_sui_att = 0 and ovi_sui_att = 0 then do;
          any_nvi_att_post = max(any_nvi_att_post, 1);
          any_nvi_att_date = min(any_nvi_att_date, adate);
          if enctype in ('AV', 'ED') then do;
            op_nvi_att_post = max(op_nvi_att_post, 1);
            op_nvi_att_date = min(op_nvi_att_date, adate);
          end;
            else if enctype in ('IP', 'IS') then do;
              ip_nvi_att_post = max(ip_nvi_att_post, 1);
              ip_nvi_att_date = min(ip_nvi_att_date, adate);
            end;
        end;
        if last.visit_date then output;
        keep mrn visit_date 
          op_attempt_post ip_attempt_post any_attempt_post
          op_lvi_att_post ip_lvi_att_post any_lvi_att_post
          op_ovi_att_post ip_ovi_att_post any_ovi_att_post
          op_nvi_att_post ip_nvi_att_post any_nvi_att_post 
          op_attempt_date ip_attempt_date any_attempt_date
          op_lvi_att_date ip_lvi_att_date any_lvi_att_date
          op_ovi_att_date ip_ovi_att_date any_ovi_att_date 
          op_nvi_att_date ip_nvi_att_date any_nvi_att_date
        ;
      run;   
  
      %dsdelete(get_att_dx|sum_att_dx|recode_att_dx)

      options nomprint;
    %end;
%mend att_post;

%att_post

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
