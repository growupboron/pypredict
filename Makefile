VERSION := $(shell python ./setup.py --version)
NAME := $(shell python ./setup.py --name)
ARCH ?= linux_x86_64
src := predict.py predict.c setup.py
sdist := dist/$(NAME)-$(VERSION).tar.gz
wheels := dist/$(NAME)-$(VERSION)-cp27-cp27m-$(ARCH).whl \
	dist/$(NAME)-$(VERSION)-cp35-cp35m-$(ARCH).whl \
	dist/$(NAME)-$(VERSION)-cp37-cp37m-$(ARCH).whl \
	dist/$(NAME)-$(VERSION)-cp27-cp27mu-$(ARCH).whl \
	dist/$(NAME)-$(VERSION)-cp36-cp36m-$(ARCH).whl \
	dist/$(NAME)-$(VERSION)-cp38-cp38-$(ARCH).whl

-include .makerc

.PHONY: help
help:
	@echo "Targets:"
	@echo "  clean:  Removes distribution folders and artifacts from building"
	@echo "  build:  Builds source and wheel distributions"
	@echo "  upload: Uploads built source and wheel distributions to repository"
	@echo "          Requires env vars `REPO`, `USER`, `PASSWORD`"

.PHONY: clean
clean:
	rm -rf wheelhouse dist/ build/ __pycache__/ *.egg-info/ tletools/*.pyc venv .pytest_cache/

.PHONY: build
build: sdist manylinux-wheels

.PHONY: manylinux-wheels
manylinux-wheels: $(wheels)

$(wheels) &: $(src)
	docker run --user $(shell id -u):$(shell id -g) -v $(shell pwd):/io \
		quay.io/pypa/manylinux1_x86_64:latest \
		/io/bin/build-manylinux-wheel.sh 27 35 36 37 38

.PHONY: sdist
sdist: $(sdist)

$(sdist): $(src)
	python setup.py sdist

.PHONY: upload
upload: build check-env
	twine upload --repository-url ${REPO} --username ${USER} --password "${PASSWORD}" dist/*

.PHONY: check-env
check-env:
ifndef REPO
	$(error $REPO must be specified)
endif
ifndef USER
	$(error USER must be specified)
endif
ifndef PASSWORD
	$(error PASSWORD must be specified)
endif
