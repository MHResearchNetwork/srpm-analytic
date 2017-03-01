*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_DELIVERY.SAS                                      *;
*   Purpose:  Pull indicators for infant delivery within specified timeframe  *;
*             around index date.                                              *;
*******************************************************************************;
options nomprint;

%macro delivery;
  %if %sysfunc(exist(temp.delivery)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "DELIVERY"
      ;
    quit;

    %put WARNING: Data set TEMP.DELIVERY already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(input.delivery_dx_list)) = 0 %then %do;
      %put ERROR: Data set TEMP.DELIVERY cannot be created!;
      %put ERROR: Required input data set INPUT.DELIVERY_DX_LIST does not exist.;
    %end;
    %else %if %sysfunc(exist(input.delivery_px_list)) = 0 %then %do;
      %put ERROR: Data set TEMP.DELIVERY cannot be created!;
      %put ERROR: Required input data set INPUT.DELIVERY_PX_LIST does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.DELIVERY cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.demog)) = 0 %then %do;
      %put ERROR: Data set TEMP.DELIVERY cannot be created!;
      %put ERROR: Required input data set TEMP.DEMOG does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.dx_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.DELIVERY cannot be created!;
      %put ERROR: Required input data set TEMP.DX_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql noprint;
        select distinct quote(strip(upcase(dx))) into :dx_del separated by ', '
        from input.delivery_dx_list
        ;

        select distinct quote(strip(px)) into :px_del separated by ', '
        from input.delivery_px_list
        ;
      quit;  

      proc sql;
        create table sort_del_ute as
        select pd.mrn
          , pd.visit_date
          , dx.dx as ute_code length=10
          , dx.adate
          , 'D' as ute_type
        from temp.person_dates as pd
          inner join temp.demog as dem
            on pd.mrn = dem.mrn
          inner join temp.dx_subset as dx
            on pd.mrn = dx.mrn 
        where dem.gender = 'F'
          and dx.enctype = 'IP'
          and pd.visit_date - 365 <= dx.adate
          and dx.adate <= min('30SEP2015'd, pd.visit_date + 280)
          and strip(upcase(dx.dx)) in (&dx_del)
        union
        select pd.mrn
          , pd.visit_date
          , px.px as ute_code length=10
          , px.adate
          , 'P' as ute_type
        from temp.person_dates as pd
          inner join temp.demog as dem
            on pd.mrn = dem.mrn
          inner join &_vdw_px as px
            on pd.mrn = px.mrn
        where dem.gender = 'F'
          and px.enctype = 'IP'
          and pd.visit_date - 365 <= px.adate
          and px.adate <= min('30SEP2015'd, pd.visit_date + 280)
          and strip(px.px) in (&px_del)
        order by mrn
          , visit_date
          , adate
        ;
      quit;

      data sum_del_ute;
        set sort_del_ute;
        by mrn visit_date adate;
        length del_pre_181_365 del_pre_91_180 del_pre_1_90 
          del_post_1_90 del_post_91_180 del_post_181_280 3
        ;
        retain del_pre_181_365 del_pre_91_180 del_pre_1_90
          del_post_1_90 del_post_91_180 del_post_181_280
        ;
        if first.visit_date then do;
          del_pre_181_365 = 0;
          del_pre_91_180 = 0;
          del_pre_1_90 = 0; 
          del_post_1_90 = 0;
          del_post_91_180 = 0;
          del_post_181_280 = 0;
        end;
        if visit_date - 365 <= adate < visit_date - 180 
          then del_pre_181_365 = max(del_pre_181_365, 1)
        ;
          else if visit_date - 180 <= adate < visit_date - 90
            then del_pre_91_180 = max(del_pre_91_180, 1)
          ;
          else if visit_date - 90 <= adate < visit_date
            then del_pre_1_90 = max(del_pre_1_90, 1)
          ;
          else if visit_date < adate <= visit_date + 90
            then del_post_1_90 = max(del_post_1_90, 1)
          ;
          else if visit_date + 90 < adate <= visit_date + 180
            then del_post_91_180 = max(del_post_91_180, 1)
          ;
          else if visit_date + 180 < adate <= visit_date + 280
            then del_post_181_280 = max(del_post_181_280, 1)
          ;
        if last.visit_date then output;
        keep mrn visit_date del_pre_181_365 del_pre_91_180 del_pre_1_90
          del_post_1_90 del_post_91_180 del_post_181_280 
        ;
      run;

      proc sql;
        create table temp.delivery as
        select p.mrn
          , p.visit_date
          , coalesce(s.del_pre_181_365, 0) as del_pre_181_365
          , coalesce(s.del_pre_91_180, 0) as del_pre_91_180
          , coalesce(s.del_pre_1_90, 0) as del_pre_1_90
          , case
              when s.del_post_1_90 = 1 then 1
              when p.visit_date + 90 > '30SEP2015'd then -1
              else 0
            end as del_post_1_90
          , case
              when s.del_post_91_180 = 1 then 1
              when p.visit_date + 180 > '30SEP2015'd then -1
              else 0
            end as del_post_91_180
          , case
              when s.del_post_181_280 = 1 then 1
              when p.visit_date + 280 > '30SEP2015'd then -1
              else 0
            end as del_post_181_280
        from temp.person_dates as p
          inner join temp.demog as d
            on p.mrn = d.mrn
          left join sum_del_ute as s
            on p.mrn = s.mrn and p.visit_date = s.visit_date
        where d.gender = 'F'
        ;
      quit;

      %dsdelete(sort_del_ute|sum_del_ute)

      options nomprint;
    %end;
%mend delivery;

%delivery
*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
