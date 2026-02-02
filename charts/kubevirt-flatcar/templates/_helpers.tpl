{{- define "kubevirt-flatcar.fullname" -}}
{{- printf "%s" .Release.Name -}}
{{- end -}}

{{- define "kubevirt-flatcar.namespace" -}}
{{- if .Values.global.namespace -}}
{{ .Values.global.namespace }}
{{- else -}}
{{ .Release.Namespace | default "default" }}
{{- end -}}
{{- end -}}
