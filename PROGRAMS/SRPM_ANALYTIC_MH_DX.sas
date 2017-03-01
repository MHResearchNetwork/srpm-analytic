*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_MH_DX.SAS                                         *;
*   Purpose:  Check for diagnoses of various MH conditions at/prior to index. *;
*******************************************************************************;
options nomprint;

%macro mh_dx;
  %if %sysfunc(exist(temp.mh_dx)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "MH_DX"
      ;
    quit;

    %put WARNING: Data set TEMP.MH_DX already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_DX cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.dx_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_DX cannot be created!;
      %put ERROR: Required input data set TEMP.DX_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      %make_dx_list(DEP)
      %make_dx_list(ANX)
      %make_dx_list(BIP)
      %make_dx_list(SCH)
      %make_dx_list(OTH)
      %make_dx_list(DEM)
      %make_dx_list(ADD)
      %make_dx_list(ASD)
      %make_dx_list(PER)
      %make_dx_list(ALC)
      %make_dx_list(DRU)
      %make_dx_list(PTS)
      %make_dx_list(EAT)
      %make_dx_list(TBI)

      proc sql;
        create table get_mh_dx as
        select p.mrn
          , p.visit_date
          , d.dx
          , d.adate
        from temp.person_dates as p
          inner join temp.dx_subset as d
            on p.mrn = d.mrn 
        where intnx('month', p.visit_date, -60, 's') < d.adate
          and d.adate <= p.visit_date
          and compress(d.dx, '.') in (&dx_dep, &dx_anx, &dx_bip, &dx_sch,
            &dx_oth, &dx_dem, &dx_add, &dx_asd, &dx_per, &dx_alc, &dx_dru,
            &dx_pts, &dx_eat, &dx_tbi)
        order by mrn
          , visit_date
          , adate
          , dx
        ;
      quit;

      %let dx_list = DEP ANX BIP SCH OTH DEM ADD ASD PER ALC DRU PTS EAT TBI;

      %let dx_count = %sysfunc(countw(&dx_list));
  
      data temp.mh_dx (drop=dx adate);
        set get_mh_dx;
        by mrn visit_date;
        %do i = 1 %to &dx_count;
          %let a = %scan(&dx_list, &i);
          length &a._DX_INDEX &a._DX_PRE1Y &a._DX_PRE5Y 3;
          retain &a._DX_index &a._DX_pre1y &a._DX_pre5y;
        %end;
        if first.visit_date then do;
          %do j = 1 %to &dx_count;
            %let b = %scan(&dx_list, &j);
            &b._dx_index = 0;
            &b._dx_pre1y = 0;
            &b._dx_pre5y = 0;
          %end;
        end;
        %do k = 1 %to &dx_count;
          %let c = %scan(&dx_list, &k);
          if compress(dx, '.') in (&&dx_&c) then do;
            if visit_date = adate then &c._dx_index = max(&c._dx_index, 1);
              else if intnx('month', visit_date, -12, 's') <= adate
                and adate < visit_date then &c._dx_pre1y = max(&c._dx_pre1y, 1)
              ;
              else if intnx('month', visit_date, -60, 's') < adate
                and adate < intnx('month', visit_date, -12, 's') 
                then &c._dx_pre5y = max(&c._dx_pre5y, 1)
              ;
          end;
        %end;
        if last.visit_date then output;
      run;

      %dsdelete(get_mh_dx)

      options nomprint;
    %end;
%mend mh_dx;

%mh_dx
*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
