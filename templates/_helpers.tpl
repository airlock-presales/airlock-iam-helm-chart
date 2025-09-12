{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "airlock-iam.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "airlock-iam.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "airlock-iam.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "airlock-iam.annotations" -}}
source.info.io/chart: {{ .Values.chartSource }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "airlock-iam.labels" -}}
helm.sh/chart: {{ include "airlock-iam.chart" . }}
{{ include "airlock-iam.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common Selector labels
*/}}
{{- define "airlock-iam.selectorLabels" -}}
app.kubernetes.io/name: {{ include "airlock-iam.fullname" $ }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if and .Values.iam.environmentId (ne .Values.iam.environmentId "") }}
iam.airlock.com/environment: {{ .Values.iam.environmentId }}
{{- end }}
{{- end }}

{{/*
Convert a label map to comma-separated string.
*/}}
{{- define "airlock-iam.toCommaSeparatedList" -}}
{{- $list := list -}}
    {{- range $key, $value := . -}}
        {{- $list = append $list (printf "%s=%s" $key $value) -}}
    {{- end -}}
{{- join "," $list -}}
{{- end }}


{{/*
Map application name to module identifier
*/}}
{{- define "airlock-iam.mapAppName" -}}
{{- if eq . "transactionApproval" -}}
transaction-approval
{{- else if eq . "serviceContainer" -}}
service-container
{{- else if eq . "apiPolicyService" -}}
api-policy-service
{{- else -}}
{{ . }}
{{- end -}}
{{- end }}

{{/*
Get list of modules for combined deployment
*/}}
{{- define "airlock-iam.listActiveModules" -}}
{{- $modules := "" -}}
{{- $name := "" -}}
{{- range $app, $app_values := .Values.iam.apps -}}
{{-   if $app_values.enable -}}
{{-     $name = include "airlock-iam.mapAppName" $app -}}
{{-     if eq $modules "" -}}
{{-       $modules = $name -}}
{{-     else -}}
{{-       $modules = print $modules "," $name -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{ $modules }}
{{- end -}}

{{/*
Get deployment type
*/}}
{{- define "airlock-iam.deploymentType" -}}
{{- $cnt := 0 }}
{{- if .Values.database.external.enable }}
{{-   $cnt = add $cnt 1 -}}
external
{{- end }}
{{- if .Values.database.embedded.mariadb }}
{{-   $cnt = add $cnt 1 -}}
mariadb
{{- end }}
{{- if .Values.database.embedded.postgresql }}
{{-   $cnt = add $cnt 1 -}}
postgresql
{{- end }}
{{- if gt $cnt 1 }}
{{-   fail "Only enable one database type (external, mariadb, postgresql)" }}
{{- end }}
{{- end }}

{{/*
Get database type
*/}}
{{- define "airlock-iam.databaseType" -}}
{{- $deploymentType := include "airlock-iam.deploymentType" . -}}
{{- if or (eq $deploymentType "mariadb") (and (eq $deploymentType "external") (eq $.Values.database.external.type "mariadb")) -}}
mariadb
{{- else if or (eq $deploymentType "postgresql") (and (eq $deploymentType "external") (eq $.Values.database.external.type "postgresql")) -}}
postgresql
{{- else if and (eq $deploymentType "external") (eq $.Values.database.external.type "mysql") -}}
mysql
{{- else if and (eq $deploymentType "external") (eq $.Values.database.external.type "oracle") -}}
oracle
{{- else if and (eq $deploymentType "external") (eq $.Values.database.external.type "mssql") -}}
sqlserver
{{- end }}
{{- end }}

{{/*
Get list of pull secrets for all images
*/}}
{{- define "airlock-iam.listPullSecrets" -}}
{{- $images := "" -}}
{{- $sep := "" -}}
{{- if ne .Values.images.iam.pullSecret "" -}}
{{-   $images = .Values.images.iam.pullSecret -}}
{{-   $sep = "," -}}
{{- end -}}
{{- if ne .Values.images.initdb.pullSecret "" -}}
{{-   $images = print $images $sep .Values.images.initdb.pullSecret -}}
{{- end -}}
{{ $images }}
{{- end -}}

