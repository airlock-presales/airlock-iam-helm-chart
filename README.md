# 🚀 Welcome to the Airlock IAM Helm Chart - by Airlock Pre-Sales

*Airlock IAM is a comprehensive authentication and identity management solution for web applications and services that features a high degree of customization.*

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/iam-helm-charts/main/media/Airlock_IAM_Icon.svg" alt="IAM Logo" width="250">
</p>

It can be installed either as a Self-Contained Application (SCA), directly on top of a Linux operating system. Or, as a container on a Docker host or in a Kubernetes cluster.

For the latter, a Helm chart is an easy option to generate and maintain the required manifests.

In stark contrast to the "official" [charts](https://github.com/airlock/iam-helm-charts/), this chart here can actually be used to create a working deployment.

## Disclaimer

This is not an official chart. It is maintained by the Airlock Pre-Sales team, as time permits, on a best-efforts basis. Still, we welcome bug reports (issues) and PRs.

## Cluster requirements

The Kubernetes cluster must comply with the following requirements:

* At least one storage class available, potentially with support for ReadWriteMany
* One of the following ingress solutions must be installed and configured
  * Kubernetes Gateway API
  * Ingress
  * Project Contour HttpProxy

## Deployment layout

### Overview
Airlock IAM is a very powerful authentication engine, supporting many different use cases - [click for details](https://www.airlock.com/secure-access-hub/komponenten/iam). It consists of multiple web applications, uses a database, and can make use of Redis. Consequently, there are different ways to deploy it.

<p align="left">
  <img src="media/shared_white.png" alt="shared deployment" height="250">
</p>

Foremost, the web applications can either be kept together, as a single deployment, or they can all be managed as their individual (sandboxed) deployment, and anything in between. The advantage of the former option is its ease of use and administration. Upon activation, configuration changes are automatically distributed to all components which take it up immediately. iOn the other hand, it is impossible to individually scale independent web applications. Therefore, the combined, or shared, deployment layout is geared towards test environments and proof-of-concepts.

<p align="left">
  <img src="media/sandboxed_white.png" alt="sandboxed deployment" height="400">
</p>

For a production environment, it is paramount to be able to freely scale the customer-facing loginapp and transaction approval while, for example, there always must only be one replica of the service container.

By the way, using the new YAML config format, configuration environments, and GitOps, config changes can also be easily and automatically distributed across your whole setup.

### Configuration

Use the following settings in <code>values.yaml</code> to define your deployment layout:

    iam:
      apps:
        loginapp:
          enable: true | false
          sandbox:
            enable: true | false
        adminapp:
          enable: true | false
          sandbox:
            enable: true | false
        transactionApproval:
          enable: true | false
          sandbox:
            enable: true | false
        ...

## Instance directory

### Storage considerations

Each Airlock IAM instance requires a so-called instance directory which contains:

* Application configuration
* UI resources
* Instance settings in <code>instance.properties</code>

All applications of the same instance must have access to the same content. How you achieve that is up to you but one obvious, simple way is to mount the same volume into all deployments. This requires a type of storage supporting ReadWriteMany or ReadOnlyMany, if you have at least one sandboxed application.

Unfortunately, logging may make the situation a bit more complicated. If you opt to have Airlock IAM ship to an Elasticsearch server, each replica will forcibly first write the logs to files before they are forwarded. By default, these files are also in the instance directory, leading to concurrent write access on text files.

To alleviate this challenge, the Helm chart uses StatefulSets if the number of replicas is greater than 1. It will also mount a dedicated volume onto the logs directory. It is best to make sure reasonable values have been set for persistence to avoid problems. Understand that persistence can be defined "globally" in <code>persistence</code> as well as per applications <code>iam.apps.\<application-name\>.sandbox.persistence</code>, with the latter overriding the former.

### <code>instance.properties</code>

For many settings in <code>instance.properties</code>, the Helm chart provides easy configuration possibilities, in <code>iam.apps.\<application-name\>.path</code> and <code>iam.instanceProperties[]</code>. There are also multiple sections to define environment variables which can be used to almost all other settings, e.g. in <code>iam.apps.\<application-name\>.sandbox.env</code>, <code>iam.instanceProperties[].env</code>, and <code>env</code>. Finally, a few settings are pre-defined in the Helm chart and should not be overriden:

* IAM_CONFIG_FORMAT
* IAM_HEALTH_PORT
* IAM_MODULES
* IAM_WEB_SERVER_HTTPS_PORT
* IAM_WEB_SERVER_HTTP_PORT

## Other important settings

* If any application has more than one replica, it is strongly recommended to enable Redis in <code>redis.enable</code> and configure an <code>Expert Mode Redis State Repository</code> in Airlock IAM.
* Hostname and TLS certificate in <code>ingress.dns.hostname</code> and <code>ingress.tls.secretName</code>, respectively.
* The required version of Airlock in in <code>image.tag</code>

## Preparations

* Create the pull secret as Airlock IAM images are not publicly available on Quay.io using these [instructions](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).
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