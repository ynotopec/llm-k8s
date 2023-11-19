# Script d'Installation Automatisé pour LLM sur Kubernetes

Ce script permet d'installer et de configurer automatiquement des modèles de langage de grande taille (LLM) dans un environnement Kubernetes.

## Prérequis

- Un GPU compatible CUDA.
- NVIDIA OPERATOR installé sur votre cluster Kubernetes.

## Script d'Installation

```bash
#!/bin/bash

# Définir le chemin de base pour les modèles LLM
modelPathList="bofenghuang/vigogne-13b-instruct
mistralai/Mistral-7B-Instruct-v0.1
lmsys/vicuna-13b-v1.5"

# Définir le domaine racine
export rootDomain=example.com

# Cloner le dépôt de Helm et se déplacer dans le dossier
git clone https://github.com/gmougeolle/fastchat-helm
cd fastchat-helm

# Ajout Ingress API
cat <<EOT >./templates/fastchat-api-ingress.yaml
{{- if .Values.webserver.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
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

# Boucle pour traiter chaque chemin de modèle
echo "${modelPathList}" | while read modelPath; do
  export modelPath=${modelPath}
  export modelName=$(echo ${modelPath} | awk -F '/' '{print $2}' | awk -F '-' '{print $1}' | tr '[:upper:]' '[:lower:]')
  export modelSize=$(echo ${modelPath} | awk -F '-' '{print $2}' | tr -dc '0-9')
  export storageRequest=$((modelSize * 3))Gi
  export gpuLimit=1

  # Générer le fichier values.yaml pour chaque modèle
  envsubst < ./values.yaml.tpl > ${modelName}-values.yaml

  # Installer ou mettre à jour le modèle via Helm
  helm upgrade --install ${modelName} . -f ${modelName}-values.yaml -n ${modelName} --create-namespace
done

# Fix de contournement
sleep 60
echo "${modelPathList}" | while read modelPath; do
  export modelPath=${modelPath}
  export modelName=$(echo ${modelPath} | awk -F '/' '{print $2}' | awk -F '-' '{print $1}' | tr '[:upper:]' '[:lower:]')

  # Supprimer les pods nécessaires pour appliquer la nouvelle configuration
  kubectl -n ${modelName} get pod -o name | grep -E "(fastchat-helm-web-server|fastchat-api)" | xargs kubectl -n ${modelName} delete
done
```

## Instructions d'Utilisation

1. Exécutez le script sur un système où `kubectl` et `helm` sont installés et configurés pour communiquer avec votre cluster Kubernetes.
2. Le script va automatiquement cloner le dépôt nécessaire, créer les configurations, et déployer chaque modèle LLM spécifié dans `modelPathList`.

## Note

- Ce script est conçu pour être le plus automatisé possible. Cependant, il peut nécessiter des ajustements en fonction de l'environnement spécifique de votre cluster Kubernetes et des exigences des modèles LLM.
- Assurez-vous que votre cluster dispose des ressources nécessaires (GPU, stockage, etc.) pour supporter les modèles déployés.
