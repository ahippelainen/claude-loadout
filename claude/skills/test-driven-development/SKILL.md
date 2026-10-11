---
name: test-driven-development
description: Test-first RED→GREEN→REFACTOR with pytest, including numerical and scientific tests. Invoked explicitly ("TDD this", "test-first", /test-driven-development); it does not fire by itself.
disable-model-invocation: true
---

# Test-driven development

Write the test first, watch it fail for the intended reason, write the least code that passes, then clean up with the tests green.

## Cycle

1. **Red**: one test for one behaviour, named after the behaviour. Run it (`python -m pytest path/to/test.py::test_name -v`) and confirm it fails because the feature is missing, not because of a typo. A test that passes at once is testing existing behaviour.
2. **Green**: the simplest code that passes; nothing speculative. Rerun the test and the suite.
3. **Refactor**: remove duplication and improve names; the tests stay green.

## What to test

- The main path with representative input, the edges (empty, zero, boundary values), and what should raise.
- Behaviour, not implementation: assert outputs and side effects; a refactor that breaks a test without changing behaviour means the test was wrong.
- Numerical code: `pytest.approx` or `np.testing.assert_allclose`, never `==` on floats; known analytic cases; symmetries and invariants; limits and asymptotics; `@pytest.mark.parametrize` over inputs.

```python
@pytest.mark.parametrize("n, expected", [(0, 1.0), (1, -1.0), (2, 1.0)])
def test_cosine_at_multiples_of_pi(n, expected):
    assert np.cos(n * np.pi) == pytest.approx(expected, abs=1e-12)
```

## Avoid

Tests that depend on each other or on shared mutable state (use fixtures); mocking so much that no real logic runs; writing tests after the fact to reach a coverage number.

## When stuck

Hard to test usually means hard to use: write the call you wish existed and work back from the assertion; if everything must be mocked, the code is too coupled.
