*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_MASTER.SAS                                        *;
*   Purpose:  Perform overarching setup and call subroutines designed to      *;
*             construct the final analytic data set for MHRN SRPM modeling.   *;
*   Updated:  27 February 2017                                                *;
*******************************************************************************;
* UPDATE HISTORY                                                              *;
*   Date      Comment                                                         *;
*   ========================================================================= *;
*   20170227  Initial GitHub version (for this program and all subroutines)   *;
*             finalized.                                                      *;
*******************************************************************************;

*******************************************************************************;
* EDIT SECTION: Enter the following values and run this section of code every *;
* time you use this program.                                                  *;
* 1 %include full location + name of local StdVars file.                      *;
* 2 %let root = location where you extracted this program.                    *;
* 3 %let startdate = either 01JAN2009 or DDMONYYYY-formatted date of local    *;
*   Epic implementation, whichever happened more recently.                    *;
* 4 %let deathdate = DDMONYYYY-formated date through which __cause-of-death__ *;
*   data are considered complete in the VDW.                                  *;
* 5 %let denom = location of SRPM_DENOM_FULL data set. (Should be in /LOCAL   *;
* subfolder from SRPM_DENOM program package.)                                 *;
* 6 %let cesrpro = location of PHQ9_CESR_PRO data set described in README.md. *;
* 7 %let itemX_ids = comma-separated lists of QUESTION_ID values to identify  *;
*   PHQ item 1-9 scores in PHQ9_CESR_PRO data described above.                *;
*******************************************************************************;
%include "\\path\StdVars.sas";
%let root = \\path\SRPM_ANALYTIC;
%let startdate = 01JAN2009;
%let deathdate = 31DEC2014;
%let denom = \\path\SRPM_DENOM\LOCAL;
%let cesrpro = \\path\phq9_cesr_pro;
%let item1_ids = '8600001', '600001';
%let item2_ids = '8600002', '600002';
%let item3_ids = '8600003', '600003';
%let item4_ids = '8600004', '600004';
%let item5_ids = '8600005', '600005';
%let item6_ids = '8600006', '600006';
%let item7_ids = '8600007', '600007';
%let item8_ids = '8600008', '600008';
%let item9_ids = '8600009', '600009';

*******************************************************************************;
* SETUP SECTION: Run as-is every time you use this program.                   *;
*******************************************************************************;
%macro set_slash;
  %global s;
  %if %index(&root, /) 
    or %index(%upcase(&sysscp), HP)
    or %index(%upcase(&sysscp), LIN)
    or %index(%upcase(&sysscp), AIX)
    or %index(%upcase(&sysscp), SUN)
    %then %let s = /
  ;
    %else %let s = \;
%mend set_slash;

%set_slash

data _null_;
  x = index("&root", "SRPM_ANALYTIC");
  if x = 0 then call symput('root', strip("&root" || "&s.SRPM_ANALYTIC"));
run;

proc datasets kill lib=work memtype=data nolist;
quit;

%macro dsdelete(dslist /* pipe-delimited list */);
  %do i = 1 %to %sysfunc(countw(&dslist, |));
    %let dsname = %scan(&dslist, &i, |);
    %if %sysfunc(exist(&dsname)) = 1 %then %do;
      proc sql;
        drop table &dsname;
      quit;
    %end;
  %end;
%mend dsdelete;

options errors=0 formchar="|----|+|---+=|-/\<>*" mprint nocenter nodate
  nofmterr nomlogic nonumber nosymbolgen
;

ods results off;

ods listing;

title;

footnote;

%let filedate = %sysfunc(today(), yymmddn8.);

%let dispdate = %sysfunc(today(), mmddyys10.);

libname denom "&denom";

libname cesrpro "&cesrpro";

libname input "&root.&s.INPUT";

libname temp "&root.&s.TEMP";

libname share "&root.&s.SHARE";

data srpm_dx_list;
  infile "&root.&s.INPUT&s.srpm_dx_list.txt" dlm='09'x dsd firstobs=1
    lrecl=32767
  ;
  informat condition $3. dx $6. description $225.;
  input @1 condition $3. @9 dx $6. @15 description : $225.;
  if condition = 'EXC' then delete;
run; 

proc sort data=srpm_dx_list;
  by condition dx;
run;

%macro make_dx_list(condition);
  %global DX_&CONDITION;

  proc sql noprint;
    select distinct quote(strip(dx)) into :DX_&condition separated by ', '
    from srpm_dx_list
    where condition = upcase("&condition")
    ;
  quit;
%mend make_dx_list;

resetline;

*******************************************************************************;
* DENOM: Prepare temporary visit, person-date, and person denominator data    *;
* sets for use throughout creation of final analysis data set.                *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_DENOM.sas" / lrecl=32767;

*******************************************************************************;
* DEM_CEN: Pull variables needed for demographic and census covariates.       *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_DEM_CEN.sas" / lrecl=32767;

*******************************************************************************;
* ENROLL: Prepare enrollment-related variables for each person-date.          *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_ENROLL.sas" / lrecl=32767;

*******************************************************************************;
* DX_SUBSET: Pull all diagnoses for underlying person denominator during      *;
* study timeframe to save time running against VDW_DX in later queries.       *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_DX_SUBSET.sas" / lrecl=32767;

*******************************************************************************;
* CHARLSON: Pull Charlson comorbidity score and related indicators for year   *;
* prior to each index visit. Code modified from VDW standard macro %Charlson. *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_CHARLSON.sas" / lrecl=32767;

*******************************************************************************;
* MH_DX: Check for diagnoses of various MH conditions at/prior to index.      *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_MH_DX.sas" / lrecl=32767;

*******************************************************************************;
* DELIVERY: Pull indicators for infant delivery within specified timeframe    *;
* around index date. Code borrowed from MEPREP studies.                       *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_DELIVERY.sas" / lrecl=32767;

*******************************************************************************;
* MH_RX: Check for relevant MH Rx fills prior to index visit.                 *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_MH_RX.sas" / lrecl=32767;

*******************************************************************************;
* MH_UTE: Identify MH-related utilization prior to index visit.               *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_MH_UTE.sas" / lrecl=32767;

*******************************************************************************;
* SII_PRE: Determine whether each person had history of self-inflicted injury *;
* prior to index visit.                                                       *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_SII_PRE.sas" / lrecl=32767;

*******************************************************************************;
* ITEM9_INDEX: Identify best PHQ item #9 scores for index visit.              *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_ITEM9_INDEX.sas" / lrecl=32767;

*******************************************************************************;
* ITEM18_INDEX: Obtain latest non-missing score on index visit date for PHQ   *;
* items #1-8.                                                                 *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_ITEM18_INDEX.sas" / lrecl=32767;

*******************************************************************************;
* ITEM9_PRE: Obtain up to 3 PHQ #9 scores/dates prior to index visit.         *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_ITEM9_PRE.sas" / lrecl=32767;

*******************************************************************************;
* DEATHS: Determine if, when, and why each person died.                       *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_DEATHS.sas" / lrecl=32767;

*******************************************************************************;
* CENSOR: Calculate censoring dates for suicide attempts and deaths.          *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_CENSOR.sas" / lrecl=32767;

*******************************************************************************;
* ATT_POST: Determine whether each person attempted suicide post-index.       *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_ATT_POST.sas" / lrecl=32767;

*******************************************************************************;
* COMBINE: Combine all temporary data sets into final analytic data set.      *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_COMBINE.sas" / lrecl=32767;

*******************************************************************************;
* SUMMARY: Produce descriptive statistics about final analytic data set.      *;
*******************************************************************************;
%include "&root.&s.PROGRAMS&s.SRPM_ANALYTIC_SUMMARY.sas" / lrecl=32767;

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
