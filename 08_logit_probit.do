*==============================================================================
* 08_logit_probit.do  —  binary-outcome models and how to interpret them
*------------------------------------------------------------------------------
* Models the probability a car is foreign as a function of mpg, weight, price.
* The key lesson: logit/probit coefficients are NOT directly interpretable —
* use margins for average marginal effects and predicted probabilities.
*==============================================================================
version 17
clear all
set more off
set linesize 90
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/08_logit_probit.log", replace text

sysuse auto, clear
generate weight_t = weight/1000
generate price_k  = price/1000
label variable weight_t "Weight (1000 lbs)"
label variable price_k  "Price ($1000s)"

*------------------------------------------------------------------------------
* 1. Three ways to model a 0/1 outcome: LPM, logit, probit.
*------------------------------------------------------------------------------
eststo clear
eststo lpm:    regress foreign mpg weight_t price_k, vce(robust)   // linear prob.
eststo logit:  logit   foreign mpg weight_t price_k, vce(robust)
eststo probit: probit  foreign mpg weight_t price_k, vce(robust)
* NOTE: raw coefficients are on different scales — do NOT compare directly.
esttab lpm logit probit, b(%9.3f) se star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("LPM" "Logit" "Probit") label ///
    title("Coefficients differ by scale — compare marginal effects, not these")

*------------------------------------------------------------------------------
* 2. Odds ratios (logit) — a common reporting convention.
*------------------------------------------------------------------------------
logit foreign mpg weight_t price_k, or

*------------------------------------------------------------------------------
* 3. Average marginal effects — the comparable, interpretable quantities.
*    Logit and probit AMEs are typically very close.
*------------------------------------------------------------------------------
quietly logit foreign mpg weight_t price_k
margins, dydx(*) post
estimates store ame_logit
quietly probit foreign mpg weight_t price_k
margins, dydx(*) post
estimates store ame_probit
esttab ame_logit ame_probit, b(%9.4f) se ///
    mtitles("Logit AME" "Probit AME") title("Average marginal effects (compare these)")

*------------------------------------------------------------------------------
* 4. Predicted probabilities + a plot across the range of mpg.
*------------------------------------------------------------------------------
quietly logit foreign mpg weight_t price_k
margins, at(mpg=(12(4)40))
marginsplot, title("Predicted P(foreign) across mpg") ///
    ytitle("Predicted probability")
graph export "output/08_logit_pr.png", replace width(1300)

*------------------------------------------------------------------------------
* 5. In-sample fit: classification table and ROC area.
*------------------------------------------------------------------------------
quietly logit foreign mpg weight_t price_k
estat classification                     // sensitivity/specificity at p=0.5
lroc, nograph                            // area under ROC curve

log close
display "08_logit_probit.do finished OK"
