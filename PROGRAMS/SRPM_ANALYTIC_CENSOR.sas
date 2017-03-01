*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_CENSOR.sas                                        *;
*   Purpose:  Calculate censoring dates for suicide attempts and deaths.      *;
*******************************************************************************;
options nomprint;

%macro censor;
  %if %sysfunc(exist(temp.censor)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "CENSOR"
      ;
    quit;

    %put WARNING: Data set TEMP.CENSOR already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.CENSOR cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.enr_post)) = 0 %then %do;
      %put ERROR: Data set TEMP.CENSOR cannot be created!;
      %put ERROR: Required input data set TEMP.ENR_POST does not exist.;
    %end;

    %else %if %sysfunc(exist(temp.deaths)) = 0 %then %do;
      %put ERROR: Data set TEMP.CENSOR cannot be created!;
      %put ERROR: Required input data set TEMP.DEATHS does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table temp.censor as
        select p.mrn
          , p.visit_date
          , case
              when e.enr_post_end + 30 >= d.death_date then d.death_date
              else e.enr_post_end
            end as enr_post_end
          , case
              when d.death_type in (0, 1) then d.death_date
              else .
            end as non_sui_dth_date
          , min(calculated non_sui_dth_date
                , calculated enr_post_end
                , '30SEP2015'd) as censor_att_date
          , min(calculated non_sui_dth_date
                , calculated enr_post_end
                , "&deathdate"d) as censor_dth_date
        from temp.person_dates as p
          left join temp.enr_post as e
            on p.mrn = e.mrn and p.visit_date = e.visit_date
          left join temp.deaths as d
            on p.mrn = d.mrn and p.visit_date = d.visit_date
        ;

        alter table temp.censor
        drop enr_post_end, non_sui_dth_date;
      quit;

      options nomprint;
    %end;
%mend censor;

%censor

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
