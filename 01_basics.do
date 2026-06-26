*==============================================================================
* 01_basics.do  —  Stata fundamentals for applied economists
*------------------------------------------------------------------------------
* Run:  from the repository root, in Stata:  do 01_basics.do
* Batch: stata-se -b do 01_basics.do
*==============================================================================
version 17                      // write code against a fixed language version
clear all
set more off                    // don't pause for --more-- in long output
set linesize 90

capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/01_basics.log", replace text

*------------------------------------------------------------------------------
* 1. Load data. sysuse loads datasets shipped with Stata (works offline).
*------------------------------------------------------------------------------
sysuse auto, clear              // 1978 automobile data (74 cars)
describe                        // structure: variables, types, labels  (~ R str())
codebook mpg foreign, compact   // quick audit of a few variables
list make price mpg in 1/5      // peek at rows  (~ head())

*------------------------------------------------------------------------------
* 2. Summarize / explore.
*------------------------------------------------------------------------------
summarize                       // means, sd, min, max for all numeric vars
summarize price, detail         // percentiles, skew/kurtosis
tabulate foreign                // one-way frequencies
tabulate foreign rep78, row     // two-way, with row percentages
bysort foreign: summarize mpg   // grouped summary (~ groupby().describe())

*------------------------------------------------------------------------------
* 3. Create & transform variables.
*    generate = new var; replace = overwrite; egen = "extended" generate.
*------------------------------------------------------------------------------
generate gpm = 1/mpg                       // gallons per mile
label variable gpm "Gallons per mile"
generate price_k = price/1000
generate byte expensive = price > 6000     // boolean -> 0/1 indicator
egen mpg_z = std(mpg)                       // standardized mpg
egen price_mean_by_for = mean(price), by(foreign)   // group mean (window fn)

* Conditional logic: replace ... if
generate size_class = "small"
replace  size_class = "large" if weight > 3500

* Missing values: Stata stores numeric missing as "." (sorts as +infinity).
codebook rep78                              // note the 5 missing values
count if missing(rep78)

*------------------------------------------------------------------------------
* 4. Labels make output self-documenting (a Stata habit worth keeping).
*------------------------------------------------------------------------------
label define yesno 0 "No" 1 "Yes"
label values expensive yesno
tabulate expensive

*------------------------------------------------------------------------------
* 5. A couple of graphs, exported to disk (no display needed in batch).
*------------------------------------------------------------------------------
histogram price, frequency title("Distribution of price")
graph export "output/01_hist_price.png", replace width(1200)

twoway (scatter price weight) (lfit price weight), ///
    title("Price vs. weight with linear fit") legend(off)
graph export "output/01_scatter_price_weight.png", replace width(1200)

*------------------------------------------------------------------------------
* 6. Save a cleaned copy (Stata's native .dta format).
*------------------------------------------------------------------------------
save "output/auto_clean.dta", replace

log close
display "01_basics.do finished OK"
