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
	echo "⚠️⚠️⚠️when you change the jenkins chart or rego files, you should run this command and copy tmp.yaml to IDE to format it, and then run conftest. otherwise, it will not return any error.⚠️⚠️⚠️"
    # fixme: templated yaml are not valid yaml files (for rego), rego not detect the correct 'containers', maybe is a bug of conftest

	helm template  jenkins ./charts/jenkins-full --debug -n jenkins -f test/default-registry/values.yaml > tmp.yaml
	conftest test -o $(OUTPUT) --policy test/default-registry/full tmp.yaml

	helm template  jenkins ./charts/jenkins --debug -n jenkins -f test/default-registry/values.yaml > tmp.yaml
	conftest test -o $(OUTPUT) --policy test/default-registry/base tmp.yaml

	helm template  jenkins ./charts/jenkins-full --debug -n jenkins -f test/override-registry/values.yaml > tmp.yaml
	conftest test -o $(OUTPUT) --policy test/override-registry/full tmp.yaml

	helm template  jenkins ./charts/jenkins --debug -n jenkins -f test/override-registry/values.yaml > tmp.yaml
	conftest test -o $(OUTPUT) --policy test/override-registry/base tmp.yaml

	helm template  jenkins ./charts/jenkins-full --debug -n jenkins -f test/runtime/values.yaml > tmp.yaml
	conftest test -o $(OUTPUT) --policy test/runtime/full tmp.yaml

	helm template  jenkins ./charts/jenkins --debug -n jenkins -f test/runtime/values.yaml > tmp.yaml
	conftest test -o $(OUTPUT) --policy test/runtime/base tmp.yaml

	rm tmp.yaml

.PHONY: install-opa
install-opa:
	./hack/install/opa.sh

.PHONY: opa-test
opa-test: install-opa
	opa test test/default-registry/ -v


.PHONY: update-agents-version
update-agents-version:
	./hack/update_agent_version.sh