# Old-skool build tools.

.DEFAULT_GOAL := help

TAG ?= openshift/online-analytics
DOCKERFILE := Dockerfile

# Builds and installs the user-analytics binary.
build: check-gopath
	go install \
		github.com/openshift/online-analytics/cmd/user-analytics
.PHONY: build


# Runs the unit tests.
#
# Args:
#   TESTFLAGS: Flags to pass to `go test`. The `-v` argument is always passed.
#
# Examples:
#   make test TESTFLAGS="-run TestSomething"
test: build
	go test -v $(TESTFLAGS) \
		github.com/openshift/online-analytics/pkg/...
.PHONY: test


# Precompile everything required for development/test.
test-prepare: build
	go test -i github.com/openshift/online-analytics/test/...
.PHONY: test-prepare


# Runs the integration tests.
#
# Args:
#   TESTFLAGS: Flags to pass to `go test`. The `-v` argument is always passed.
#
# Example:
#   make test-integration
#   make test-integration TESTFLAGS="-run TestIntegration/SubscriptionUpgrade"
test-integration: test-prepare
	go test -v -timeout 1h $(TESTFLAGS) \
		github.com/openshift/online-analytics/test/...
.PHONY: test-integration


# Build a release image. The resulting image can be used with test-release.
#
# Args:
#   TAG: Docker image tag to apply to the built image. If not specified, the
#     default tag "openshift/online-analytics" will be used.
#
# Example:
#   make release TAG="my/online-analytics"
release:
	docker build --rm -f $(DOCKERFILE) -t $(TAG) .
.PHONY: release


# Tests a release image.
#
# Prerequisites:
#   A release image must be built and tagged (make release)
#
# Examples:
#
#   make test-release
#   make test-release TAG="my/online-analytics"
test-release:
	docker run --rm -ti \
		$(DOCKERFLAGS) \
		--entrypoint make \
		$(TAG) \
		test
.PHONY: test-release


# Verifies that source passes standard checks.
verify:
	$(GOPATH)/src/github.com/openshift/online-analytics/hack/verify-source.sh
	go vet \
		github.com/openshift/online-analytics/cmd/... \
		github.com/openshift/online-analytics/pkg/... \
		github.com/openshift/online-analytics/test/...
.PHONY: verify


# Prints a list of useful targets.
help:
	@echo ""
	@echo "OpenShift Online User Analytics"
	@echo ""
	@echo "make build                compile binaries"
	@echo "make test                 run unit tests"
	@echo "make test-integration     run integration tests"
	@echo "make release              build release image using Dockerfile"
	@echo "make test-release         run unit and integration tests in Docker container"
	@echo "make verify               lint source code"
	@echo ""
.PHONY: help


# Checks if a GOPATH is set, or emits an error message
check-gopath:
ifndef GOPATH
	$(error GOPATH is not set)
endif
.PHONY: check-gopath
