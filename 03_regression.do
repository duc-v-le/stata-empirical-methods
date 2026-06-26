*==============================================================================
* 03_regression.do  —  OLS, robust SE, factor variables, interactions,
*                      marginal effects, postestimation, publication tables
*==============================================================================
version 17
clear all
set more off
set linesize 90
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/03_regression.log", replace text

sysuse auto, clear
generate weight_t = weight/1000          // weight in 1000s of lbs
label variable weight_t "Weight (1000 lbs)"
label variable mpg "Mileage (mpg)"
label variable foreign "Foreign"

*------------------------------------------------------------------------------
* 1. OLS with heteroskedasticity-robust standard errors.
*    i.foreign = factor (dummy); c.var = continuous; ## = full interaction.
*------------------------------------------------------------------------------
eststo clear
eststo m1: regress price mpg weight_t, vce(robust)
eststo m2: regress price mpg weight_t i.foreign, vce(robust)
eststo m3: regress price c.mpg##c.weight_t i.foreign, vce(robust)

* Print a comparison table to the log.
esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) b(%9.2f) ///
    r2 label mtitles("Base" "+Foreign" "+Interaction") ///
    title("Determinants of car price")

* Export the same table to LaTeX and CSV (publication-ready deliverables).
esttab m1 m2 m3 using "output/03_regression_table.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) b(%9.2f) r2 label booktabs ///
    mtitles("Base" "+Foreign" "+Interaction") ///
    title("Determinants of car price\label{tab:price}")
esttab m1 m2 m3 using "output/03_regression_table.csv", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) r2 label plain

*------------------------------------------------------------------------------
* 2. Marginal effects (margins) — interpret models on the outcome scale.
*------------------------------------------------------------------------------
quietly regress price c.mpg##c.weight_t i.foreign, vce(robust)
margins, dydx(mpg)                       // average marginal effect of mpg
margins foreign                          // predicted price by foreign status
margins, dydx(mpg) at(weight_t=(2 3 4))  // how the mpg slope varies with weight

*------------------------------------------------------------------------------
* 3. Postestimation diagnostics.
*------------------------------------------------------------------------------
quietly regress price mpg weight_t i.foreign
test mpg weight_t                        // joint F-test (both = 0)
estat hettest                            // Breusch-Pagan heteroskedasticity test
estat vif                                // variance inflation (multicollinearity)
predict yhat                             // fitted values
predict ehat, residuals                  // residuals
rvfplot, yline(0) title("Residual vs. fitted")
graph export "output/03_rvfplot.png", replace width(1200)

log close
display "03_regression.do finished OK"
