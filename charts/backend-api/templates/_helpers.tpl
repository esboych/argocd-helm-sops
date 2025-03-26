
# charts/backend-api/templates/_helpers.tpl
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "backend-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "backend-api.fullname" -}}
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
{{- define "backend-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "backend-api.labels" -}}
helm.sh/chart: {{ include "backend-api.chart" . }}
{{ include "backend-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "backend-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backend-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

# charts/backend-api/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "backend-api.fullname" . }}-config
  labels:
    {{- include "backend-api.labels" . | nindent 4 }}
data:
  {{- if .Values.env }}
  application.properties: |
    # Application configuration
    {{- range $key, $value := .Values.env }}
    {{ $key | lower | replace "_" "." }}={{ $value }}
    {{- end }}
  {{- end }}