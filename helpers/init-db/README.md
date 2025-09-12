# Container image for database initialisation

## Description

The Helm chart allows to automatically initialise and upgrade the database for Airlock IAM.
This is handled by a [script](../../_include/init_db) executed in an init container.

Currently, the script requires the following CLI commands:

* mariadb / mysql / psql - depending on database type
* pg_isready for PostgreSQL
* curl
* ls, grep, sed, wc

## Alternatives

Other container images can be used, too, for example, the official MariaDB image <code>mariadb:12-ubi</code>.

The official PostgreSQL image, however, lacks the curl command.

## Installation

1. Clone the repository:
    ```
    git clone https://github.com/airlock-presales/airlock-iam-helm-chart/
    cd airlock-iam-helm-chart/helpers/init-db
    ```
1. Set the parameters
    ```
    export IMAGE_REPO=docker.example.com/airlock/db-tools
    export VERSION="$(awk -F '=' '/ARG VERSION/{print $2}' Dockerfile)"
    ```
1. Build the container image
    ```
    docker build . --build-arg BUILD_DATE="$(date "+%Y/%m/%d %H:%M:%S")" -t "${IMAGE_REPO}:${VERSION}"
    ```
1. Upload the image to your local repository
    ```
    docker push "${IMAGE_REPO}:${VERSION}"
    ```
1. Update <code>custom.yaml</code> with:
    ```
    images:
      initdb:
        repository: 'docker.example.com/airlock/db-tools'
        tag: '0.0.2'
    ```
