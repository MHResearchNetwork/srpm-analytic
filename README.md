# Suicide Risk Prediction Model (SRPM)
## Analytic Data Set Programming

The [Mental Health Research Network (MHRN)](http://hcsrn.org/mhrn/en/) Suicide Risk Prediction Model (SRPM) encompasses the following major programming tasks:

1. Identify denominator (code written in [Base SAS®](http://www.sas.com/en_us/software/base-sas.html))
    1. Recommended: Perform quality checks on [Patient Health Questionnaire (PHQ-9)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1495268/) data (code written in Base SAS)
2. **Create analytic data set (code written in Base SAS)**
3. Implement model (code written in [R](https://www.r-project.org/))

In addition to this README, the srpm-analytic repository contains a set of basic descriptive statistics (SRPM_ANALYTIC_DESC_STATS.xlsx) about the MHRN data set that served as input for the modeling referenced in step 3 above. This repository also contains the following materials that were used to construct the analytic data set for use in modeling.

* **Main SAS program:** SRPM_ANALYTIC_MASTER.sas
    * **Details:** 
	    * Developed in SAS 9.4 for use in the [HCSRN VDW](http://www.hcsrn.org/en/Tools%20&%20Materials/VDW/) programming environment
		* Note: The master program and some subroutines include a few hard-coded date references that were applicable to the original MHRN study timeline. Those dates were 01JAN2004 (five years prior to original study period) and 30SEP2015 (end of original study period + 90 days of allowed follow-up). These sections of code may need to be modified per local IRB approval.
    * **Purpose:** Perform overarching setup and call subroutines designed to construct the final analytic data set for use in MHRN SRPM modeling.
    * **Dependencies:** 
		* StdVars.sas
		* Local modifications in introductory edit section
		* Subroutines in /PROGRAMS subdirectory (described below)
		* Contents of /INPUT subdirectory (described below)
		* SRPM_DENOM_FULL_SITE.sas7bdat
            * This data set should have been produced by SRPM_DENOM.sas and stored in the accompanying /LOCAL subdirectory. More information available in the [MHResearchNetwork/sprm-denom](https://github.com/MHResearchNetwork/srpm-denom) repository.
		    * Note: SITE = local site abbreviation as implemented in VDW StdVars &_siteabbr macro variable
		* PHQ9_CESR_PRO.sas7bdat
		    * This data set must be created from local PHQ-9 item-level response data and stored in a location accessible to the program.
            * The required data elements, shown below in Table 1, represent a simplified version of the Kaiser Permanente CESR data model PRO_SURVEY_RESPONSES table (PRO = Patient Reported Outcomes). 			
    * **Output files:**
        * /LOCAL/SRPM_PHQ9_QA_SITE.log – SAS log file
        * /SHARE/SRPM_PHQ9_QA_SITE.pdf – Table for local review. Small cell sizes suppressed per local implementation of VDW StdVars &lowest_count macro variable.
* **Subdirectory /PROGRAMS:** Stores the following SAS subroutines:
	*	SRPM_ANALYTIC_DENOM.sas - Prepare temporary visit, person-date, and person denominator data sets for use in creation of final analysis data set.
	*	SRPM_ANALYTIC_DEM_CEN.sas - Pull variables needed for demographic and census covariates.
	*	SRPM_ANALYTIC_ENROLL.sas - Prepare enrollment-related variables for each person-date.
	*	SRPM_ANALYTIC_DX_SUBSET.sas - Pull all diagnoses for underlying person denominator during study timeframe to save time running against VDW_DX in later queries.
	*	SRPM_ANALYTIC_CHARLSON.sas - Pull Charlson comorbidity score and related indicators for year prior to each index visit.
	*	SRPM_ANALYTIC_MH_DX.sas - Check for diagnoses of various MH conditions at/prior to index.
	*	SRPM_ANALYTIC_DELIVERY.sas - Pull indicators for infant delivery within specified timeframe around index date.
	*	SRPM_ANALYTIC_MH_RX.sas - Check for relevant MH Rx fills prior to index visit.
	*	SRPM_ANALYTIC_MH_UTE.sas - Identify MH-related utilization prior to index visit.
	*	SRPM_ANALYTIC_SII_PRE.sas - Determine whether each person had history of self-inflicted injury prior to index visit.
	*	SRPM_ANALYTIC_ITEM9_INDEX.sas - Identify best PHQ item #9 scores for index visit.
	*	SRPM_ANALYTIC_ITEM18_INDEX.sas - Obtain latest non-missing score on index visit date for PHQ items #1 through #8.
	*	SRPM_ANALYTIC_ITEM9_PRE.sas - Obtain up to 3 PHQ #9 scores/dates prior to index visit.
	*	SRPM_ANALYTIC_DEATHS.sas - Determine if, when, and why each person died.
	*	SRPM_ANALYTIC_CENSOR.sas - Calculate censoring dates for suicide attempts and deaths.
	*	SRPM_ANALYTIC_ATT_POST.sas - Determine whether each person attempted suicide post-index.
	*	SRPM_ANALYTIC_COMBINE.sas - Combine all temporary data sets into final analytic data set.
	*	SRPM_ANALYTIC_SUMMARY.sas - Generate descriptive statistics about final analytic data set.
* **Subdirectory /INPUT:** Stores the following files required as input to various subroutines:
	* SRPM_DX_LIST.txt: Mental health–related diagnosis codes
	* DELIVERY_DX_LIST.sas7bdat: Diagnosis codes indicative of live births
	* DELIVERY_PX_LIST.sas7bdat: Procedure codes indicative of live births
	* MHRN2_NDC2015.sas7bdat: NDC codes for mental health drugs
* **Subdirectory /TEMP:** Stores the following temporary SAS data sets generated by subroutines, retained for use in construction of final analytic data set:
	*	index_visit.sas7bdat
	*	people.sas7bdat
	*	person_dates.sas7bdat
	*	demog.sas7bdat
	*	census.sas7bdat
	*	enr_subset.sas7bdat
	*	enr_index.sas7bdat
	*	enr_pre.sas7bdat
	*	enr_post.sas7bdat
	*	dx_subset.sas7bdat
	*	charlson.sas7bdat
	*	mh_dx.sas7bdat
	*	delivery.sas7bdat
	*	mh_rx.sas7bdat
	*	mh_ute.sas7bdat
	*	sii_pre.sas7bdat
	*	item9_index.sas7bdat
	*	item18_index.sas7bdat
	*	item9_pre.sas7bdat
	*	deaths.sas7bdat
	*	censor.sas7bdat
	*	att_post.sas7bdat
* **Subdirectory /LOCAL:** Stores the following output files for local review:
	* SRPM_ANALYTIC_SITE.xml - Descriptive statistics about analytic data set
	* SRPM_ANALYTIC_SITE.html - SAS PROC CONTENTS output for analytic data set
* **Subdirectory /SHARE:** Stores analytic data set, SRPM_ANALYTIC_SITE.sas7bdat (originally intended to be shared with lead programming site)

The basic procedure to generate the SRPM analytic data set is as follows:

1. Prepare the PHQ9_CESR_PRO SAS data set as specified above and in Table 1 below.
2. Extract repository contents to local directory of choice.
3. Open SRPM_ANALYTIC_MASTER.sas and complete initial %include and %let statements as directed in program header. As described in the program header, you **always** need to run lines 1–131 of the MASTER program to establish necessary parameters before running any subroutines.
4. The rest of the MASTER program consists of calls to subroutines stored in the /PROGRAMS subdirectory.
	* Each subroutine checks to see if required input data sets are available in the expected locations. The subroutine will stop running and generate an error message if required data sets are not available.
	* Each subroutine also checks to see if intended output data set has already been generated and stored in /TEMP. If the data set already exists, a warning message will be written to the log, and the subroutine will stop executing.
		* Note: The warning message directs the user to manually delete the output data set if s/he wishes to recreate it. This is intended to prevent accidentally resubmitting a subroutine and writing over a data set that took a long time to create!
5. After successfully executing all subroutines, make sure that the aforementioned SAS data set and HTML/XML files have been created in the /SHARE and /LOCAL subfolders, respectively.
6. Review the contents of the /LOCAL subfolder to look for errors or issues before proceeding to modeling.

**Table 1. PHQ9_CESR_PRO data dictionary**

Name | Type | Description
--- | --- | ---
MRN | Character | Patient-level identifier, for use in linking to VDW-based denominator
QUESTION_ID | Character | PHQ item-level identifier, for use in differentiating between items 1–9. Valid values vary by site. Can be set to FLO_MEAS_ID or other Epic/Clarity-based differentiator if appropriate. Programmer will need to know which value(s) correspond to item #9 specifically.
RESPONSE_DATE | SAS date | Date of PHQ response (e.g., Clarity PAT_ENC.CONTACT_DATE if PHQ data are sourced from Epic)
RESPONSE_TIME | SAS datetime | Date/time of PHQ-9 response (e.g., Clarity PAT_ENC.ENTRY_TIME or IP_FLWSHT_MEAS.RECORDED_TIME). For use in selecting most recent available score.
RESPONSE_TEXT | Character | PHQ item score. Valid values are 0, 1, 2, 3, and blank (' ').
ENC_ID | Character or numeric, per local VDW specifications | VDW-based encounter ID, if already linked to PHQ response data. If unavailable, set to blank (' ') if your VDW ENC_ID is a character variable or null (.) if numeric.
PROVIDER | Character | Provider identifier, for use in linking to VDW-based denominator. If PHQ data are sourced from Epic, this field can be set to Clarity PAT_ENC.VISIT_PROV_ID assuming that ID can be linked directly to VDW ENCOUNTER.PROVIDER.
