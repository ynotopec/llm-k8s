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
