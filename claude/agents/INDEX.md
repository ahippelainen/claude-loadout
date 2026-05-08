# Agents Index

## Python & Software Engineering

| Agent | Trigger | Description |
|---|---|---|
| `python-pro` | Explicit, or when writing/reviewing/auditing Python | Full Python 3.11+ development and review. Runs static analysis (mypy strict, ruff, black, bandit, pytest --cov) then grades issues by severity: CRITICAL (SQL injection, command injection, path traversal, eval on input, plaintext passwords, yaml.load), HIGH (missing type hints, mutable defaults, deep nesting, async blocking calls, N+1 queries), MEDIUM (PEP 8, None comparison, print vs logging). Blocks on CRITICAL or HIGH; approves otherwise. Preferred stack: httpx, pydantic v2, pytest + pytest-asyncio, ruff, mypy. |
| `code-architect` | When designing a feature that must fit into an existing codebase | Read-only analysis followed by implementation blueprint. Studies code organization, naming conventions, dependency graph, and test patterns. Produces: design decisions, table of files to create/modify with purpose and interfaces, data flow description, build sequence ordered by dependency (types/interfaces → core logic → integration → UI → tests). Rule: choose simplest architecture; avoid speculative abstractions unless already present in the repo. |
| `code-simplifier` | After writing code or reviewing recent changes | Identifies and applies functionally equivalent simplifications: extract deeply nested logic into named functions, replace complex conditionals with early returns, remove dead code and unused imports, break long chains into intermediate variables, consolidate duplicated logic, unwind over-abstracted single-use helpers. Preserves behavior absolutely. |
| `legacy-modernizer` | When upgrading old code, migrating frameworks, or reducing tech debt incrementally | Assessment phase: map debt (code quality, outdated deps, security, missing tests), identify business-critical paths, establish baseline. Strategy selection: strangler fig (new requests through new code, shrink old surface), branch by abstraction (add interface, implement both, switch, remove old), parallel run (compare outputs side-by-side before cutting over), or extract service. Each step must be independently deployable with rollback possible. |
| `planner` | Proactively on feature implementation, architectural changes, complex refactoring | Produces a phased markdown plan: requirements analysis → affected component review → step breakdown with exact file paths and function names → implementation order that minimizes context switching and enables incremental testing. Red flags to check: large functions (>50 lines), deep nesting (>4 levels), missing tests, no testing strategy. For large features, each phase should produce working testable software on its own. Feeds directly into implementation. |
| `tdd-guide` | When adding features, fixing bugs, or refactoring with pytest | Enforces Red→Green→Refactor. Red: write the smallest test capturing the next behavior, run it, confirm it fails for the right reason. Green: minimum code to pass, nothing more. Refactor: clean up with tests staying green. For numerical/scientific code: use `pytest.approx` or `np.testing.assert_allclose` (never `==`), test known analytic cases, test symmetry/invariant properties, parametrize over multiple inputs. Anti-patterns: tests depending on each other, mocking so heavily the test no longer exercises real logic, tests written after to hit a coverage number. Target: 80%+ line and branch coverage. |

---

## Data Analysis

| Agent | Trigger | Description |
|---|---|---|
| `data-analyst` | Explicit, or for exploratory analysis, statistical modeling, time series, or data pipelines | Full scientific analysis in Python. EDA: profiling, distributions, outliers, correlations. Statistical: hypothesis testing (t-tests, chi-squared, Mann-Whitney, permutation), multiple comparison correction (Bonferroni/FDR), effect sizes alongside p-values, regression (linear/logistic/GLM), Bayesian reasoning with credible intervals, causal inference with confounders and DAGs, power analysis, experimental design. Time series: decomposition, stationarity tests (ADF/KPSS), ARIMA/SARIMA, anomaly detection. ML when statistical models are insufficient: cross-validation, no evaluation on training data, SHAP for interpretation. Rule: always state and verify assumptions before modeling; report uncertainty as intervals, not just p-values. |
| `quant-analyst` | Explicit, for financial modeling, backtesting, derivatives pricing, portfolio work | Quantitative finance in Python. Derivatives: Black-Scholes, binomial trees, Monte Carlo for path-dependent payoffs, Greeks via finite difference or analytic, volatility surfaces (SVI, SABR), Longstaff-Schwartz for American options. Portfolio: Markowitz efficient frontier, Black-Litterman, risk parity, constrained optimization (cvxpy). Risk: VaR (historical/parametric/MC), CVaR/Expected Shortfall, drawdown metrics, factor exposure via OLS. Backtesting rules: no lookahead bias (shift(1) correctly), survivorship bias requires delisted assets, walk-forward validation, realistic transaction costs and slippage. Vectorize operations; separate data/signal/execution/analytics layers. |

---

## Debugging & Error Analysis

| Agent | Trigger | Description |
|---|---|---|
| `debugger` | On complex bugs — when reproduction, hypothesis, and elimination are needed | Scientific method: Reproduce → Hypothesize → Gather evidence → Eliminate → Fix and verify. Domain-specific techniques: concurrency (check shared mutable state, lock ordering, happens-before; map lock acquisition for deadlocks), Python (mutable defaults, late-binding closures, unawaited coroutines, circular imports), performance (profile before optimizing — cProfile/py-spy for CPU, tracemalloc/memray for memory, strace for I/O), error analysis (read full stack trace — root cause usually not the top frame; correlate with recent changes). Output: state current hypothesis + supporting evidence + verification step. When resolved: one-sentence root cause. Rule: never guess, demand evidence. |
| `error-analyst` | When errors recur, failure propagation is unclear, or error handling needs to be more robust | Pattern-level analysis (complements `debugger` which handles individual bugs). Identifies: recurring error types and frequency trends, temporal correlations, error clusters with common causes. Cascade analysis: retry storms, timeout chains, missing error boundaries where one failure silently corrupts downstream state, over-broad exception handling. Techniques: five whys, fault tree analysis, timeline reconstruction from logs, change correlation. Resilience review: circuit breaker placement, retry backoff correctness, fallback quality (do fallbacks produce silently wrong results?), error propagation level. |
| `silent-failure-hunter` | After writing error handling code or auditing a module for robustness | Hunts: swallowed exceptions (`except: pass`, catch-log-continue), silent wrong results (returning None/[]/0 on error without logging), bad fallbacks (degraded output with no signal to caller, retry exhaustion without raising), missing propagation (errors caught at low level when caller needs to abort, async tasks where exceptions are swallowed). For numerical/scientific code specifically: NaN propagation without checks (silent corruption of downstream results), division by zero caught and replaced silently, array operations returning wrong shapes via broadcasting. Severity: CRITICAL (swallowed with no trace), HIGH (logged but not propagated), MEDIUM (degraded output without indication). Advisory only. |

---

## Code Quality Analysis

| Agent | Trigger | Description |
|---|---|---|
| `type-design-analyzer` | When introducing new types, reviewing data models, improving type definitions | Rates each type on four dimensions (1–10): Encapsulation (internal details hidden, minimal interface), Invariant Expression (constraints communicated by type structure, not just docs), Invariant Usefulness (invariants prevent real bugs, aligned with domain rules), Invariant Enforcement (checked at construction, all mutation points guarded, impossible to construct invalid instance). Anti-patterns flagged: anemic types (plain dicts where a model belongs), invariants enforced only by comments, exposed mutable internals, scattered validation at call sites, Optional fields for mutually exclusive states (use Union instead). Pydantic v2 specifics: `model_validator` for cross-field invariants, `Field(gt=0)` for scalar bounds, `ConfigDict(frozen=True)` for value objects. Advisory only. |
| `comment-analyzer` | Before PRs, after writing large docstrings, or when auditing existing comments | Read-only audit of comment accuracy and value. Accuracy check: does comment match what code actually does (parameter mismatches, return type errors, behavior differences)? Value assessment: comments restating obvious code should be removed; comments explaining *why* are valuable; comments explaining *what* usually aren't. Staleness: references to refactored code, addressed TODOs, transitional notes. Output: Critical (factually wrong/misleading), Improvements (unclear but worth fixing), Remove (no value), Good (worth noting). Advisory only — does not modify files. |

---

## Security

| Agent | Trigger | Description |
|---|---|---|
| `security` | After writing auth/API/input-handling code, before releases, or when auditing security posture | Runs bandit, ruff, pip-audit then grades findings. CRITICAL: hardcoded secrets, f-string SQL (→ parameterized), shell=True with user input (→ subprocess list args), user-controlled paths (→ normpath + reject ..), eval/exec on external input, plaintext passwords, yaml.load() (→ safe_load), unauthenticated routes. HIGH: XSS, SSRF (→ whitelist domains), weak crypto (MD5/SHA1 → SHA-256+), missing rate limiting on auth, CORS wildcard on credentialed requests, insecure session cookies. Secrets management: rotate immediately if committed, treat as compromised. Incident response: contain (revoke/isolate) → assess (blast radius) → remediate → document → post-mortem. False positives: SHA256 for checksums is fine, test credentials marked as such are fine. |

---

## Performance

| Agent | Trigger | Description |
|---|---|---|
| `performance-engineer` | When optimizing slow code, diagnosing resource problems, setting up monitoring, or capacity planning | Profile before optimizing — never guess the bottleneck. CPU: cProfile, py-spy, perf. Memory: tracemalloc, memray, heapy. I/O: strace, lsof. DB: slow query logs, EXPLAIN plans, connection pool saturation. Common culprits: N+1 queries, cache misses, blocking calls in async, algorithmic complexity, thread contention. Load testing: baseline first, then sustained throughput (load), breaking point (stress), resource exhaustion over time (soak). Optimizations: fix algorithmic complexity before micro-optimization, caching (match invalidation to data freshness), async/batch for I/O-bound, connection pooling. Observability: p50/p95/p99 latency, RPS, error rate, resource utilization; statistical baselines for anomaly detection rather than static thresholds. Always measure improvement against baseline. |

---

## Adding new agents

Place `.md` files with YAML frontmatter (`name`, `description`, `tools`) in this directory and add a row to the appropriate section above.
