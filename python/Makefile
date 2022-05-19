SHELL=/bin/bash
VENV_DIR="venv"


# The .PHONY line and help task allow parameterless make to display a self documenting help file based on the comments after each target.
.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

python-version: ## Show python versions installed
	@python --version
	@python3 --version

python-make-venv: ## Setup the venv virtual environment in this directory
	python3 -m venv ./$(VENV_DIR)

init: ## Activate the venv virtual environment, install the required pips, and then output the version
	@source ./$(VENV_DIR)/bin/activate; \
	pip3 install boto3 requests pymsteams; \

test: ## Source venv and run the script file.
	@source ./$(VENV_DIR)/bin/activate; \
	python3 test.py

run: ## Source venv and run the script file.
	@source ./$(VENV_DIR)/bin/activate; \
	python3 run.py

references: ## List of references used in this project.
	@echo "https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html"
	@echo "https://docs.python.org/3/library/venv.html"
