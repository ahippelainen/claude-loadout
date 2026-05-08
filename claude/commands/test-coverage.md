---
description: Analyze pytest coverage gaps and generate missing tests to reach 80%+ coverage
argument-hint: "[optional: path to analyze, defaults to full project]"
---

Analyze test coverage for the Python project, identify gaps, and generate missing tests.

## Step 1: Run coverage

```bash
pytest --cov=. --cov-report=term-missing ${ARGUMENTS:-.}
```

If `pytest-cov` is not installed or the project has a different source root configured in `pyproject.toml`, adapt accordingly.

## Step 2: Identify gaps

List files below 80% coverage, sorted worst-first. For each, identify:
- Untested functions or methods
- Missing branch coverage (if/else, error paths)
- Dead code that inflates the denominator (note it but don't generate tests for it)

## Step 3: Generate missing tests

For each under-covered file, generate tests in this priority order:

1. **Happy path** — core functionality with representative inputs
2. **Error paths** — invalid inputs, raised exceptions, missing data
3. **Edge cases** — empty collections, None, boundary values (0, -1, max)
4. **Branch coverage** — each if/else arm not yet covered

Rules:
- Follow existing test file naming and location conventions for the project
- Use existing fixtures and patterns from the test suite
- Each test must be independent — no shared mutable state
- For numerical code: use `pytest.approx` or `np.testing.assert_allclose`, never `==`
- Name tests descriptively: `test_<function>_<scenario>_<expected>`

## Step 4: Verify

Re-run coverage. If still below 80%, identify remaining gaps and repeat Step 3.

## Step 5: Report

```
Coverage Report
────────────────────────────────
File                  Before  After
src/foo.py            45%     88%
src/bar.py            32%     82%
────────────────────────────────
Overall:              67%     84%
```
