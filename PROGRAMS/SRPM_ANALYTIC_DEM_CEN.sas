*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_DEM_CEN.SAS                                       *;
*   Purpose:  Pull variables needed for demographic and census covariates.    *;
*******************************************************************************;
options nomprint;

%macro demog;
  %if %sysfunc(exist(temp.demog)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "DEMOG"
      ;
    quit;

    %put WARNING: Data set TEMP.DEMOG already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.people)) = 0 %then %do;
      %put ERROR: Data set TEMP.DEMOG cannot be created!;
      %put ERROR: Required input data set TEMP.PEOPLE does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table temp.demog as
        select p.mrn
          , d.gender
          , d.race1
          , d.race2
          , d.hispanic
        from temp.people as p
          inner join &_vdw_demographic as d
            on p.mrn = d.mrn
        ;
      quit;

      options nomprint;
    %end;
%mend demog;

%demog

%macro census;
  %if %sysfunc(exist(temp.census)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "CENSUS"
      ;
    quit;

    %put WARNING: Data set TEMP.CENSUS already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.CENSUS cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %do;
      options mprint;

      %local max_cen;

      proc sql noprint;
        select max(census_year) into :max_cen
        from &_vdw_census_demog
        ;

        create table temp.census as
        select p.mrn
          , p.visit_date
          , d.medhousincome
          , d.education6
          , d.education7
          , d.education8
        from temp.person_dates as p
          inner join &_vdw_census_loc as c
            on p.mrn = c.mrn
            and c.geocode ^= ''
            and c.loc_start <= p.visit_date <= c.loc_end
          inner join &_vdw_census_demog as d
            on substr(c.geocode, 1, 11) = d.geocode
            and d.census_year = &max_cen
        ;
      quit;

      options nomprint;
    %end;
%mend census;

%census

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
