*==============================================================================
* install_packages.do  —  one-shot installer for this portfolio's dependencies
*------------------------------------------------------------------------------
* WHAT: installs the community (SSC) packages that the .do files in
*       this repository rely on. Base Stata covers everything else.
*
* RUN (once per machine / user):
*   GUI:    do packages/install_packages.do
*   Batch:  /Applications/StataNow19SE/StataSE19.app/Contents/MacOS/stata-se \
*               -b do packages/install_packages.do
*
* NOTES:
*   - Needs an internet connection (SSC = the Boston College RePEc archive).
*   - Order matters: ftools and require are dependencies of reghdfe, so they
*     go first. ", replace" makes the script safe to re-run (idempotent).
*   - See PACKAGES.md (same folder) for what each package does and why.
*==============================================================================
version 17
set more off

* point Stata at SSC explicitly (this is the default, shown for clarity)
* net set ado SITE          // <- leave commented; only if redirecting install dir

display as text "Installing SSC dependencies ..."

* --- core (scripts 01-06) ---
ssc install ftools,    replace  // fast data ops; dependency of reghdfe
ssc install require,   replace  // version checker; dependency of recent reghdfe
ssc install reghdfe,   replace  // high-dimensional fixed-effects regression
ssc install estout,    replace  // publication tables (provides esttab/estadd)
ssc install coefplot,  replace  // coefficient / event-study plots

* --- advanced (scripts 07-09) ---
ssc install ranktest,  replace  // rank/weak-IV tests; dependency of ivreg2
ssc install ivreg2,    replace  // IV/2SLS/GMM engine; dependency of ivreghdfe
ssc install ivreghdfe, replace  // IV/2SLS with high-dimensional fixed effects
ssc install drdid,     replace  // doubly-robust DiD; dependency of csdid
ssc install csdid,     replace  // Callaway-Sant'Anna staggered-adoption DiD

* --- regression discontinuity (script 10) ---
ssc install rdrobust,  replace  // local-polynomial RD estimation, bw, rdplot
ssc install lpdensity, replace  // dependency of rddensity
ssc install rddensity, replace  // RD manipulation / density-continuity test

* --- synthetic control (script 11) ---
ssc install synth,     replace  // Abadie et al. synthetic control
ssc install distinct,  replace  // dependency of synth_runner
* synth_runner is NOT on SSC — install from its GitHub repo:
net install synth_runner, replace ///
    from("https://raw.githubusercontent.com/bquistorff/synth_runner/master/")

*------------------------------------------------------------------------------
* Verify every package is now callable; stop with an error if any is missing.
*------------------------------------------------------------------------------
local missing ""
foreach p in ftools require reghdfe esttab coefplot ///
             ranktest ivreg2 ivreghdfe drdid csdid ///
             rdrobust rddensity lpdensity synth synth_runner distinct {
    capture which `p'
    if _rc {
        local missing "`missing' `p'"
        display as error "  MISSING: `p' (rc=" _rc ")"
    }
    else display as result "  OK: `p'"
}
if "`missing'" != "" {
    display as error "Some packages failed to install:`missing'"
    error 111
}
display as result "All dependencies installed and verified."
