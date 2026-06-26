*==============================================================================
* 12_dynamic_panel_gmm.do  —  dynamic panel data: Arellano-Bond &
*                             Blundell-Bond (system) GMM
*------------------------------------------------------------------------------
* A dynamic panel  y_it = rho*y_{i,t-1} + beta*x_it + alpha_i + e_it  has a
* built-in endogeneity: the lagged dependent variable is mechanically correlated
* with the unit effect alpha_i. Pooled OLS therefore OVERstates rho, and the
* within (FE) estimator UNDERstates it (Nickell bias, severe when T is small).
* Difference and system GMM instrument the lagged level with deeper lags and
* recover the truth. TRUE rho = 0.6, beta = 1.
*==============================================================================
version 17
clear all
set more off
set linesize 90
set seed 90210
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/12_dynamic_panel_gmm.log", replace text

*------------------------------------------------------------------------------
* 1. Simulate a dynamic panel: 500 firms; keep 12 periods after a burn-in so the
*    process has reached its stationary distribution.
*------------------------------------------------------------------------------
local N    = 500
local Tgen = 20
local Tkeep = 12
local rho  = 0.6
local beta = 1
set obs `N'
generate id = _n
generate alpha = rnormal()                 // unit (firm) fixed effect
expand `Tgen'
bysort id: generate t = _n
xtset id t
generate x   = 0.5*alpha + rnormal()       // regressor, correlated with alpha
generate eps = rnormal()
generate y = .
replace y = alpha + `beta'*x + eps if t==1            // starting value
forvalues s = 2/`Tgen' {                              // iterate the dynamics
    replace y = `rho'*L.y + `beta'*x + alpha + eps if t==`s'
}
drop if t <= `Tgen' - `Tkeep'              // burn-in: discard the early periods
bysort id (t): replace t = _n              // re-index time to 1..12
xtset id t

*------------------------------------------------------------------------------
* 2. The bias: pooled OLS (rho too high) vs. within/FE (rho too low).
*------------------------------------------------------------------------------
regress y L.y x, vce(cluster id)           // pooled OLS: rho biased UP
local rho_ols = _b[L.y]
local se_ols  = _se[L.y]
xtreg y L.y x, fe vce(cluster id)          // within: rho biased DOWN (Nickell)
local rho_fe = _b[L.y]
local se_fe  = _se[L.y]

*------------------------------------------------------------------------------
* 3. Arellano-Bond difference GMM and Blundell-Bond system GMM.
*    estat abond: AR(1) in the differenced errors SHOULD reject; AR(2) should NOT
*    -- the key check that the lagged-level moment conditions are valid.
*------------------------------------------------------------------------------
xtabond y x, lags(1) vce(robust)           // difference GMM (Arellano-Bond)
local rho_ab = _b[L.y]
local se_ab  = _se[L.y]
estat abond

xtdpdsys y x, lags(1) vce(robust)          // system GMM (Blundell-Bond)
local rho_bb = _b[L.y]
local se_bb  = _se[L.y]
estat abond

*------------------------------------------------------------------------------
* 4. Persistence rho across estimators (true rho = 0.6).
*------------------------------------------------------------------------------
display "rho:  OLS=" %5.3f `rho_ols' "  FE=" %5.3f `rho_fe' ///
        "  DiffGMM=" %5.3f `rho_ab' "  SysGMM=" %5.3f `rho_bb'

capture file close dp
file open dp using "output/12_dynpanel_table.tex", write replace
file write dp "\begin{table}[htbp]\centering" _n
file write dp "\caption{Dynamic panel: the persistence \(\rho\) (true \(\rho=0.6\))}" _n
file write dp "\begin{tabular}{lcccc}" _n "\toprule" _n
file write dp " & Pooled OLS & Within FE & Diff GMM & Sys GMM \\" _n "\midrule" _n
file write dp "\(\hat\rho\) (coef.\ on \(y_{t-1}\)) & " ///
    %5.3f (`rho_ols') " & " %5.3f (`rho_fe') " & " %5.3f (`rho_ab') " & " %5.3f (`rho_bb') " \\" _n
file write dp "(std.\ err.) & (" %5.3f (`se_ols') ") & (" %5.3f (`se_fe') ") & (" ///
    %5.3f (`se_ab') ") & (" %5.3f (`se_bb') ") \\" _n
file write dp "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close dp

log close
display "12_dynamic_panel_gmm.do finished OK"
