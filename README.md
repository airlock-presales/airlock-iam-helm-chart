# 🚀 Welcome to the Airlock IAM Helm Chart - by Airlock Pre-Sales

*Airlock IAM is a comprehensive authentication and identity management solution for web applications and services that features a high degree of customization.*

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/iam-helm-charts/main/media/Airlock_IAM_Icon.svg" alt="IAM Logo" width="250">
</p>

It can be installed either as a Self-Contained Application (SCA), directly on top of a Linux operating system. Or, as a container on a Docker host or in a Kubernetes cluster.

For the latter, a Helm chart is an easy option to generate and maintain the required manifests.

As of now, there is unfortunately no official chart. To simplify deploying Airlock IAM on Kubernets / OpenShift, the pre-sales team got to work. :-)

## Disclaimer

This is not an official chart. It is maintained by the Airlock Pre-Sales team, as time permits, on a best-efforts basis. Still, we welcome bug reports (issues) and PRs.

Also note, the chart is work in progress. Not all features and possible configurations have been tested and the structure of the configuration parameters may always change.

## Who is this for?

This Helm chart is for anybody who is tasked with bringing up a running, ready-to-use (or at least ready-to-configure) instance of Airlock IAM on a Kubernetes/OpenShift cluster. This encompasses proof-of-concepts, test and production instances.

## Versioning ##

Each release version of this Helm chart is tagged according to following strategy:

* Minor version of Airlock IAM it supports
* Release counter of chart

Current version: 8.5.0
* Supported IAM versions: 8.5.0, 8.5.1 etc.

## Cluster requirements

The Kubernetes cluster must comply with the following requirements:

* At least one storage class available, potentially with support for ReadWriteMany
* One of the following ingress solutions must be installed and configured
  * Airlock Microgateway
  * Kubernetes Gateway API
  * Ingress
  * Project Contour HttpProxy

# Designing an Airlock IAM deployment

## Deployment layout

### Overview
Airlock IAM is a very powerful authentication engine, supporting many different use cases - [click for details](https://www.airlock.com/secure-access-hub/components/iam). It consists of multiple web applications, uses a database, and can make use of Redis. Consequently, there are different ways to deploy it.

### iam.appDeploymentStrategy: 'single'

Foremost, the web applications can either be kept together, as a single deployment, or they can all be managed as their individual (sandboxed) deployments (see next section). The advantage of the former option is its ease of use and administration. Upon activation, configuration changes are automatically distributed to all components which take it up immediately. On the other hand, it is impossible to individually scale independent web applications. Also, modules like the Service Container must not be running multiple times. Therefore, the combined deployment layout is geared towards test environments and proof-of-concepts and their replica count is fixed to 1.

<p align="left">
  <img src="media/shared_white.png" alt="combined deployment" height="250">
</p>

### iam.appDeploymentStrategy: 'multi'

For a production environment, it is paramount to be able to freely scale the customer-facing loginapp and, potentially also, transaction approval while, for example, there always must only be one replica of the service container.

<p align="left">
  <img src="media/sandboxed_white.png" alt="sandboxed deployment" height="400">
</p>

By the way, using the new YAML config format, configuration environments, and GitOps, config changes can also be easily and automatically distributed across your whole setup, even with multiple deployments.

### Configuration

Use the following settings in <code>values.yaml</code> to define your deployment layout:

    iam:
      appDeploymentStrategy: single | multi
      apps:
        loginapp:
          enable: true | false
        adminapp:
          enable: true | false
        transactionApproval:
          enable: true | false
        ...

## Instance directory

### Storage considerations

Each Airlock IAM instance requires a so-called instance directory which contains:

* Application configuration
* UI resources
* Instance settings in <code>instance.properties</code>

All applications of the same instance must have access to the same content. How you achieve that is up to you but one obvious, simple way is to mount the same volume into all deployments. This requires a type of storage supporting ReadWriteMany or ReadOnlyMany, if you have chosen appDeploymentStrategy 'multi'.

Unfortunately, logging may make the situation a bit more complicated. If you opt to have Airlock IAM ship logs to an Elasticsearch server, each replica will forcibly first write the logs to files before they are forwarded. By default, these files are also in the instance directory, leading to concurrent write access on text files.

To alleviate this challenge, the Helm chart forces an emptyDir() volume on the logs subdirectory and turns of local logging, if the number of replicas is greater than 1.

### <code>instance.properties</code>

For many settings in <code>instance.properties</code>, the Helm chart provides easy configuration possibilities, in <code>iam.apps.\<application-name\></code> and <code>iam.instanceProperties[]</code>. There are also multiple sections to define environment variables which can be used to adjust almost all other settings, e.g. in <code>iam.apps.\<application-name\>.dedicatedDeployment.env</code>, <code>iam.instanceProperties[].env</code>, and <code>env</code>.

Finally, a few settings are pre-defined in the Helm chart and should not be overwritten:

* IAM_CONFIG_FORMAT
* IAM_HEALTH_PORT
* IAM_MODULES
* IAM_WEB_SERVER_HTTPS_PORT
* IAM_WEB_SERVER_HTTP_PORT

## Other important settings

* Hostname and TLS certificate in <code>ingress.dns.hostname</code> and <code>ingress.tls.secretName</code>, respectively.
* If any application has more than one replica, it is strongly recommended to enable Redis in <code>redis.enable</code> and configure an <code>Expert Mode Redis State Repository</code> in Airlock IAM.
  * Due to limitations in the Helm dependency condition syntax, this can unfortunately not be automated.
  * For simplification, the Helm charts sets the following environment variable:
    * IAM_CFG_REDIS_EXPERT_CONFIG
  * In your <code>iam-config.yaml</code> make sure that the <code>stateRepository</code> config contains the following:
  ```
  yamlConfig:
    - value: "sentinelServersConfig: \n  connectTimeout: 10000 \n  masterName: \"mymaster\" \n  sentinelAddresses: \n  - \"redis://redis1:2812\" \n  - \"redis://redis2:2813\"  "
      var:
        name: IAM_CFG_REDIS_EXPERT_CONFIG

  ```

## What about the Airlock IAM version?

Thare is more to switching Airlock IAM versions than just chaning the image tag <code>images.iam.tag</code>. Each release may feature new environment variables and, most especially, new manifests for Airlock Microgateway. It is, therefore, recommended to just leave <code>images.iam.tag</code> alone. It is set by the Helm chart itself which is versioned according to the Airlock IAM version.

## Database setup

With the exception of a few special use cases, Airlock IAM requires an SQL database. The Helm chart supports embedded provisioning of two different database engines, MariaDB and PostgreSQL (see [below](#installing-airlock-iam) for details). In addition, it can interface with exisiting, previously deployed database systems. In this case, MySQL, MS SQL and Oracle are also supported.

How Airlock IAM accesses this database is defined in the application configuration. By default, this configuration is maintained with the built-in Config Editor. However, using environment variables, the Helm chart can provide the necessary configuration information for its database setup to Airlock IAM.

The chart sets the following environment variables:

* IAM_DB_DRIVER_CLASS
* IAM_DB_URL
* IAM_DB_USERNAME
* IAM_DB_PASSWORD

To ensure Airlock IAM respects these variables, search for the key sqlDataSource in the configuration file <code>iam-config.yaml</code> and adapt according to the following:

    sqlDataSource:
      type: com.airlock.iam.core.misc.impl.persistency.db.JdbcConnectionPool
      displayName: Env-var-controlled Database Connection
      properties:
        driverClass:
        - value: org.mariadb.jdbc.Driver
          var:
            name: IAM_DB_DRIVER_CLASS
        password:
        - value: password
          var:
            name: IAM_DB_PASSWORD
            sensitive: true
        url:
        - value: jdbc:mariadb://localhost:3306/iam73
          var:
            name: IAM_DB_URL
        user:
        - value: airlock_iam
          var:
            name: IAM_DB_USERNAME

By the way, starting with Airlock IAM 8.5, the built-in Start Config already contains these settings.

# Installing Airlock IAM

## Preparations

* Airlock IAM images are hosted on Quay.io but are not publicly accessible. Create the necessary pull secret using these [instructions](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). Make sure the referenced user account has been authorised to pull Airlock images - open a ticket on [Airlock Jira](https://jira.airlock.com) to get this done.
* Create a ConfigMap or Secret with the license:
```
    kubectl create secret generic \<name\> --from-file=license.txt=\<filename\>
    kubectl create configmap \<name\> --from-file=license.txt=\<filename\>
```
* Create <code>custom.yaml</code> with your settings
```
    cp values.yaml custom.yaml
    vi custom.yaml
```
  * Set <code>iam.license.type</code> to the resource kind used for the license.
  * You must setup the correct settings for section 'ingress:'
  * You very probably should check the settings for sections 'persistence:' and 'database:'

## Embedded database

In your <code>custom.yaml</code>, you have the option to concurrently deploy a database. If you uninstall Airlock IAM using <code>helm uninstall ...</code>, the database will also be stopped.

Due to the Bitnami situation embedding can no longer rely on sub-charts. Instead, the requested database is deployed using its appropriate operator which must be installed and setup beforehand.

* MariaDB
  * Setup [MariaDB Community Operator](https://github.com/mariadb-operator/mariadb-operator)
  * Installation [documentation](https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/helm.md)
  * As of 2025-09-11, the following worked
    ```
    helm repo add mariadb-operator https://helm.mariadb.com/mariadb-operator
    helm install mariadb-operator-crds mariadb-operator/mariadb-operator-crds

    helm install mariadb-operator mariadb-operator/mariadb-operator \
    --set webhook.cert.certManager.enabled=true -n mariadb-system --create-namespace
    ```

* PostgreSQL
  * Setup [CloudNativePG](https://cloudnative-pg.io/)
  * Installation [documentation](https://cloudnative-pg.io/documentation/1.27/installation_upgrade/)
  * As of 2025-09-11, the following worked
    ```
    curl -sSfL https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh | \
    sudo sh -s -- -b /usr/local/bin

    kubectl apply --server-side -f \
    https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.27/releases/cnpg-1.27.0.yaml
    
    kubectl rollout status deployment -n cnpg-system cnpg-controller-manager

    kubectl apply -f \
    https://raw.githubusercontent.com/cloudnative-pg/postgres-containers/main/Debian/ClusterImageCatalog-bookworm.yaml
    ```
  * **WARNING --- Possible Data Loss**

    Please note: as of the time of writing, CloudNativePG forcibly removes an existing database upon (re-)start of the engine. The Internet mentions workarounds which are, however, rather cumbersome and require lots of manual interventions to get an existing database safely up and running again.

    The possibility to use an embedded PostgreSQL database managed by the CloudNativePG operator is still maintained in the Helm chart. However, due to the above-mentioned shortcoming, it is very strongly recommended to define it as "external" (<code>database.external.enable</code>). The CloudNativePG operator can still be used for this but the manifests must be defined and deployed outside of this Helm chart. This way, data loss inadvertently caused by <code>helm upgrade</code> can be avoided.

    You have been warned!

## Installation

Run Helm to create the Airlock IAM deployment:

```
    helm install airlock-iam . -f custom.yaml --namespace airlock-iam --create-namespace
```
