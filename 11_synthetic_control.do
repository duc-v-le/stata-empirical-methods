*==============================================================================
* 11_synthetic_control.do  —  synthetic control method (Abadie et al.)
*------------------------------------------------------------------------------
* One treated unit, many controls. We build a "synthetic" version of the treated
* unit as a weighted average of controls that matches its PRE-treatment path,
* then read the treatment effect as the post-treatment gap between the two.
*
* Simulates 20 units x 30 periods; unit 1 is treated from t = 21 with a true
* effect of +3. A factor structure makes a good synthetic control feasible.
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 2020
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/11_synthetic_control.log", replace text

*------------------------------------------------------------------------------
* 1. Build the panel (factor model: shared time factors x unit-specific loadings).
*------------------------------------------------------------------------------
set obs 20
generate id = _n
generate u1 = runiform()                 // loading on factor 1 (fixed within unit)
generate u2 = runiform()                 // loading on factor 2
expand 30
bysort id: generate t = _n               // 1..30
generate f1 = sin(t/3)                   // common factors (functions of time)
generate f2 = t/30
generate y = 5 + 3*u1*f1 + 4*u2*f2 + rnormal(0,0.3)
replace  y = y + 3 if id==1 & t>20       // TRUE post-treatment effect = +3 on unit 1
label variable y "Outcome"

xtset id t                               // declare the panel

*------------------------------------------------------------------------------
* 2. Fit the synthetic control for unit 1 (treatment starts t = 21). We save the
*    treated/synthetic paths with keep(), then draw a COLORED version of them
*    (synth's built-in `fig` is monochrome).
*------------------------------------------------------------------------------
synth y y(5) y(10) y(15) y(20) u1 u2, ///
    trunit(1) trperiod(21) keep("output/synth_results.dta", replace)

preserve
    use "output/synth_results.dta", clear
    keep if !missing(_time)
    twoway (line _Y_treated   _time, lcolor(navy)      lwidth(medthick)) ///
           (line _Y_synthetic _time, lcolor(cranberry) lwidth(medthick) lpattern(dash)), ///
        xline(20.5, lpattern(dash) lcolor(gs10)) ///
        legend(order(1 "Treated unit" 2 "Synthetic control") rows(1) position(6)) ///
        title("Synthetic control: treated unit vs. its synthetic") ///
        xtitle("t") ytitle("Outcome")
    graph export "output/11_synth_path.png", replace width(1400)
restore

*------------------------------------------------------------------------------
* 3. Inference by placebo: re-assign treatment to each control unit in turn and
*    compare the treated unit's gap to the placebo distribution (synth_runner).
*------------------------------------------------------------------------------
synth_runner y y(5) y(10) y(15) y(20) u1 u2, ///
    trunit(1) trperiod(21) gen_vars

* Colored placebo "gap" plot: each control gap in light gray, the treated gap bold.
* synth_runner's gen_vars stores each unit's gap in `effect'.
levelsof id if id!=1, local(donors)
local plots ""
foreach d of local donors {
    local plots `plots' (line effect t if id==`d', lcolor(gs13) lwidth(vthin))
}
twoway `plots' (line effect t if id==1, lcolor(cranberry) lwidth(thick)), ///
    yline(0, lcolor(gs9)) xline(20.5, lpattern(dash) lcolor(gs10)) legend(off) ///
    title("Placebo gaps: treated unit (bold) vs. control units") ///
    xtitle("t") ytitle("Gap (treated - synthetic)")
graph export "output/11_synth_placebo.png", replace width(1400)

log close
display "11_synthetic_control.do finished OK"
