.DEFAULT_GOAL := help

INSTALL_DIR := $(HOME)/.local/bin
SRC_DIR     := $(CURDIR)

SHELL_SCRIPTS := keepawake.sh keepawake-teams.sh
PYTHON_SCRIPT := keepawake.py
VENV_DIR      := $(SRC_DIR)/.venv
VENV_PIP      := $(VENV_DIR)/bin/pip

.PHONY: help install uninstall python-deps

help:
	@printf "nosleep — keep-awake scripts\n\n"
	@printf "Targets:\n"
	@printf "  %-14s %s\n" "install"      "Make scripts executable, install Python deps, symlink to $(INSTALL_DIR)"
	@printf "  %-14s %s\n" "uninstall"    "Remove symlinks from $(INSTALL_DIR)"
	@printf "  %-14s %s\n" "python-deps"  "Install Python dependencies only (pyobjc)"
	@printf "  %-14s %s\n" "help"         "Show this help"

install: scripts python-deps python
	@echo ""
	@echo "Installation complete. You can now run 'keepawake-py' or the shell scripts from anywhere."
	@echo "  Example: keepawake-py --help"
	@echo ""

python:
	@mkdir -p $(INSTALL_DIR)
	@chmod +x $(PYTHON_SCRIPT)
	@printf '#!/usr/bin/env bash\nexec "$(VENV_DIR)/bin/python3" "$(SRC_DIR)/$(PYTHON_SCRIPT)" "$$@"\n' \
		> $(INSTALL_DIR)/keepawake-py
	@chmod +x $(INSTALL_DIR)/keepawake-py
	@echo "  installed: $(INSTALL_DIR)/keepawake-py (uses venv)"
	@echo ""
	@echo "Done."
	@if ! echo "$$PATH" | tr ':' '\n' | grep -qx "$(INSTALL_DIR)"; then \
		echo ""; \
		echo "  WARNING: $(INSTALL_DIR) is not in your PATH."; \
		echo "  Add this to your ~/.zshrc or ~/.bash_profile:"; \
		echo "    export PATH=\"$(INSTALL_DIR):\$$PATH\""; \
	fi

scripts:
	@mkdir -p $(INSTALL_DIR)
	@chmod +x $(SHELL_SCRIPTS)

	@for script in $(SHELL_SCRIPTS); do \
		name=$$(basename $$script .sh); \
		ln -sf $(SRC_DIR)/$$script $(INSTALL_DIR)/$$name; \
		echo "  linked: $(INSTALL_DIR)/$$name"; \
	done

uninstall:
	@for script in $(SHELL_SCRIPTS); do \
		name=$$(basename $$script .sh); \
		rm -f $(INSTALL_DIR)/$$name && echo "  removed: $(INSTALL_DIR)/$$name" || true; \
	done
	@rm -f $(INSTALL_DIR)/keepawake-py && echo "  removed: $(INSTALL_DIR)/keepawake-py" || true

python-deps:
	@if [ ! -d "$(VENV_DIR)" ]; then python3 -m venv $(VENV_DIR); echo "  created venv: $(VENV_DIR)"; fi
	@$(VENV_PIP) install -q -r requirements.txt
	@echo "  installed Python deps into $(VENV_DIR)"
