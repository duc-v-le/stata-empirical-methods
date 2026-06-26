*==============================================================================
* 06_import_public_data.do  —  getting public data INTO Stata
*------------------------------------------------------------------------------
* Empirical work often requires scraping publicly available data and
* cleaning it. This shows the three routes used in practice.
*==============================================================================
version 17
clear all
set more off
set linesize 90
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/06_import_public_data.log", replace text

*------------------------------------------------------------------------------
* (A) Round-trip a CSV to demonstrate import/export delimited (the CSV workhorses).
*     We write the built-in 'auto' data out and read it straight back — auto is just
*     a throwaway here, the point is the file I/O, not the data. varnames(1)=header.
*------------------------------------------------------------------------------
sysuse auto, clear
keep make price mpg foreign
export delimited using "output/_cars.csv", replace
clear
import delimited "output/_cars.csv", varnames(1) clear
describe
list in 1/3
erase "output/_cars.csv"

*------------------------------------------------------------------------------
* (B) Import a REAL public series: the U.S. unemployment rate (FRED: UNRATE).
*     PRIMARY route — Stata's native FRED importer, a live API call (the most
*     reproducible: no manual download step). It needs a free key, set ONCE with
*         set fredkey YOUR_KEY, permanently   (free key: fredaccount.stlouisfed.org)
*     The key then lives in the Stata config, never in this script. With no key
*     set we fall back to a CSV previously downloaded from FRED, so this always runs.
*------------------------------------------------------------------------------
capture import fred UNRATE, clear
if _rc == 0 {
    display "Live FRED API pull succeeded: " _N " observations."
    rename UNRATE unrate                     // the native importer keeps FRED's case
    generate mdate = mofd(daten)             // import fred already provides daten (%td)
}
else {
    display "No FRED key configured (rc = " _rc "); using the bundled CSV instead."
    import delimited "data/UNRATE.csv", varnames(1) clear
    rename observation_date datestr
    generate daten = date(datestr, "YMD")    // parse the YYYY-MM-DD string ourselves
    format daten %td
    generate mdate = mofd(daten)             // collapse to monthly
}
format mdate %tm
tsset mdate
summarize unrate
list datestr unrate in 1/3
list datestr unrate in -3/L                  // most recent observations

tsline unrate, title("U.S. unemployment rate (FRED: UNRATE)") ///
    ytitle("Percent") xtitle("")
graph export "output/06_unrate.png", replace width(1400)
save "output/fred_unrate.dta", replace
display "FRED UNRATE imported: " _N " monthly observations"

* To pull several series at once over a date window:
*   import fred UNRATE GDPC1, daterange(2000-01-01 .) aggregate(monthly)

log close
display "06_import_public_data.do finished OK"
