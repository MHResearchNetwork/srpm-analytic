*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_ITEM18_INDEX.SAS                                  *;
*   Purpose:  Obtain latest non-missing score on index visit date for PHQ     *;
*             items #1 through #8.                                            *;
*******************************************************************************;
options nomprint;

%macro item18_index;
  %if %sysfunc(exist(temp.item18_index)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ITEM18_INDEX"
      ;
    quit;

    %put WARNING: Data set TEMP.ITEM18_INDEX already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(cesrpro.phq9_cesr_pro)) = 0 %then %do;
      %put ERROR: Data set TEMP.ITEM18_INDEX cannot be created!;
      %put ERROR: Required input data set CESRPRO.PHQ9_CESR_PRO does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.ITEM18_INDEX cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %do;
      options mprint;

      data all_phq_item18;
          set cesrpro.phq9_cesr_pro;
          where response_date between "&startdate"d and "30JUN2015"d
            and question_id in (&item1_ids, &item2_ids, &item3_ids,
            &item4_ids, &item5_ids, &item6_ids, &item7_ids, &item8_ids)
            and strip(response_text) in ('0', '1', '2', '3')
          ;
          if question_id in (&item1_ids) then num = '1';
            else if question_id in (&item2_ids) then num = '2';
            else if question_id in (&item3_ids) then num = '3';
            else if question_id in (&item4_ids) then num = '4';
            else if question_id in (&item5_ids) then num = '5';
            else if question_id in (&item6_ids) then num = '6';
            else if question_id in (&item7_ids) then num = '7';
            else if question_id in (&item8_ids) then num = '8';
          score = input(substr(response_text, 1, 1), 1.);
          keep mrn response_date response_time num score;
      run;

      proc sort data=all_phq_item18 out=sort_phq_item18;
        by mrn response_date num descending response_time descending score; 
      run;

      data last_phq_item18;
        set sort_phq_item18;
        by mrn response_date num descending response_time descending score;
        if first.num;
      run;

      proc transpose data=last_phq_item18 out=tran_phq_item18 (drop=_name_)
        prefix=item suffix=_index_score
      ;
        by mrn response_date;
        var score;
        id num;
      run;

      proc sql; 
        create table temp.item18_index as
        select p.mrn
          , p.visit_date
          , t.item1_index_score
          , t.item2_index_score
          , t.item3_index_score
          , t.item4_index_score
          , t.item5_index_score
          , t.item6_index_score
          , t.item7_index_score
          , t.item8_index_score
        from temp.person_dates as p
          inner join tran_phq_item18 as t
            on p.mrn = t.mrn
            and p.visit_date = t.response_date
        where t.item1_index_score ne .
          or t.item2_index_score ne .
          or t.item3_index_score ne .
          or t.item4_index_score ne . 
          or t.item5_index_score ne .
          or t.item6_index_score ne .
          or t.item7_index_score ne .
          or t.item8_index_score ne .
        ;
      quit;

      %dsdelete(all_phq_item18|sort_phq_item18|last_phq_item18|tran_phq_item18)

      options nomprint;
    %end;
%mend item18_index;

%item18_index

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
