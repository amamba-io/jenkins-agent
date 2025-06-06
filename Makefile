include Makefile.defs

NAMESPACE ?= "jenkins"
INSTALLATION_NAME ?= "jenkins"
DEPLOY_ENV ?= ""
VERSION ?= ""
FILENAME := ""
OUTPUT ?= "stdout"
ifeq ($(VERSION), "")
    LATEST_TAG=$(shell  git describe --tags --abbrev=8)
    ifeq ($(LATEST_TAG),)
        # Forked repo may not sync tags from upstream, so give it a default tag to make CI happy.
        VERSION="unknown"
    else
        VERSION=$(LATEST_TAG)
    endif
endif


CHART_VERSION ?= $(shell echo ${VERSION} | sed 's/-/+/1' | sed  's/^v//g' )


.PHONY: lint
lint:
	helm lint charts/jenkins
	helm lint charts/jenkins-full

.PHONY: render-all
render-all: render render-full

.PHONY: render
render:
	helm template jenkins charts/jenkins -n $(NAMESPACE) --create-namespace \
		 --set image.pullPolicy=Always --debug --dry-run

.PHONY: render-full
render-full:
	helm template jenkins charts/jenkins-full -n $(NAMESPACE) --create-namespace \
		 --set image.pullPolicy=Always --debug --dry-run

.PHONY: build
build:
	./hack/build.sh

.PHONY: deploy
deploy:
	./hack/deploy.sh $(VERSION)


.PHONY: e2e-test
e2e-test:
	./hack/e2e-test.sh $(VERSION)


.PHONY: local-e2e-test
local-e2e-test:
	KIND_IMAGE="release-ci.daocloud.io/kpanda/kindest-node:v1.26.0" ./hack/e2e-test.sh $(VERSION)

.PHONY: install-conftest
install-conftest:
	./hack/install/conftest.sh

.PHONY: conftest
conftest: install-conftest
	#if policy is not effective, please check the yaml indent.
	OUTPUT=$(OUTPUT) ./hack/test-chart.sh

.PHONY: install-opa
install-opa:
	./hack/install/opa.sh

.PHONY: opa-test
opa-test: install-opa
	opa test test/default-registry/ -v


.PHONY: update-agents-version
update-agents-version:
	./hack/update_agent_version.sh

.PHONY: check_casc_config
check_casc_config:
	./hack/check_casc_config.sh jenkins ./charts/jenkins
	./hack/check_casc_config.sh jenkins-full ./charts/jenkins-full