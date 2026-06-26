*==============================================================================
* 02_data_management.do  —  merge, reshape, collapse, dates, strings, dups
*==============================================================================
version 17
clear all
set more off
set linesize 90
capture log close
capture mkdir logs   // create the log folder if absent (gitignored)
log using "logs/02_data_management.log", replace text

*------------------------------------------------------------------------------
* 1. MERGE  (joins). Split auto into two files, then merge 1:1 on a key.
*------------------------------------------------------------------------------
sysuse auto, clear
keep make price mpg
save "output/_left.dta", replace

sysuse auto, clear
keep make weight foreign
save "output/_right.dta", replace

use "output/_left.dta", clear
merge 1:1 make using "output/_right.dta"
tabulate _merge                 // 3 = matched both; 1 = master only; 2 = using only
assert _merge==3                // sanity check the join is clean
drop _merge

* m:1 (many-to-one): a country-year panel picks up one GDP figure per country.
clear
input str3 country gdp
"USA" 21000
"CAN"  1700
"MEX"  1100
end
save "output/_gdp.dta", replace
clear
input str3 country int year
"USA" 2020
"USA" 2021
"CAN" 2020
"CAN" 2021
"MEX" 2020
"MEX" 2021
end
merge m:1 country using "output/_gdp.dta"   // each country's GDP fans out to its year rows
sort country year
list country year gdp _merge, sepby(country) noobs
drop _merge
erase "output/_gdp.dta"

* _merge values: an imperfect join shows 1 (master only), 2 (using only), 3 (matched).
clear
input str3 country pop
"USA" 331
"CAN"  38
"MEX" 126
end
save "output/_pop.dta", replace
clear
input str3 country gdp
"CAN"  1700
"MEX"  1100
"BRA"  1600
end
merge 1:1 country using "output/_pop.dta"   // master {CAN,MEX,BRA} vs using {USA,CAN,MEX}
tabulate _merge
sort _merge country
list country pop gdp _merge, sepby(_merge) noobs
drop _merge
erase "output/_pop.dta"

*------------------------------------------------------------------------------
* 2. RESHAPE  (wide <-> long), the panel-builder's workhorse.
*------------------------------------------------------------------------------
clear
input id year income
1 2010 100
1 2011 110
1 2012 130
2 2010 200
2 2011 220
2 2012 250
end
list, sepby(id)
reshape wide income, i(id) j(year)      // long -> wide  (income2010, income2011,...)
list
reshape long income, i(id) j(year)      // wide -> long  (back again)
list, sepby(id)

*------------------------------------------------------------------------------
* 3. COLLAPSE  (aggregate to a coarser level; ~ groupby().agg()).
*------------------------------------------------------------------------------
sysuse auto, clear
collapse (mean) mean_price=price mean_mpg=mpg ///
         (sd) sd_price=price (count) n=price, by(foreign)
list

* --- export the collapse summary as a table for the reference ---
capture file close cl
file open cl using "output/02_collapse_table.tex", write replace
file write cl "\begin{table}[htbp]\centering" _n
file write cl "\caption{\cmd{collapse}: the 74-car sample reduced to one row per origin}" _n
file write cl "\begin{tabular}{lrrrr}" _n "\toprule" _n
file write cl "Origin & Mean price & Mean mpg & SD price & \(N\) \\" _n "\midrule" _n
forvalues i = 1/`=_N' {
    local org = cond(foreign[`i']==0, "Domestic", "Foreign")
    file write cl "`org' & " %6.0f (mean_price[`i']) " & " %5.1f (mean_mpg[`i']) ///
        " & " %6.0f (sd_price[`i']) " & " %3.0f (n[`i']) " \\" _n
}
file write cl "\bottomrule" _n "\end{tabular}" _n "\end{table}" _n
file close cl

*------------------------------------------------------------------------------
* 4. DATES  (Stata stores dates as integers; display via formats).
*------------------------------------------------------------------------------
clear
input str10 raw
"2020-01-15"
"2020-06-30"
"2021-12-01"
end
generate edate = date(raw, "YMD")       // string -> numeric daily date
list raw edate, noobs                    // edate is a number: days since 1960-01-01
format edate %td
list raw edate, noobs                    // same column, now shown as a calendar date
generate year  = year(edate)
generate month = month(edate)
generate mdate = mofd(edate)            // monthly date
format mdate %tm
list

*------------------------------------------------------------------------------
* 5. STRING handling.
*------------------------------------------------------------------------------
sysuse auto, clear
generate brand = word(make, 1)          // first token of make
generate make_up = upper(make)
generate is_amc = strpos(make, "AMC")>0
generate spc = strpos(make, " ")        // position of the first space (0 if none)
list make brand make_up spc in 1/6, noobs
tabulate brand if is_amc

*------------------------------------------------------------------------------
* 6. DUPLICATES.
*------------------------------------------------------------------------------
clear
input id v
1 10
1 10
2 20
3 30
3 30
end
duplicates report                       // how many dup rows
duplicates drop                         // drop exact duplicates
list

* tidy up scratch files
erase "output/_left.dta"
erase "output/_right.dta"

log close
display "02_data_management.do finished OK"
