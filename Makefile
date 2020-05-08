SHELL := bash
PACKAGE_NAME = $(shell basename "$$PWD")
PYTHON_NAME = $(shell echo "$(PACKAGE_NAME)" | sed -e 's/-//' | sed -e 's/-/_/g')
SOURCE = $(PYTHON_NAME)
PYTHON_FILES = $(SOURCE)/*.py *.py tests/*.py bin/*.py
SHELL_FILES = bin/* debian/bin/* *.sh
PIP_INSTALL ?= install
DOWNLOAD_DIR = download

.PHONY: reformat check dist venv downloads

version := $(shell cat VERSION)
architecture := $(shell bash architecture.sh)

version_tag := "rhasspy/$(PACKAGE_NAME):$(version)"

DOCKER_PLATFORMS = linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6

ifneq (,$(findstring -dev,$(version)))
	DOCKER_TAGS = -t "$(version_tag)"
else
	DOCKER_TAGS = -t "$(version_tag)" -t "rhasspy/$(PACKAGE_NAME):latest"
endif

all: venv

# -----------------------------------------------------------------------------
# Python
# -----------------------------------------------------------------------------

reformat:
	scripts/format-code.sh $(PYTHON_FILES)

check:
	scripts/check-code.sh $(PYTHON_FILES)

venv: downloads
	scripts/create-venv.sh

dist: sdist

sdist:
	python3 setup.py sdist

test:
	scripts/run-tests.sh

# -----------------------------------------------------------------------------
# Downloads
# -----------------------------------------------------------------------------

# Rhasspy development dependencies
RHASSPY_DEPS := $(shell grep '^rhasspy-' requirements.txt | sort | comm -3 - rhasspy_wheels.txt | sed -e 's|^|$(DOWNLOAD_DIR)/|' -e 's/==/-/' -e 's/$$/.tar.gz/')

$(DOWNLOAD_DIR)/%.tar.gz:
	mkdir -p "$(DOWNLOAD_DIR)"
	scripts/download-dep.sh "$@"

downloads: $(RHASSPY_DEPS)
