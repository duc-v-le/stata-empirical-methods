*==============================================================================
* 09_staggered_did_csdid.do  —  staggered-adoption DiD (Callaway & Sant'Anna)
*------------------------------------------------------------------------------
* When units are treated at DIFFERENT times, two-way FE DiD can be biased
* (the "forbidden comparison" / negative-weighting problem). Callaway &
* Sant'Anna (2021) estimate clean group-time ATTs and aggregate them.
*
* Simulates 3 cohorts: first-treated in 2014, in 2017, and never-treated.
* True effect is 0 pre-treatment and grows after each cohort's own start.
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 555
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/09_staggered_did_csdid.log", replace text

*------------------------------------------------------------------------------
* 1. Build a staggered panel: 300 units x 12 years (2010-2021).
*    gvar = year of first treatment; 0 = never treated (csdid convention).
*------------------------------------------------------------------------------
set obs 300
generate id = _n
generate g = 0                            // never-treated by default
replace  g = 2014 if id <= 100            // early cohort
replace  g = 2017 if id > 100 & id <= 200 // late cohort
generate u_id = rnormal()*1.5             // unit fixed effect
expand 12
bysort id: generate year = 2009 + _n      // 2010..2021

generate att = 0
replace  att = 0.4*(year - g + 1) if g>0 & year>=g   // dynamic, grows post-onset
generate yr_fe = 0.2*(year-2015)          // common year trend
generate y = 3 + u_id + yr_fe + att + rnormal()
label variable y "Outcome"

tabulate g, missing                       // cohort sizes (in unit-years)

*------------------------------------------------------------------------------
* 2. Callaway & Sant'Anna estimator (doubly robust). No covariates here.
*------------------------------------------------------------------------------
csdid y, ivar(id) time(year) gvar(g) method(dripw)

*------------------------------------------------------------------------------
* 3. Aggregations of the group-time ATTs.
*------------------------------------------------------------------------------
estat simple                              // single overall ATT
matrix _Tsimple = r(table)                // capture the aggregate ATT now, before
                                          //   estat group/event overwrite r(table)
estat group                               // ATT by treatment cohort
estat event                               // dynamic / event-study path (LAST, so
                                          //   csdid_plot below plots THIS)

*------------------------------------------------------------------------------
* 4. Event-study plot of the dynamic aggregation.
*    csdid_plot graphs the most recent estat aggregation -> run estat event last.
*------------------------------------------------------------------------------
csdid_plot, title("Callaway-Sant'Anna event study") ///
    ytitle("ATT") xtitle("Event time (years relative to treatment)")
graph export "output/09_csdid_event.png", replace width(1400)

*------------------------------------------------------------------------------
* 5. For contrast: the naive two-way FE estimate on the same data.
*    (Can be biased under staggered timing + dynamic effects — that's the point.)
*------------------------------------------------------------------------------
generate byte treated_now = (g>0 & year>=g)
reghdfe y treated_now, absorb(id year) vce(cluster id)

*------------------------------------------------------------------------------
* 6. Export a table contrasting the Callaway-Sant'Anna ATT with the naive TWFE
*    estimate (the bias this method removes).
*------------------------------------------------------------------------------
local twfe  = _b[treated_now]
local twse  = _se[treated_now]
local csatt = _Tsimple[1,1]
local csse  = _Tsimple[2,1]

capture file close ct
file open ct using "output/09_csdid_table.tex", write replace
file write ct "\begin{table}[htbp]\centering" _n
file write ct "\caption{Overall ATT: Callaway--Sant'Anna vs.\ naive two-way FE}" _n
file write ct "\begin{tabular}{lcc}" _n "\toprule" _n
file write ct "Estimator & ATT & Std.\ err. \\" _n "\midrule" _n
file write ct "Callaway--Sant'Anna (\pkg{csdid}) & " %5.3f (`csatt') " & " %5.3f (`csse') " \\" _n
file write ct "Naive two-way FE (\pkg{reghdfe}) & " %5.3f (`twfe') " & " %5.3f (`twse') " \\" _n
file write ct "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close ct

log close
display "09_staggered_did_csdid.do finished OK"
