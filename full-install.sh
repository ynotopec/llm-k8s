#!/bin/bash

modelPathList="OpenLLM-France/Claire-7B-0.1"

export rootDomain=example.com

cd
git clone https://github.com/gmougeolle/fastchat-helm
cd fastchat-helm

cat <<EOT >./templates/fastchat-api-ingress.yaml
{{- if .Values.webserver.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "fastchat-helm.fullname" . }}-api
  labels:
  {{- include "fastchat-helm.labels" . | nindent 4 }}
spec:
  rules:
  - host: {{ .Values.api.ingress.hostname }}
    http:
      paths:
      - backend:
          service:
            name: '{{ include "fastchat-helm.fullname" . }}-api'
            port:
              number: 8001
        path: /
        pathType: Prefix
{{- end }}
EOT

cat <<'EOT' >./values.yaml.tpl
webserver:
  enabled: true
  extraParams: []
  fastchatWebserver:
    image:
      repository: gmougeolle/fastchat
      tag: latest
  replicas: 1
  ingress:
    enabled: true
    hostname: ${modelName}.${rootDomain}
api:
  enabled: true
  extraParams: []
  fastchatAPI:
    image:
      repository: gmougeolle/fastchat
      tag: latest
  replicas: 1
  ingress:
    enabled: true
    hostname: api-${modelName}.${rootDomain}
controller:
  enabled: true
  extraParams: []
  fastchatController:
    image:
      repository: gmougeolle/fastchat
      tag: latest
  ports:
  replicas: 1
kubernetesClusterDomain: cluster.local
modelWorker:
  enabled: true
  extraParams: [ "--model-names","${modelName},gpt-3.5-turbo,text-davinci-003,text-embedding-ada-002" ]
  gpuBrand: nvidia.com/gpu
  gpuLimit: ${gpuLimit}
  fastchatModelWorker:
    modelPath: ${modelPath}
    image:
      repository: gmougeolle/fastchat
      tag: latest
  replicas: 1
pvc:
  huggingface:
    storageRequest: ${storageRequest}
EOT

echo "${modelPathList}" |while read modelPath ;do
  export modelPath=${modelPath}
  export modelName=$(basename ${modelPath} |sed -rn 's#^([^-]+)-.*$#\1#p' |tr '[:upper:]' '[:lower:]' )
  export modelSize=$(basename ${modelPath} |sed -rn 's#^([^-]+)-([0-9]+)[bB].*$#\2#p' )
  export storageRequest=$((modelSize * 3 ))Gi
  export gpuLimit=1
  cat values.yaml.tpl |envsubst >${modelName}-values.yaml
  helm uninstall ${modelName} -n ${modelName}
  kubectl delete ns ${modelName}
  helm upgrade --install ${modelName} . -f ${modelName}-values.yaml -n ${modelName} --create-namespace
done

echo "${modelPathList}" |while read modelPath ;do
  export modelName=$(basename ${modelPath} |sed -rn 's#^([^-]+)-.*$#\1#p' |tr '[:upper:]' '[:lower:]' )
  kubectl -n ${modelName} get pod -o name |grep -E "(fastchat-helm-web-server|fastchat-api)" |xargs kubectl -n ${modelName} delete
done
