Sure, here's a documentation write-up for the provided script:

---

# LLM K8S Install Documentation

This documentation outlines the process for setting up a Kubernetes (K8S) environment to deploy Large Language Models (LLMs) using Helm charts. The setup involves configuring a webserver, API, and a model worker for various LLMs.

## Prerequisites

Before you begin, ensure you have the following prerequisites:

- CUDA GPU: A CUDA-compatible GPU is required for running the models.
- NVIDIA OPERATOR: This should be installed and configured on your Kubernetes cluster.

## Installation Steps

1. **Set the Model Path List**: Define the model paths for the LLMs you wish to deploy. For example:

   ```bash
   modelPathList="bofenghuang/vigogne-13b-instruct
   mistralai/Mistral-7B-Instruct-v0.1
   lmsys/vicuna-13b-v1.5"
   ```

2. **Configure the Domain**: Set the root domain for your services:

   ```bash
   export rootDomain=numerique-interieur.com
   ```

3. **Clone the Helm Chart Repository**:

   ```bash
   git clone https://github.com/gmougeolle/fastchat-helm
   cd fastchat-helm
   ```

4. **Create the Ingress Configuration**: Use the provided template to create an ingress configuration for the fastchat API.

5. **Configure Values**: Edit `values.yaml.tpl` to set various configurations such as webserver, API, controller, and model worker settings.

6. **Deploy the Models**: Run the provided script to deploy each model in the `modelPathList`. The script performs the following actions for each model:
   
   - Sets environment variables based on the model path.
   - Generates a `values.yaml` file for the Helm chart.
   - Uninstalls any existing Helm release for the model.
   - Deletes the Kubernetes namespace for the model.
   - Installs the Helm chart for the model in a new namespace.

7. **Restart Necessary Pods**: After deployment, the script restarts certain pods to ensure that the new configurations are applied.

## Notes

- The script assumes familiarity with Helm, Kubernetes, and the use of environment variables in shell scripts.
- Customizations may be necessary based on the specific requirements of your Kubernetes environment and the models you are deploying.
- Ensure that your Kubernetes cluster has the necessary resources (GPUs, storage, etc.) to support the deployed models.

---

This documentation provides a basic overview of the installation process. Depending on your specific use case and environment, additional configuration or steps may be necessary.
