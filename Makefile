
# Default target
.DEFAULT_GOAL := help

# To be included in the help message, target must have no space before the colon and a comment on the next line starting
# with ##. This comment is extracted and printed as the help message for that target.
.PHONY : help
help:
## Print this message.
	@grep -Eo '^[a-z0-9_%]+:|^## .*' Makefile | paste - - | column -t -s ':'

VENV_DIR := .venv
PYTHON := python3
PIP := $(VENV_DIR)/bin/pip

# Create the venv and install VSG. It automatically skips if the venv is already set up.
$(VENV_DIR)/bin/activate :
	$(PYTHON) -m venv $(VENV_DIR)
	$(PIP) install --upgrade pip
	$(PIP) install -r ./util/python_tools.txt
	@touch $(VENV_DIR)/bin/activate

.PHONY : _set_up_tools
_set_up_tools : $(VENV_DIR)/bin/activate

VSG := $(VENV_DIR)/bin/vsg
VHDL_FILES := $(shell find . -path './src/*' -name '*.vhd')
VSG_BASE_ARGS := --configuration ./util/vsg_config.yml -f $(VHDL_FILES)

.PHONY : vsg_check
vsg_check : _set_up_tools
## Check for formatting mistakes with VSG.
	@$(VSG) $(VSG_BASE_ARGS)

.PHONY : vsg_fix
vsg_fix : _set_up_tools
## Fix formatting mistakes with VSG.
	@$(VSG) $(VSG_BASE_ARGS) --fix

.PHONY : clean
clean:
## Remove all ignored files from repository.
	@echo "Removing untracked files"
	git clean -dfX
