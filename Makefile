# Makefile for a uv-managed Jupyter notebook repo
# Valmor F. de Almeida Cortix Tech
#
# Usage:
#   make help
#   make notebook
#   make lab
#   make sync
#   make lock
#   make kernel-install
#
# Notes:
# - Targets are designed to work even if some optional tools aren't installed.
# - Override variables on the command line as needed, e.g.:
#     make notebook NOTEBOOK_DIR=notebooks
#     make kernel-install KERNEL_NAME=my-kernel DISPLAY_NAME="Python (my-kernel)"

SHELL := /bin/bash

# ---- User-tunable variables ----
NOTEBOOK_DIR ?= notebooks

# Kernel name as it appears in `jupyter kernelspec list`
KERNEL_NAME ?= ct-300-jupynb-repo
DISPLAY_NAME ?= Python ($(KERNEL_NAME))

# Jupyter command to launch (Notebook 7 UI)
JUPYTER_NOTEBOOK_CMD ?= jupyter notebook

# JupyterLab command (only works if jupyterlab is installed)
JUPYTER_LAB_CMD ?= jupyter lab

# ---- Internals ----
UV ?= uv

.PHONY: help
help:
	@echo "uv notebook repo helpers"
	@echo ""
	@echo "Run:"
	@echo "  make notebook            Launch Jupyter Notebook in $(NOTEBOOK_DIR)/ via uv"
	@echo "  make lab                 Launch JupyterLab in $(NOTEBOOK_DIR)/ via uv (if installed)"
	@echo ""
	@echo "Environment / deps:"
	@echo "  make sync                Sync .venv to uv.lock"
	@echo "  make lock                Recompute uv.lock from pyproject.toml"
	@echo "  make upgrade             Upgrade dependencies (re-lock + sync)"
	@echo "  make clean-venv          Remove .venv (disposable)"
	@echo "  make reset               Remove .venv, then sync"
	@echo ""
	@echo "Kernel / Jupyter wiring:"
	@echo "  make kernel-install      Install/update a kernelspec named '$(KERNEL_NAME)'"
	@echo "  make kernel-list         Show installed kernels"
	@echo "  make kernel-check        Print sys.executable from the uv environment"
	@echo ""
	@echo "Info / maintenance:"
	@echo "  make uvinfo              Run ./uvinfo (your helper script)"
	@echo "  make pip-list            Show pip packages in the uv environment"
	@echo "  make pip-freeze          Show frozen pip packages in the uv environment"
	@echo "  make pip-check           Check pip packages in the uv environment"
	@echo "  make python              Run a python REPL inside the uv environment"
	@echo "  make check-mendeleev     Quick import test for mendeleev"
	@echo ""
	@echo "Optional tooling (only if installed):"
	@echo "  make fmt                 Run ruff format ."
	@echo "  make lint                Run ruff check ."
	@echo "  make test                Run pytest (if present)"
	@echo ""
	@echo "Variables you can override:"
	@echo "  NOTEBOOK_DIR, KERNEL_NAME, DISPLAY_NAME"
	@echo ""

# ---- Core uv operations ----

.PHONY: sync
sync:
	$(UV) sync

.PHONY: lock
lock:
	$(UV) lock

# Conservative "upgrade": rely on `uv lock` to re-resolve, then sync.
# If your uv version supports `uv lock --upgrade`, you can replace the first line with it.
.PHONY: upgrade
upgrade:
	$(UV) lock
	$(UV) sync

.PHONY: clean-venv
clean-venv:
	rm -rf .venv

.PHONY: reset
reset: clean-venv sync

# ---- Jupyter launchers ----

.PHONY: notebook
notebook:
	$(UV) run $(JUPYTER_NOTEBOOK_CMD) $(NOTEBOOK_DIR)/

.PHONY: lab
lab:
	$(UV) run $(JUPYTER_LAB_CMD) $(NOTEBOOK_DIR)/

# ---- Kernel management ----

.PHONY: kernel-install
kernel-install:
	$(UV) run python -m ipykernel install --user --name "$(KERNEL_NAME)" --display-name "$(DISPLAY_NAME)"

.PHONY: kernel-list
kernel-list:
	$(UV) run python -m jupyter kernelspec list

.PHONY: kernel-check
kernel-check:
	$(UV) run python -c "import sys; print(sys.executable)"

# ---- Info / day-to-day helpers ----

UVINFO ?= $(HOME)/bin/uvinfo.sh

.PHONY: uvinfo
uvinfo:
	@$(UVINFO)

.PHONY: pip-list
pip-list:
	$(UV) pip list

.PHONY: pip-freeze
pip-freeze:
	$(UV) pip freeze

.PHONY: pip-check
pip-check:
	$(UV) pip check

.PHONY: python
python:
	$(UV) run python

.PHONY: check-mendeleev
check-mendeleev:
	$(UV) run python -c "from mendeleev import element; print(element('Fe'))"

# ---- Optional tool targets (run only if tool exists in the uv env) ----

.PHONY: fmt
fmt:
	@$(UV) run python -c "import shutil; raise SystemExit(0 if shutil.which('ruff') else 1)" \
		&& $(UV) run ruff format . \
		|| echo "ruff not installed. Add it with:  uv add --dev ruff"

.PHONY: lint
lint:
	@$(UV) run python -c "import shutil; raise SystemExit(0 if shutil.which('ruff') else 1)" \
		&& $(UV) run ruff check . \
		|| echo "ruff not installed. Add it with:  uv add --dev ruff"

.PHONY: test
test:
	@$(UV) run python -c "import shutil; raise SystemExit(0 if shutil.which('pytest') else 1)" \
		&& $(UV) run pytest \
		|| echo "pytest not installed. Add it with:  uv add --dev pytest"
