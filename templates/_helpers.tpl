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
app.kubernetes.io/name: {{ default .IAM_the_name (include "airlock-iam.fullname" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .IAM_suffix }}
app.kubernetes.io/component: {{ .IAM_suffix }}
{{- end }}
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
Get list of modules for shared deployment
*/}}
{{- define "airlock-iam.listModulesShared" -}}
{{- $modules := "" -}}
{{- $name := "" -}}
{{- range $app, $app_values := .Values.iam.apps -}}
{{-   if and $app_values.enable (not $app_values.sandbox.enable) -}}
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
Check if shared deployment is required
*/}}
{{- define "airlock-iam.hasShared" -}}
{{- $result := false -}}
{{- range $app, $app_values := .Values.iam.apps -}}
{{-   if and $app_values.enable (not $app_values.sandbox.enable) -}}
{{-     $result = true -}}
{{-   end -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{/*
Check if at least one app is sandboxed
*/}}
{{- define "airlock-iam.hasSandbox" -}}
{{- $result := false -}}
{{- range $app, $app_values := .Values.iam.apps -}}
{{-   if and $app_values.enable $app_values.sandbox.enable -}}
{{-     $result = true -}}
{{-   end -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{/*
Find service for app
*/}}
{{- define "airlock-iam.findService" -}}
{{- $values := .values -}}
{{- $suffix := .suffix -}}
{{- $idxSvc := -1 -}}
{{- $idxNoSuffix := -1 -}}
{{- $idx := -1 -}}
{{- range $svc := $.Values.service -}}
{{-   $idx = $idx +1 -}}
{{-   if $svc.enable -}}
{{-     if eq $svc.suffix "" -}}
{{-       $idxNoSuffix = $idx -}}
{{-     else if eq $svc.suffix $suffix -}}
{{-       $idxSvc = $idx -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- if ne $idxSvc -1 -}}
{{ $idxSvc }}
{{- else -}}
{{ $idxNoSuffix }}
{{- end -}}
{{- end -}}

