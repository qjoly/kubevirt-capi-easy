{{- define "kubevirt-talos.fullname" -}}
{{- printf "%s" .Release.Name -}}
{{- end -}}

{{- define "kubevirt-talos.namespace" -}}
{{- if .Values.global.namespace -}}
{{ .Values.global.namespace }}
{{- else -}}
{{ .Release.Namespace | default "default" }}
{{- end -}}
{{- end -}}

{{- define "kubevirt-talos.talosCiliumInlineManifest" -}}
{{- $cilium := .cilium -}}
{{- $image := default "quay.io/cilium/cilium-cli-ci:latest" $cilium.image -}}
{{- $kubeProxyReplacement := true -}}
{{- if hasKey $cilium "kubeProxyReplacement" -}}
  {{- $kubeProxyReplacement = $cilium.kubeProxyReplacement -}}
{{- end -}}
{{- $hostLegacyRouting := false -}}
{{- if hasKey $cilium "hostLegacyRouting" -}}
  {{- $hostLegacyRouting = $cilium.hostLegacyRouting -}}
{{- end -}}
{{- $hubbleEnabled := true -}}
{{- if hasKey $cilium "hubbleEnabled" -}}
  {{- $hubbleEnabled = $cilium.hubbleEnabled -}}
{{- end -}}
{{- $routingMode := default "tunnel" $cilium.routingMode -}}
{{- $tunnelProtocol := default "geneve" $cilium.tunnelProtocol -}}
{{- $kubeProxyReplacementStr := ternary "true" "false" $kubeProxyReplacement -}}
{{- $hostLegacyRoutingStr := ternary "true" "false" $hostLegacyRouting -}}
{{- $hubbleEnabledStr := ternary "true" "false" $hubbleEnabled -}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cilium-install
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: cilium-install
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cilium-install
  namespace: kube-system
---
apiVersion: batch/v1
kind: Job
metadata:
  name: cilium-install
  namespace: kube-system
spec:
  backoffLimit: 10
  template:
    metadata:
      labels:
        app: cilium-install
    spec:
      restartPolicy: OnFailure
      tolerations:
        - operator: Exists
        - effect: NoSchedule
          operator: Exists
        - effect: NoExecute
          operator: Exists
        - effect: PreferNoSchedule
          operator: Exists
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoExecute
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: PreferNoSchedule
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-role.kubernetes.io/control-plane
                    operator: Exists
      serviceAccount: cilium-install
      serviceAccountName: cilium-install
      hostNetwork: true
      containers:
      - name: cilium-install
        image: {{ $image }}
        env:
        - name: KUBERNETES_SERVICE_HOST
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: KUBERNETES_SERVICE_PORT
          value: "6443"
        command:
        - cilium
        - install
        - --set
        - ipam.mode=kubernetes
        - --set
        - kubeProxyReplacement={{ $kubeProxyReplacementStr }}
        - --set
        - securityContext.capabilities.ciliumAgent={CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}
        - --set
        - securityContext.capabilities.cleanCiliumState={NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}
        - --set
        - cgroup.autoMount.enabled=false
        - --set
        - cgroup.hostRoot=/sys/fs/cgroup
        - --set
        - k8sServiceHost=localhost
        - --set
        - k8sServicePort=7445
        - --set
        - bpf.hostLegacyRouting={{ $hostLegacyRoutingStr }}
        - --set
        - bpf.masquerade=true
        - --set
        - nodePort.enabled=true
        - --set
        - routingMode={{ $routingMode }}
        - --set
        - tunnelProtocol={{ $tunnelProtocol }}
        - --set
        - socketLB.enabled=true
        - --set
        - hubble.enabled={{ $hubbleEnabledStr }}
        - --set
        - hubble.relay.enabled={{ $hubbleEnabledStr }}
{{- end -}}
