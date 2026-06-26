*==============================================================================
* 07_iv_2sls.do  —  instrumental variables / 2SLS, with diagnostics, and the
*                   high-dimensional-FE version (ivreghdfe)
*------------------------------------------------------------------------------
* Simulates an endogenous regressor x correlated with an unobserved confounder
* u; two valid instruments z1, z2 (independent of u). True slope on x is 2.0,
* so OLS should be biased and 2SLS should recover ~2.0.
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 1234
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/07_iv_2sls.log", replace text

set obs 5000
generate id = _n
generate z1 = rnormal()                  // instrument 1
generate z2 = rnormal()                  // instrument 2
generate u  = rnormal()                  // unobserved confounder
generate x  = 0.6*z1 + 0.5*z2 + 0.6*u + rnormal()   // endogenous regressor
generate e  = 0.6*u + rnormal()          // structural error (corr with x via u)
generate grp = mod(id,50) + 1            // 50 groups, for the FE demo
bysort grp (id): generate gfe = rnormal() if _n==1
bysort grp (id): replace   gfe = gfe[1]
generate y  = 1 + 2*x + e + gfe          // TRUE slope on x = 2

*------------------------------------------------------------------------------
* 1. OLS (biased) vs. 2SLS (base Stata: ivregress).
*------------------------------------------------------------------------------
eststo clear
eststo ols:  regress y x, vce(robust)                       // biased upward
eststo tsls: ivregress 2sls y (x = z1 z2), vce(robust) first // first-stage shown

*------------------------------------------------------------------------------
* 2. IV diagnostics — the standard validity checks for any IV design.
*------------------------------------------------------------------------------
estat firststage          // weak-instrument F (rule of thumb: > 10)
estat endogenous          // Durbin-Wu-Hausman: is x actually endogenous?
estat overid              // over-identification test (2 instruments, 1 endog var)

*------------------------------------------------------------------------------
* 2b. Efficient (two-step) GMM. 2SLS is GMM with a fixed weight matrix; `gmm` uses
*     the optimal heteroskedasticity-robust weight matrix, so it is more efficient
*     when errors are heteroskedastic. With homoskedastic errors (as here) it
*     essentially coincides with 2SLS; the over-id test is Hansen's J.
*------------------------------------------------------------------------------
ivregress gmm y (x = z1 z2), vce(robust)

*------------------------------------------------------------------------------
* 3. IV with high-dimensional fixed effects (ivreghdfe = ivreg2 + reghdfe).
*    Absorbs the group FE that base ivregress would need as dummies.
*------------------------------------------------------------------------------
eststo ivfe: ivreghdfe y (x = z1 z2), absorb(grp) vce(robust)

*------------------------------------------------------------------------------
* 4. Compare the slope on x across estimators.
*------------------------------------------------------------------------------
esttab ols tsls ivfe, b(%9.3f) se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(x) mtitles("OLS (biased)" "2SLS" "IV + FE") ///
    title("True slope on x = 2.0: OLS is biased, IV recovers it")
esttab ols tsls ivfe using "output/07_iv_table.tex", replace booktabs ///
    b(%9.3f) se star(* 0.10 ** 0.05 *** 0.01) keep(x) ///
    mtitles("OLS" "2SLS" "IV+FE") title("IV vs OLS")

*------------------------------------------------------------------------------
* 5. Export an IV-diagnostics table for the reference (re-fit quietly first; the
*    last active estimates above are the IV+FE model, not the plain 2SLS).
*------------------------------------------------------------------------------
quietly regress x z1 z2, vce(robust)
test z1 z2
local fsF = r(F)
quietly ivregress 2sls y (x = z1 z2), vce(robust)
quietly estat endogenous
local dwh  = r(r_score)
local dwhp = r(p_r_score)
quietly estat overid
local oj   = r(score)
local ojp  = r(p_score)
local dwhpt = cond(`dwhp'<0.001, "\(<\)0.001", string(`dwhp',"%5.3f"))
local ojpt  = string(`ojp',"%5.3f")

capture file close it
file open it using "output/07_iv_diag_table.tex", write replace
file write it "\begin{table}[htbp]\centering" _n
file write it "\caption{IV diagnostics (2SLS, heteroskedasticity-robust)}" _n
file write it "\begin{tabular}{lcc}" _n "\toprule" _n
file write it "Test & Statistic & \(p\) \\" _n "\midrule" _n
file write it "First-stage \(F\) (weak instruments) & " %6.1f (`fsF') " & --- \\" _n
file write it "Endogeneity: Durbin--Wu--Hausman (\(\chi^2_1\)) & " %6.1f (`dwh') " & `dwhpt' \\" _n
file write it "Overidentification: robust score (\(\chi^2_1\)) & " %5.2f (`oj') " & `ojpt' \\" _n
file write it "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close it

log close
display "07_iv_2sls.do finished OK"
