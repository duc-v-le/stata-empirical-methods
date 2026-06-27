# Stata skill portfolio — [Duc V. Le](https://duc-v-le.github.io)

A small, **fully runnable** Stata project that demonstrates the empirical workflow
applied economists use end to end: load → clean → model → diagnose → export. It pairs 12
documented `.do` scripts with two typeset reference books, spanning data management,
regression, panel/DiD and event studies, time series, IV/2SLS, limited-dependent-variable
models, staggered DiD, regression discontinuity, synthetic control, and dynamic-panel GMM.

Every script was executed on **Stata 19.5 SE** and runs clean; the figures and tables in
`output/` are the real results.

**The two typeset books are in [`books/`](books/):** the [Reference](books/Stata-Reference.pdf)
(method, code, and results for all 12 scripts) and the [Guide](books/Stata-Guide.pdf)
(a line-by-line walkthrough).

## How to run
From inside this folder, in Stata:
```stata
do 00_run_all.do          // runs the whole portfolio
```
Or in batch from a shell:
```bash
STATA="/Applications/StataNow19SE/StataSE19.app/Contents/MacOS/stata-se"
"$STATA" -b do 00_run_all.do
```
Each script writes a log to `logs/<name>.log` and any tables/figures to `output/`. (Batch mode
also drops a session log named after the do-file in this folder — the canonical per-script logs
live in `logs/`; the top-level `*.log` can be deleted after a run.)

### One-time package setup
The panel/table/plot scripts use five community (SSC) packages. Install them all with:
```stata
do packages/install_packages.do
```
See [`packages/PACKAGES.md`](packages/PACKAGES.md) for what each package does and why it's
needed; `packages/installed_manifest.txt` is the provenance snapshot. Everything else uses
base Stata (no install needed).

## File map (run order)
| File | What it teaches |
|---|---|
| `00_run_all.do` | Master script — runs everything in order |
| `01_basics.do` | Load (`sysuse`), `describe`/`summarize`/`tabulate`, `generate`/`egen`, labels, `if`, graphs, save `.dta` |
| `02_data_management.do` | `merge`, `reshape` (wide↔long), `collapse`, dates, string functions, `duplicates` |
| `03_regression.do` | OLS, robust SE, factor variables (`i.`/`c.`/`##`), `margins`, postestimation (`test`, `estat hettest`, `vif`), `esttab` → LaTeX + CSV |
| `04_panel_did_eventstudy.do` | `xtset`, fixed effects (`xtreg`, `reghdfe`), difference-in-differences, dynamic event study + `coefplot` |
| `05_timeseries.do` | `tsset`, lag/diff operators (`L.`/`D.`), `ac`, Newey–West HAC SE, level-break test |
| `06_import_public_data.do` | `import`/`export delimited`, importing a **real FRED series** live via `import fred` (CSV fallback) |
| `07_iv_2sls.do` | Instrumental variables / 2SLS (`ivregress`), weak-IV / endogeneity / overid diagnostics, IV with FE (`ivreghdfe`) |
| `08_logit_probit.do` | Binary outcomes: LPM vs logit vs probit, odds ratios, **average marginal effects** (`margins`), predicted-probability plot, classification + ROC |
| `09_staggered_did_csdid.do` | Staggered-adoption DiD (Callaway–Sant'Anna `csdid`): group-time ATTs, event-study/simple/group aggregations, vs. the biased naive two-way FE |
| `10_rdd_regression_discontinuity.do` | Sharp regression discontinuity (`rdrobust`): local-polynomial estimate + robust CI, bandwidth selection, `rdplot`, manipulation test (`rddensity`) |
| `11_synthetic_control.do` | Synthetic control (`synth`): donor-weighted counterfactual, treated-vs-synthetic path, placebo-based inference (`synth_runner`) |
| `12_dynamic_panel_gmm.do` | Dynamic panel GMM: Arellano–Bond (`xtabond`) & Blundell–Bond system GMM (`xtdpdsys`); pooled OLS/FE bracket the truth, AR(2) validity test |

Supporting folders: `books/` (the two typeset PDFs — the Reference and the Guide), `packages/`
(dependency installer + guide + manifest), `output/` (figures, tables,
datasets), `data/` (downloaded public data). Each script also writes a run log to a local
`logs/` folder (created automatically at run time).

## Outputs (`output/`)
- `02_collapse_table.tex` — collapse summary (mean/SD price & mpg by car origin)
- `03_regression_table.tex`, `.csv` — publication regression table (esttab)
- `04_did_table.tex` — DiD estimates across three specifications
- `04_event_study.png` — dynamic treatment-effect path (flat pre-trend, rising lags)
- `07_iv_table.tex` — OLS vs 2SLS vs IV+FE (IV recovers the true slope; OLS biased)
- `07_iv_diag_table.tex` — IV diagnostics (first-stage F, Durbin–Wu–Hausman, overid)
- `08_logit_pr.png` — predicted P(foreign) across mpg
- `09_csdid_event.png` — Callaway–Sant'Anna event study (pre vs post)
- `09_csdid_table.tex` — overall ATT (Callaway–Sant'Anna) vs naive two-way FE
- `10_rdplot.png` — annotated sharp RD plot (binned means + local fit each side; grey double-arrow
  just right of the cutoff = the `rdrobust` jump τ̂=1.938 with limit dots; dashed control-fit
  counterfactual; cutoff marked)
- `10_rd_table.tex` — RD estimate + robust CI + manipulation-test p
- `11_synth_path.png`, `11_synth_placebo.png` — synthetic control: treated vs synthetic, and placebo gaps
- `12_dynpanel_table.tex` — dynamic panel: persistence ρ across pooled OLS, within FE, difference GMM, system GMM
- `01_*`, `03_rvfplot`, `05_tsline`, `05_acf`, `06_unrate` — figures
- `*.dta` — saved datasets (incl. `fred_unrate.dta`)

## Data provenance
- **U.S. unemployment rate (FRED: `UNRATE`)** — `06_import_public_data.do` pulls this **live** from
  FRED's API using Stata's native `import fred` (941 monthly observations, 1948-01 through 2026-05;
  public domain). The importer needs a free key, set once with `set fredkey YOUR_KEY, permanently` — the
  key lives in user's Stata config, **NOT in this repo**. With no key configured the script falls back to
  `data/UNRATE.csv` (the same series, downloaded from FRED via `curl` on 2026-06-23).
- All other data are either Stata's bundled `auto` dataset (`sysuse auto`) or simulated
  in-script with a fixed `set seed` (so results are fully reproducible).

## Python/R → Stata cheat sheet
| Task | pandas / R | Stata |
|---|---|---|
| Load CSV | `pd.read_csv` / `read_csv` | `import delimited "f.csv", varnames(1) clear` |
| Inspect | `df.head()` / `head()` | `list in 1/5`, `describe`, `codebook` |
| New column | `df["x"]=...` / `mutate` | `generate x = ...` (`replace` to overwrite) |
| Group aggregate | `groupby().agg` | `collapse (mean)... , by(g)` or `egen ..., by(g)` |
| Reshape | `pivot`/`melt` / `pivot_longer` | `reshape wide`/`reshape long` |
| Join | `merge` | `merge 1:1 key using "f.dta"` |
| OLS robust | `smf.ols(...).fit(cov_type="HC1")` / `feols` | `regress y x, vce(robust)` |
| Fixed effects | `PanelOLS` / `feols(... | fe)` | `xtreg ..., fe` or `reghdfe ..., absorb()` |
| Marginal effects | `.get_margeff()` / `margins` | `margins, dydx(x)` |
| Lag | `.shift()` / `lag()` | `L.x` (after `tsset`) |
