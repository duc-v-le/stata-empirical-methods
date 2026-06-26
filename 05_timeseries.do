*==============================================================================
* 05_timeseries.do  —  tsset, lag/diff operators, autocorrelation,
*                      HAC (Newey-West) SE, and a simple event/break window
*------------------------------------------------------------------------------
* Simulates a monthly AR(1) series with a level shift in 2015m1.
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 4321
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/05_timeseries.log", replace text

*------------------------------------------------------------------------------
* 1. Build a monthly time series and declare it with tsset.
*------------------------------------------------------------------------------
set obs 120
generate t = _n
generate mdate = tm(2010m1) + t - 1      // Stata monthly date
format mdate %tm
tsset mdate                              // declare time-series structure

generate eps = rnormal(0,1)
generate y = eps in 1
replace  y = 0.6*L.y + eps in 2/L        // AR(1): recursion fills in order
replace  y = y + 3 if mdate >= tm(2015m1)  // structural level shift
label variable y "Simulated series"

*------------------------------------------------------------------------------
* 2. Time-series operators: L. (lag), D. (difference), F. (lead).
*------------------------------------------------------------------------------
generate dy   = D.y                      // first difference
generate y_l1 = L.y                      // first lag
summarize y dy

*------------------------------------------------------------------------------
* 3. Plots: the series and its autocorrelation function.
*------------------------------------------------------------------------------
tsline y, title("Monthly series with a 2015 level shift") ///
    tline(2015m1, lpattern(dash))
graph export "output/05_tsline.png", replace width(1400)

ac y, title("Autocorrelation function")
graph export "output/05_acf.png", replace width(1200)

*------------------------------------------------------------------------------
* 4. Regression with a lag + HAC (Newey-West) standard errors.
*------------------------------------------------------------------------------
newey y L.y, lag(3)                      // robust to serial correlation up to 3 lags

*------------------------------------------------------------------------------
* 5. Test the level break with an indicator (a mini event study).
*------------------------------------------------------------------------------
generate byte post = mdate >= tm(2015m1)
regress y L.y i.post, vce(robust)        // coefficient on post = estimated jump

log close
display "05_timeseries.do finished OK"
