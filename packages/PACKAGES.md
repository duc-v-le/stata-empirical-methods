# Stata package dependencies — what to install and why

The `.do` scripts in [the repository root](../) run on **base Stata** *except* for a few
community-contributed commands. This folder documents exactly what those are, how to install
them, and why each is needed — so the environment can be reproduced.

## TL;DR — install everything
From the repository root, in Stata:
```stata
do packages/install_packages.do
```
That installs all five packages (idempotent — safe to re-run) and verifies each one. An internet
connection is needed the first time.

## What these are
All five come from **SSC** (the *Statistical Software Components* archive at Boston College —
`http://fmwww.bc.edu/repec/bocode/`), which is Stata's main repository of peer-contributed,
free, open-source commands. `ssc install <name>` downloads a package into the personal `ado`
directory; once installed it behaves like a built-in command.

**Core (scripts 01–06)**

| Package | What it does | Why this portfolio needs it | Used in |
|---|---|---|---|
| **reghdfe** | Linear/IV regression absorbing *any number* of high-dimensional fixed effects, with multi-way clustered SEs | The workhorse for modern panel/causal work. Base `xtreg` absorbs one FE dimension; `reghdfe` absorbs firm **and** year FE at once (two-way FE DiD, event studies) and is far faster | `04`, `09` |
| **ftools** | Fast versions of common data ops (collapse/merge/egen) on large data | **Dependency of reghdfe** — its fast group operations are what make `reghdfe` quick. Not called directly here | (dependency) |
| **require** | Checks that installed packages meet a minimum/exact version | **Dependency of recent reghdfe builds** — reghdfe refuses to load without it. This was the one missing piece that made `reghdfe` error on first run | (dependency) |
| **estout** | Builds publication-quality regression tables; provides `esttab`, `eststo`, `estadd` | Exports model results to **LaTeX and CSV** — the deliverable format faculty actually want, instead of copying numbers by hand | `03`, `04`, `07`, `08` |
| **coefplot** | Plots regression coefficients and CIs | Draws the **event-study figure** (coefficient path with confidence intervals and a reference line) from stored estimates | `04` |

**Advanced (scripts 07–09)**

| Package | What it does | Why this portfolio needs it | Used in |
|---|---|---|---|
| **ivreghdfe** | IV/2SLS with high-dimensional fixed effects (marries `ivreg2` + `reghdfe`) | The FE version of instrumental variables — absorb unit/time FE *and* instrument an endogenous regressor in one command | `07_iv_2sls.do` |
| **ivreg2** | Extended IV/2SLS/GMM with weak-IV and overid diagnostics | **Dependency of ivreghdfe** (the underlying IV engine) | (dependency) |
| **ranktest** | Rank tests behind weak-instrument statistics | **Dependency of ivreg2/ivreghdfe** | (dependency) |
| **csdid** | Callaway & Sant'Anna (2021) staggered-adoption DiD: clean group-time ATTs + aggregations | Modern DiD when units are treated at **different times** — avoids the negative-weighting bias of naive two-way FE | `09_staggered_did_csdid.do` |
| **drdid** | Doubly-robust DiD estimators (Sant'Anna & Zhao) | **Dependency of csdid** — the estimator csdid calls for each group-time cell | (dependency) |

**Advanced — quasi-experimental designs (scripts 10–11)**

| Package | What it does | Why this portfolio needs it | Used in |
|---|---|---|---|
| **rdrobust** | Calonico–Cattaneo–Titiunik regression discontinuity: local-polynomial estimation, MSE-optimal bandwidths (`rdbwselect`), robust bias-corrected CIs, and `rdplot` | The standard RD toolkit — point estimate, bandwidth, and the canonical RD figure | `10_rdd_regression_discontinuity.do` |
| **rddensity** | Manipulation test — is the running variable's density continuous at the cutoff? | The standard RD validity check (sorting around the threshold would invalidate the design) | `10_rdd_regression_discontinuity.do` |
| **lpdensity** | Local-polynomial density estimation | **Dependency of rddensity** | (dependency) |
| **synth** | Abadie et al. synthetic control: builds a weighted donor pool matching the treated unit's pre-period | The estimator for one-treated-unit comparative case studies | `11_synthetic_control.do` |
| **synth_runner** | Automates placebo/permutation inference for synth (p-values, gap plots) | Turns a single synth fit into an inference procedure (placebo distribution) | `11_synthetic_control.do` |
| **distinct** | Counts distinct values | **Dependency of synth_runner** | (dependency) |

## Dependency chains (worth knowing)
Several packages won't work installed alone — install order matters, which is why
`install_packages.do` sequences them:
- **reghdfe** needs **ftools** *and* **require**. Recent builds throw `reghdfe requires ... the
  require package` and stop if `require` is missing — that's the one piece that made `reghdfe`
  error on first run here.
- **ivreghdfe** needs **ivreg2**, **ranktest**, and (for the FE part) **ftools** + **reghdfe**.
- **csdid** needs **drdid**.
- **rddensity** needs **lpdensity**.
- **synth_runner** needs **synth** + **distinct** — and is **not on SSC**: it installs from
  GitHub (`net install synth_runner, from("https://raw.githubusercontent.com/bquistorff/synth_runner/master/")`).

If any of these throws a load error, just re-run the installer.

## Base Stata does the rest
A lot is built in — no install needed: `regress`, `ivregress 2sls` + `estat firststage`/
`endogenous`/`overid`, `logit`/`probit`, `margins`/`marginsplot`, `xtreg`, `xtset`/`tsset`,
`newey`, `ac`, `import/export delimited`, `import fred`, `reshape`, `collapse`, `merge`,
`graph export`. The packages above are the minimal set of community tools standard in applied
empirical work — used only where base Stata doesn't reach (high-dimensional FE, IV+FE,
staggered DiD, LaTeX tables, coefficient plots).

## Verify / reproduce
- `installed_manifest.txt` — a snapshot of the installed packages (`ado dir`) on the machine
  where this was built (Stata 19.5 SE), for provenance.
- To re-check at any time: `do packages/install_packages.do` (re-installs `, replace` and
  reports OK/MISSING for each), or in Stata run `ado dir`.

## Provenance (versions captured 2026-06-23, from SSC)
| Package | Source | Distribution date | Min. Stata |
|---|---|---|---|
| ftools | `fmwww.bc.edu/repec/bocode/f` | 2026-01-11 | 11.2 |
| reghdfe | `fmwww.bc.edu/repec/bocode/r` | 2026-01-11 | 11.2 (+ ftools) |
| estout | `fmwww.bc.edu/repec/bocode/e` | 2026-04-13 | 8.2 |
| coefplot | `fmwww.bc.edu/repec/bocode/c` | 2025-08-22 | 11 |
| require | `fmwww.bc.edu/repec/bocode/r` | 2023-09-21 | 14 |
| ranktest | `fmwww.bc.edu/repec/bocode/r` | 2020-09-29 | — |
| ivreg2 | `fmwww.bc.edu/repec/bocode/i` | 2024-08-14 | — |
| ivreghdfe | `fmwww.bc.edu/repec/bocode/i` | 2026-01-11 | (+ ivreg2, reghdfe) |
| drdid | `fmwww.bc.edu/repec/bocode/d` | 2025-10-05 | — |
| csdid | `fmwww.bc.edu/repec/bocode/c` | 2025-10-05 | (+ drdid) |
| rdrobust | `fmwww.bc.edu/repec/bocode/r` | 2022-09-30 | — |
| rddensity | `fmwww.bc.edu/repec/bocode/r` | 2022-07-08 | (+ lpdensity) |
| lpdensity | `fmwww.bc.edu/repec/bocode/l` | 2022-07-08 | — |
| synth | `fmwww.bc.edu/repec/bocode/s` | 2026-04-30 | — |
| distinct | `fmwww.bc.edu/repec/bocode/d` | 2012-03-21 | — |
| synth_runner | GitHub: `bquistorff/synth_runner` | (GitHub master) | (+ synth, distinct) |

## Offline / restricted networks
SSC needs outbound HTTP to `fmwww.bc.edu`. If a machine blocks it, install from a machine that
can reach it and copy the personal `ado/plus/` directory across (find it with `sysdir` →
`PLUS`), or install from the authors' GitHub mirrors (`net install` from the repo URLs).
