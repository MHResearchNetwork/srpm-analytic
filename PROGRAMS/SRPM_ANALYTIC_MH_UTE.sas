*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_MH_UTE.SAS                                        *;
*   Purpose:  Identify MH-related utilization prior to index visit.           *;
*******************************************************************************;
options nomprint;

%macro mh_ute;
  %if %sysfunc(exist(temp.mh_ute)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "MH_UTE"
      ;
    quit;

    %put WARNING: Data set TEMP.MH_UTE already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.people)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_UTE cannot be created!;
      %put ERROR: Required input data set TEMP.PEOPLE does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_UTE cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.dx_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.MH_UTE cannot be created!;
      %put ERROR: Required input data set TEMP.DX_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql; 
        create table mh_ute_enc as
        select u.enc_id
          , u.mrn
          , u.adate
          , u.enctype
          , u.encounter_subtype
          , u.department
          , u.provider as enc_provider
          , s.specialty as enc_specialty
        from temp.people as p
          inner join &_vdw_utilization as u
            on p.mrn = u.mrn
          left join &_vdw_provider_specialty as s
            on u.provider = s.provider and u.provider ne ''
        where "01JAN2004"d < intnx('month', p.first_visit, -60, 's') < u.adate
          and u.adate < p.last_visit
          and u.enctype not in ('LO', 'RO', 'EM', 'TE')
        ;

        create table mh_ute_dx as
        select distinct d.mrn
          , d.adate
          , d.enc_id
          , d.diagprovider as dx_provider
          , s.specialty as dx_specialty
          , 1 as mh_dx length=3
        from mh_ute_enc as e
          inner join temp.dx_subset as d
            on e.enc_id = d.enc_id
          left join &_vdw_provider_specialty as s
            on d.diagprovider = s.provider and d.diagprovider ne ''
        where substr(d.dx, 1, 2) in ('29', '30', '31')
        ;

        create table mh_ute_px as
        select distinct p.mrn
          , p.adate
          , p.enc_id
          , 1 as mh_px length=3
        from mh_ute_enc as e
          inner join &_vdw_px as p
            on e.enc_id = p.enc_id
        where ( substr(p.px, 1, 4) in ('9079', '9080', '9081', '9082', '9083',
                '9084', '9085')
            or  substr(p.px, 1, 5) in ('90860', '90861', '90862') )
        ;

        create table comb_mh_ute as
        select e.enc_id
          , e.mrn
          , e.adate
          , e.enctype
          , e.encounter_subtype
          , e.department
          , e.enc_specialty
          , max(d.mh_dx) as any_mh_dx_code
          , max(case 
                  when d.dx_specialty in ('MEN', 'PSY', 'SOC') then 1
                  else 0
                end) as any_mh_dx_prov
          , max(p.mh_px) as any_mh_px
        from mh_ute_enc as e
          left join mh_ute_dx as d
            on e.enc_id = d.enc_id
          left join mh_ute_px as p
            on e.enc_id = p.enc_id
        group by e.enc_id
          , e.mrn
          , e.adate
          , e.enctype
          , e.encounter_subtype
          , e.department
          , e.enc_specialty
        ;

        create table add_mh_ute as
        select p.mrn
          , p.visit_date
          , c.enc_id
          , c.adate
          , c.enctype
          , c.encounter_subtype
          , c.department
          , c.enc_specialty
          , c.any_mh_dx_code
          , c.any_mh_dx_prov
          , c.any_mh_px
        from temp.person_dates as p
          inner join comb_mh_ute as c
            on p.mrn = c.mrn
        where intnx('month', p.visit_date, -60, 's') < c.adate
          and c.adate < p.visit_date
        order by mrn
          , visit_date
          , adate desc
        ;
      quit;

      data temp.mh_ute;
        set add_mh_ute;
        by mrn visit_date;
        length mh_ip_pre3m mh_ip_pre1y mh_ip_pre5y mh_ed_pre3m mh_ed_pre1y
          mh_ed_pre5y mh_op_pre3m mh_op_pre1y mh_op_pre5y 3
        ;
        retain mh_ip_pre3m mh_ip_pre1y mh_ip_pre5y mh_ed_pre3m mh_ed_pre1y
          mh_ed_pre5y mh_op_pre3m mh_op_pre1y mh_op_pre5y
        ;
        if first.visit_date then do;
          mh_ip_pre3m = 0;
          mh_ip_pre1y = 0;
          mh_ip_pre5y = 0;
          mh_ed_pre3m = 0;
          mh_ed_pre1y = 0;
          mh_ed_pre5y = 0;
          mh_op_pre3m = 0;
          mh_op_pre1y = 0;
          mh_op_pre5y = 0;
        end;
        if any_mh_dx_code = 1 then do;
          if enctype in ('IS', 'IP') then do;
            if visit_date - 90 <= adate < visit_date
              then mh_ip_pre3m = max(mh_ip_pre3m, 1)
            ;
              else if intnx('month', visit_date, -12, 's') <= adate
                and adate < visit_date - 90 
                then mh_ip_pre1y = max(mh_ip_pre1y, 1)
              ;
              else if intnx('month', visit_date, -60, 's') < adate
                and adate < intnx('month', visit_date, -12, 's')
                then mh_ip_pre5y = max(mh_ip_pre5y, 1)
              ;
          end;
            else if enctype = 'ED' or encounter_subtype = 'UC'
              or department in ('ER', 'URG') or enc_specialty in ('EME', 'URG')
              then do
            ;
              if visit_date - 90 <= adate < visit_date
                then mh_ed_pre3m = max(mh_ed_pre3m, 1)
              ;
                else if intnx('month', visit_date, -12, 's') <= adate
                  and adate < visit_date - 90 
                  then mh_ed_pre1y = max(mh_ed_pre1y, 1)
                ;
                else if intnx('month', visit_date, -60, 's') < adate
                  and adate < intnx('month', visit_date, -12, 's')
                  then mh_ed_pre5y = max(mh_ed_pre5y, 1)
                ;
            end;
        end;
        if enctype = 'AV' and (any_mh_px = 1 or department = 'MH'
          or enc_specialty in ('MEN', 'PSY', 'SOC') or any_mh_dx_prov = 1)
          then do
        ;
          if (visit_date - 90) <= adate < visit_date
            then mh_op_pre3m = max(mh_op_pre3m, 1)
          ;
            else if intnx('month', visit_date, -12, 's') <= adate
              and adate < (visit_date - 90) 
              then mh_op_pre1y = max(mh_op_pre1y, 1)
            ;
            else if intnx('month', visit_date, -60, 's') < adate
              and adate < intnx('month', visit_date, -12, 's')
              then mh_op_pre5y = max(mh_op_pre5y, 1)
            ;
        end;
        if last.visit_date then output;
        keep mrn visit_date mh_ip: mh_ed: mh_op:;
      run;

      %dsdelete(mh_ute_enc|mh_ute_dx|mh_ute_px|comb_mh_ute|add_mh_ute)

      options nomprint;
    %end;
%mend mh_ute;

%mh_ute

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
