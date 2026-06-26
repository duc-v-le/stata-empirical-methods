*==============================================================================
* 00_run_all.do  —  master script: runs the whole Stata portfolio in order.
*------------------------------------------------------------------------------
* Usage (run from the repository root):
*   GUI:   do 00_run_all.do
*   Batch: /Applications/StataNow19SE/StataSE19.app/Contents/MacOS/stata-se -b do 00_run_all.do
*------------------------------------------------------------------------------
* Each script writes its own log to logs/ and any tables/figures to output/.
*==============================================================================
version 17
clear all
set more off

do 01_basics.do
do 02_data_management.do
do 03_regression.do
do 04_panel_did_eventstudy.do
do 05_timeseries.do
do 06_import_public_data.do
do 07_iv_2sls.do
do 08_logit_probit.do
do 09_staggered_did_csdid.do
do 10_rdd_regression_discontinuity.do
do 11_synthetic_control.do
do 12_dynamic_panel_gmm.do

display "============================================"
display " ALL SCRIPTS FINISHED — see logs/ and output/"
display "============================================"
