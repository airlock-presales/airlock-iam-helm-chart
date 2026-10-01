REGISTRY=quay.io/miniboat/charts
VERSION=`grep ^version: Chart.yaml | sed -e 's,.*: ,,'`

all:
	@echo "Targets:"
	@echo "  build        Build Helm chart (version: ${VERSION})"
	@echo "  push         Upload chart to ${REGISTRY}"

.PHONY: build
build:
	helm package .

.PHONY: push
push:
	helm push iam-${VERSION}.tgz oci://${REGISTRY}
