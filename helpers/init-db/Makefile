IMAGE_REPO="docker.example.com/airlock/db-tools"
VERSION=`awk -F '=' '/ARG VERSION/{print $$2}' Dockerfile`

TS=`date "+%Y/%m/%d %H:%M:%S"`

all:
	docker build . --build-arg BUILD_DATE="$(TS)" -t "${IMAGE_REPO}:${VERSION}"
	docker push "${IMAGE_REPO}:${VERSION}"
