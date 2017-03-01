*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_DX_SUBSET.SAS                                     *;
*   Purpose:  Pull all diagnoses for underlying person denominator during     *;
*             study timeframe to save time running against VDW_DX in later    *;
*             queries.                                                        *;
*******************************************************************************;
options nomprint;

%macro dx_subset;
  %if %sysfunc(exist(temp.dx_subset)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "DX_SUBSET"
      ;
    quit;

    %put WARNING: Data set TEMP.DX_SUBSET already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.people)) = 0 %then %do;
      %put ERROR: Data set TEMP.DX_SUBSET cannot be created!;
      %put ERROR: Required input data set TEMP.PEOPLE does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql; 
        create table temp.dx_subset as
        select d.* 
        from temp.people as p
          inner join &_vdw_dx as d
            on p.mrn = d.mrn
        where intnx('month', p.first_visit, -60, 's') < d.adate
          and d.adate <= '30SEP2015'd
        ;
      quit;

      options nomprint;
    %end;
%mend dx_subset;

%dx_subset
*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
