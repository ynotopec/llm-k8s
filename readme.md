# Automated Installation Script for LLM on Kubernetes

This script allows for the automatic installation and configuration of large language models (LLM) in a Kubernetes environment.

## Prerequisites

- A CUDA-compatible GPU.
- NVIDIA OPERATOR installed on your Kubernetes cluster.

## Installation Script

```bash
#!/bin/bash

# Define the base path for LLM models
# Add " xb" when necessary. Example : "openchat/openchat_3.5 7b"
modelPathList="lmsys/vicuna-33b-v1.3
lmsys/vicuna-7b-v1.5-16k
lmsys/fastchat-t5-3b-v1.0
HuggingFaceH4/zephyr-7b-beta
openchat/openchat_3.5 7b"

#bofenghuang/vigogne-13b-instruct
#mistralai/Mistral-7B-Instruct-v0.1
#OpenLLM-France/Claire-7B-0.1
#teknium/OpenHermes-2.5-Mistral-7B
#mistralai/Mistral-7B-v0.1

# Set the root domain
export rootDomain=example.com

# Clone the Helm repository and move into the folder
git clone https://github.com/gmougeolle/fastchat-helm
cd fastchat-helm
#git checkout

# Add Ingress API
cat <<EOT >./templates/fastchat-api-ingress.yaml
{{- if .Values.webserver.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
  name: {{ include "fastchat-helm.fullname" . }}-api
  labels:
  {{- include "fastchat-helm.labels" . | nindent 4 }}
spec:
  tls:
  - hosts:
    - {{ .Values.api.ingress.hostname }}
    secretName: {{ .Values.api.ingress.hostname }}-tls
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

# Template values
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
  extraParams: [ "--model-names","${modelName},gpt-4,gpt-3.5-turbo-instruct,gpt-3.5-turbo,gpt-3.5-turbo-16k,text-embedding-ada-002" ]
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

# Loop to process each model path
echo "${modelPathList}" | while read modelPath2; do
  export modelPath=$(echo "${modelPath2}" |sed -rn 's#^([^[:space:]]+)([[:space:]].*|)$#\1#p' )
  export modelName=$(basename "${modelPath}" |sed -rn 's#^(|[0-9]+[bB][^[:alnum:]]+)([[:alnum:]]+)([^[:alnum:]].*|)$#\2#p' |tr '[:upper:]' '[:lower:]' )
  export modelSize=$(basename "${modelPath2}" |sed -rn 's#^(|.*[^0-9])([0-9]+)[bB]([^[:alnum:]].*|)$#\2#p' )
  export storageRequest=$((modelSize * 3))Gi
  export gpuLimit=1

  # Generate the values.yaml file for each model
  envsubst < ./values.yaml.tpl > ${modelName}-values.yaml

  # Install or update the model via Helm
  helm upgrade --install ${modelName} . -f ${modelName}-values.yaml -n ${modelName} --create-namespace
done

# Workaround fix
sleep 600
echo "${modelPathList}" | while read modelPath2; do
  export modelPath=$(echo "${modelPath2}" |sed -rn 's#^([^[:space:]]+)([[:space:]].*|)$#\1#p' )
  export modelName=$(basename "${modelPath}" |sed -rn 's#^(|[0-9]+[bB][^[:alnum:]]+)([[:alnum:]]+)([^[:alnum:]].*|)$#\2#p' |tr '[:upper:]' '[:lower:]' )

  # Delete necessary pods to apply the new configuration
  kubectl -n ${modelName} get pod -o name | grep -E "(fastchat-helm-web-server|fastchat-api)" | xargs kubectl -n ${modelName} delete
done
```

## Usage Instructions

1. Run the script on a system where `kubectl` and `helm` are installed and configured to communicate with your Kubernetes cluster.
2. The script will automatically clone the necessary repository, create configurations, and deploy each specified LLM model in `modelPathList`.

## Note

- This script is designed to be as automated as possible. However, it may require adjustments depending on the specific environment of your Kubernetes cluster and the requirements of the LLM models.
- Ensure that your cluster has the necessary resources (GPU, storage, etc.) to support the deployed models.
