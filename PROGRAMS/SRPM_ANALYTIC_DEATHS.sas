*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_DEATHS.sas                                        *;
*   Purpose:  Determine if, when, and why each person died.                   *;
*******************************************************************************;
options nomprint;

%macro deaths;
  %if %sysfunc(exist(temp.deaths)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "DEATHS"
      ;
    quit;

    %put WARNING: Data set TEMP.DEATHS already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.DEATHS cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %do;
      options mprint;

      %dsdelete(all_cod)

      proc sql;
        create table all_cod as
        select p.mrn
          , p.visit_date
          , d.deathdt
          , d.dtimpute
          , d.source_list
          , d.confidence
          , c.cod
        from temp.person_dates as p
          inner join &_vdw_death as d
            on p.mrn = d.mrn
          left join &_vdw_cause_of_death as c
            on p.mrn = c.mrn
        where d.confidence in ('E', 'F')
          and d.deathdt >= p.visit_date - 30 /* ignore deaths >30 days pre-index */
          and d.deathdt <= '30SEP2015'd
        order by mrn
          , visit_date
          , deathdt
        ;
      quit;

      data temp.deaths (keep=mrn visit_date death_date dtimpute source_list
        confidence death_type)
       ;
        set all_cod;
        by mrn visit_date deathdt;
        rename deathdt=death_date;
        length death_type 3;
        retain death_type;
        /* Create worst cause-of-death "score" for each death. */
        if first.visit_date then death_type = .;
        if cod in: ('X7', 'X80', 'X81', 'X82', 'Y2', 'Y30', 'Y31', 'Y32')
          then do
        ;
        /* Score 4: Suicide, violent, non-laceration */
          if cod not in: ('X78', 'Y28') then death_type = max(death_type, 4);
        /* Score 3: Suicide, violent, laceration */ 
            else death_type = max(death_type, 3);
        end;
        /* Score 2: Suicide, non-violent */
          else if cod in: ('X6', 'X83', 'X84', 'Y1', 'Y33', 'Y34', 'Y87.0',
            'Y87.2') then death_type = max(death_type, 2)
          ;
        /* Score 1: Non-suicide death */
          else if cod ne '' then death_type = max(death_type, 1);
        /* Score 0: Unknown cause of death */
          else death_type = max(death_type, 0);
        if last.visit_date;
      run;

      options nomprint;
    %end;
%mend deaths;

%deaths

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
