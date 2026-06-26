*==============================================================================
* 10_rdd_regression_discontinuity.do  —  sharp regression discontinuity (RD)
*------------------------------------------------------------------------------
* Units with running variable x >= 0 get treated. The outcome is a smooth
* function of x with a JUMP of 2.0 at the cutoff = the treatment effect.
* Uses Calonico-Cattaneo-Titiunik local-polynomial estimation (rdrobust).
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 1010
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/10_rdd_regression_discontinuity.log", replace text

set obs 3000
generate x = runiform(-1,1)              // running variable; cutoff at 0
generate byte d = (x >= 0)               // sharp assignment
generate y = 3 + 1.5*x + 0.5*x^2 + 2.0*d + rnormal(0,0.5)  // TRUE jump = 2.0
label variable x "Running variable"
label variable y "Outcome"

*------------------------------------------------------------------------------
* 1. RD point estimate: local-linear fit each side of the cutoff, MSE-optimal
*    bandwidth, bias-corrected robust confidence interval.
*------------------------------------------------------------------------------
rdrobust y x, c(0)

*------------------------------------------------------------------------------
* 2. Data-driven bandwidth selection (what rdrobust chose, and alternatives).
*------------------------------------------------------------------------------
rdbwselect y x, c(0) all

*------------------------------------------------------------------------------
* 3. The annotated RD picture. Binned means (rdplot genvars) + a local fit each
*    side, then three annotations that make the estimate legible:
*      - open dots at the two one-sided limits at the cutoff;
*      - a grey double arrow, offset just right of the cutoff, spanning the
*        estimated jump and labelled with rdrobust's tau-hat (so the picture
*        reports the SAME number as the results table); short dashed leaders
*        link the two limit dots to the arrow's ends;
*      - the control fit extrapolated across c as the "no-treatment"
*        counterfactual (dashed) -- what the treated units would have done.
*------------------------------------------------------------------------------
rdplot y x, c(0) genvars hide
egen _bin = tag(rdplot_id)

* local fit each side (quadratic, matching the smooth DGP) + the two limits at c
quietly regress y c.x##c.x if x<0
predict double _fit_l if x<0                       // control fit
predict double _cf    if inrange(x,0,0.45)         // control fit extended past c
local yL = _b[_cons]                               // control limit  lim_{x up c}
quietly regress y c.x##c.x if x>=0
predict double _fit_r if x>=0                       // treated fit
local yR = _b[_cons]                               // treated limit  lim_{x down c}

* headline estimate (rdrobust local-linear) drives the arrow + its label
quietly rdrobust y x, c(0)
local tau  = e(tau_cl)
local yT   = `yL' + `tau'                           // treated limit implied by tau-hat
local taus : display %4.3f `tau'
local ymid = (`yL' + `yT')/2

twoway ///
    (scatter rdplot_mean_y rdplot_mean_x if rdplot_mean_x<0  & _bin, mcolor(midblue%35)   msize(small)) ///
    (scatter rdplot_mean_y rdplot_mean_x if rdplot_mean_x>=0 & _bin, mcolor(cranberry%35) msize(small)) ///
    (line _fit_l x if x<0,  sort lcolor(midblue)   lwidth(medthick)) ///
    (line _fit_r x if x>=0, sort lcolor(cranberry) lwidth(medthick)) ///
    (line _cf    x if inrange(x,0,0.45), sort lcolor(midblue%55) lpattern(dash) lwidth(medium)) ///
    (pci `yT' 0 `yT' 0.24, lcolor(gs9) lpattern(dash) lwidth(thin)) ///
    (pci `yL' 0 `yL' 0.24, lcolor(gs9) lpattern(dash) lwidth(thin)) ///
    (pcarrowi `yL' 0.24 `yT' 0.24, lcolor(gs9) lwidth(medthick) mcolor(gs9) barbsize(2.2)) ///
    (pcarrowi `yT' 0.24 `yL' 0.24, lcolor(gs9) lwidth(medthick) mcolor(gs9) barbsize(2.2)) ///
    (scatteri `yL' 0 `yT' 0, mcolor(white) mlcolor(black) mlwidth(thin) msymbol(O) msize(medium)) ///
    , ///
    xline(0, lpattern(dash) lcolor(gs10)) ///
    text(`ymid' 0.27 "{&tau} = `taus'", color(gs9) place(e) size(medium)) ///
    legend(order(3 "Control fit (x < c)" 4 "Treated fit (x {&ge} c)" ///
                 5 "Counterfactual (no treatment)") ///
           cols(1) position(11) ring(0) size(small) region(lstyle(none) fcolor(none))) ///
    title("Sharp RD: the outcome jumps at the cutoff") ///
    subtitle("binned means + local fit each side; grey arrow = rdrobust estimate") ///
    xtitle("Running variable  X   (sharp cutoff at c)") ytitle("Outcome  Y") ///
    xlabel(-1 -.5 0 "c = 0" .5 1)
graph export "output/10_rdplot.png", replace width(1600)
drop _fit_l _fit_r _cf _bin

*------------------------------------------------------------------------------
* 4. Manipulation test: is the density of x continuous at the cutoff?
*    (A jump would suggest units sorted around the threshold — an RD red flag.)
*    Here x is uniform, so the test should NOT reject.
*------------------------------------------------------------------------------
rddensity x, c(0)

*------------------------------------------------------------------------------
* 5. Export a compact results table for the reference. rdplot's genvars call
*    overwrote e(), so re-fit quietly to recover the rdrobust/rddensity scalars.
*------------------------------------------------------------------------------
quietly rdrobust y x, c(0)
local tau = e(tau_cl)
local cil = e(ci_l_rb)
local cir = e(ci_r_rb)
local pv  = e(pv_rb)
quietly rddensity x, c(0)
local mpv = e(pv_q)
local ptxt = cond(`pv'<0.001, "\(<\)0.001", string(`pv',"%5.3f"))

capture file close rt
file open rt using "output/10_rd_table.tex", write replace
file write rt "\begin{table}[htbp]\centering" _n
file write rt "\caption{Sharp RD estimate vs.\ the true jump (\(\tau=2.0\))}" _n
file write rt "\begin{tabular}{lc}" _n "\toprule" _n
file write rt " & Estimate \\" _n "\midrule" _n
file write rt "RD effect (\(\hat\tau\)) & " %5.3f (`tau') " \\" _n
file write rt "Robust 95\% CI & [" %5.3f (`cil') ", " %5.3f (`cir') "] \\" _n
file write rt "Robust \(p\)-value & `ptxt' \\" _n
file write rt "\addlinespace" _n
file write rt "Manipulation test \(p\) (\pkg{rddensity}) &" %5.3f (`mpv') " \\" _n
file write rt "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close rt

log close
display "10_rdd_regression_discontinuity.do finished OK"
