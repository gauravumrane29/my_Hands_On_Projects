{{/*
Expand the name of the chart.
*/}}
{{- define "java-microservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "java-microservice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "java-microservice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "java-microservice.labels" -}}
helm.sh/chart: {{ include "java-microservice.chart" . }}
{{ include "java-microservice.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Values.app.name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "java-microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "java-microservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "java-microservice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "java-microservice.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image name
*/}}
{{- define "java-microservice.image" -}}
{{- if .Values.ecr.enabled }}
{{- if .Values.ecr.accountId }}
{{- printf "%s.dkr.ecr.%s.amazonaws.com/%s:%s" .Values.ecr.accountId .Values.ecr.region .Values.ecr.repositoryName .Values.image.tag }}
{{- else }}
{{- printf "ACCOUNT_ID.dkr.ecr.%s.amazonaws.com/%s:%s" .Values.ecr.region .Values.ecr.repositoryName .Values.image.tag }}
{{- end }}
{{- else }}
{{- if .Values.image.registry }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository .Values.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate environment-specific namespace
*/}}
{{- define "java-microservice.namespace" -}}
{{- if .Values.namespace.create -}}
{{- .Values.namespace.name | default .Release.Namespace }}
{{- else -}}
{{- .Release.Namespace }}
{{- end -}}
{{- end }}

{{/*
Generate AWS region
*/}}
{{- define "java-microservice.awsRegion" -}}
{{- .Values.ecr.region | default "us-east-1" }}
{{- end }}

{{/*
Generate service port configuration
*/}}
{{- define "java-microservice.servicePort" -}}
{{- .Values.backend.service.port | default 80 }}
{{- end }}

{{/*
Generate target port configuration
*/}}
{{- define "java-microservice.targetPort" -}}
{{- .Values.backend.service.targetPort | default 8080 }}
{{- end }}

{{/*
Generate health check path
*/}}
{{- define "java-microservice.healthPath" -}}
{{- "/actuator/health" }}
{{- end }}

{{/*
Generate metrics path
*/}}
{{- define "java-microservice.metricsPath" -}}
{{- "/actuator/prometheus" }}
{{- end }}

{{/*
Create the backend image name
*/}}
{{- define "java-microservice.backendImage" -}}
{{- if .Values.backend.ecr.enabled }}
{{- if .Values.backend.ecr.accountId }}
{{- printf "%s.dkr.ecr.%s.amazonaws.com/%s:%s" .Values.backend.ecr.accountId .Values.backend.ecr.region .Values.backend.ecr.repositoryName .Values.backend.image.tag }}
{{- else }}
{{- printf "ACCOUNT_ID.dkr.ecr.%s.amazonaws.com/%s:%s" .Values.backend.ecr.region .Values.backend.ecr.repositoryName .Values.backend.image.tag }}
{{- end }}
{{- else }}
{{- if .Values.backend.image.registry }}
{{- printf "%s/%s:%s" .Values.backend.image.registry .Values.backend.image.repository .Values.backend.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.backend.image.repository .Values.backend.image.tag }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the frontend image name
*/}}
{{- define "java-microservice.frontendImage" -}}
{{- if .Values.frontend.ecr.enabled }}
{{- if .Values.frontend.ecr.accountId }}
{{- printf "%s.dkr.ecr.%s.amazonaws.com/%s:%s" .Values.frontend.ecr.accountId .Values.frontend.ecr.region .Values.frontend.ecr.repositoryName .Values.frontend.image.tag }}
{{- else }}
{{- printf "ACCOUNT_ID.dkr.ecr.%s.amazonaws.com/%s:%s" .Values.frontend.ecr.region .Values.frontend.ecr.repositoryName .Values.frontend.image.tag }}
{{- end }}
{{- else }}
{{- if .Values.frontend.image.registry }}
{{- printf "%s/%s:%s" .Values.frontend.image.registry .Values.frontend.image.repository .Values.frontend.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.frontend.image.repository .Values.frontend.image.tag }}
{{- end }}
{{- end }}
{{- end }}