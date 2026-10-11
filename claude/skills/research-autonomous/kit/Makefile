# @NAME@ program: environment and test entry points.
SHELL   := /bin/bash
ROOT    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
# PROGRAM_VENV (e.g. outside a Dropbox folder) overrides the default, as in nightly.sh
VENV    ?= $(or $(PROGRAM_VENV),$(ROOT)/venv)
PY      := $(VENV)/bin/python
PYTEST   = timeout -k 10 $(1) env PYTHONPATH=$(ROOT)/src $(PY) -m pytest -q -p no:cacheprovider
E2E_MIN ?= 5

.PHONY: help venv smoke test e2e

help:
	@echo "make venv            - create $(VENV) and install requirements.txt"
	@echo "make smoke           - runner/watchdog/nightly/digest tests, must stay < 60 s"
	@echo "make test            - every pytest test"
	@echo "make e2e [E2E_MIN=5] - nightly.sh end to end in throwaway copies (git and non-git), E2E_MIN-minute window"

venv:
	test -x $(PY) || python3 -m venv $(VENV)
	timeout -k 10 1800 $(VENV)/bin/pip install -q -r $(ROOT)/requirements.txt

smoke:
	@start=$$(date +%s%N); \
	$(call PYTEST,120) $(ROOT)/tests/test_runner.py $(ROOT)/tests/test_watchdog.py $(ROOT)/tests/test_nightly.py \
		$(ROOT)/tests/test_digest.py && \
	echo "smoke wall $$(( ($$(date +%s%N) - start) / 1000000 )) ms"

test:
	$(call PYTEST,3600) $(ROOT)/tests

e2e:
	PROGRAM_VENV=$(VENV) timeout -k 10 $$(( $(E2E_MIN) * 60 + 1500 )) $(ROOT)/tests/nightly_e2e.sh $(E2E_MIN)
