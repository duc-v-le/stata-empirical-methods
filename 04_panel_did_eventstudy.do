*==============================================================================
* 04_panel_did_eventstudy.do  —  panel FE, difference-in-differences,
*                                two-way FE with reghdfe, dynamic event study
*------------------------------------------------------------------------------
* Builds a SYNTHETIC firm-by-year panel (fully reproducible, no external data),
* then runs the canonical causal-inference workflow of applied empirical work.
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 90210
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/04_panel_did_eventstudy.log", replace text

*------------------------------------------------------------------------------
* 1. Simulate a panel: 150 firms x 12 years (2010-2021).
*    Treated firms (half) get a +1.5 effect starting in 2015 that grows over time.
*------------------------------------------------------------------------------
set obs 150
generate firm    = _n
generate fe_firm = rnormal(0, 2)         // firm fixed effect
generate byte treat = mod(firm, 2)==0    // half the firms are treated
expand 12
bysort firm: generate year = 2009 + _n   // 2010..2021
generate byte post = year >= 2015        // treatment turns on in 2015
generate rel = year - 2015               // event time relative to treatment

generate year_fe = 0.3*(year-2015) + 0.5*sin(year)   // common time shocks
generate tau = 0
replace  tau = 0.5*(rel+1) if treat==1 & year>=2015  // dynamic treatment effect
generate y = 3 + fe_firm + year_fe + tau + rnormal(0,1)
label variable y "Outcome"

xtset firm year                          // declare panel structure
xtdescribe

*------------------------------------------------------------------------------
* 2. Pooled OLS vs. fixed-effects DiD (the 2x2 interaction).
*------------------------------------------------------------------------------
eststo clear
eststo ols: regress y i.treat##i.post, vce(cluster firm)
eststo fe:  xtreg   y i.treat##i.post, fe vce(cluster firm)
* Under firm FE the time-invariant treat main effect drops; the DiD estimate
* is the 1.treat#1.post coefficient (true value = average post effect).

*------------------------------------------------------------------------------
* 3. Two-way fixed effects with reghdfe (absorb firm AND year FE).
*------------------------------------------------------------------------------
eststo twfe: reghdfe y 1.treat#1.post, absorb(firm year) vce(cluster firm)

esttab ols fe twfe, se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) ///
    mtitles("Pooled OLS" "Firm FE" "Two-way FE") ///
    keep(1.treat#1.post) label title("Difference-in-differences estimates")
esttab ols fe twfe using "output/04_did_table.tex", replace booktabs ///
    se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) keep(1.treat#1.post) label ///
    mtitles("Pooled OLS" "Firm FE" "Two-way FE") title("DiD estimates")

*------------------------------------------------------------------------------
* 4. Dynamic event study: treatment-effect path by event time.
*    The full set of event-time dummies sums to the (time-invariant) treated
*    indicator, which the firm FE absorbs, so one dummy must be dropped. We omit
*    t = -1 (the eve of treatment) as the single reference period, so every other
*    coefficient is read relative to it. Leads should sit near zero (no pre-trend);
*    lags trace the dynamic effect.
*------------------------------------------------------------------------------
forvalues k = -5/6 {
    if `k'==-1 continue                    // omit t = -1: the single reference period
    local j = `k' + 6                      // 1..12 index -> a legal variable name
    generate evt`j' = (treat==1 & rel==`k')
    label variable evt`j' "t = `k'"
}
reghdfe y evt*, absorb(firm year) vce(cluster firm)

coefplot, keep(evt*) vertical yline(0) xline(4.5, lpattern(dash)) ///
    coeflabels(evt1="-5" evt2="-4" evt3="-3" evt4="-2" evt6="0" evt7="1" evt8="2" ///
               evt9="3" evt10="4" evt11="5" evt12="6") ///
    title("Event-study estimates (ref: t = -1)") ///
    xtitle("Event time (years relative to treatment)") ///
    ytitle("Effect on outcome")
graph export "output/04_event_study.png", replace width(1400)

log close
display "04_panel_did_eventstudy.do finished OK"
