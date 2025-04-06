## Containerizing Applications with Azure Kubernetes Service (AKS)

Welcome to **Video 2** of the [Kubernetes In the Cloud](https://github.com/mamonaco1973/cloud-k8s-intro/blob/main/README.md) series.

**This video complements the [Azure VM Scale Sets](https://github.com/mamonaco1973/azure-flask-vmss/blob/main/README.md) and the [Simple Azure Containers](https://github.com/mamonaco1973/azure-flask-container/blob/main/README.md) projects**, where we deployed a simple Python-based microservice using the Flask framework with different cloud services.

This is a **fully automated deployment** of containerized microservices and web apps with **Azure Kubernetes Service (AKS)** — powered by Terraform and shell scripting.

You'll build and deploy:

- **A document database-backed microservice** using:  
  - **Azure Cosmos DB (SQL API)** for fast, globally distributed NoSQL storage.

- **A Docker container** for the Flask microservice, optimized for deployment to **Azure AKS**.

- **Additional standalone Docker containers** that run classic JavaScript games like **[Tetris](https://gist.github.com/straker/3c98304f8a6a9174efd8292800891ea1)**, **[Frogger](https://gist.github.com/straker/82a4368849cbd441b05bd6a044f2b2d3)**, and **[Breakout](https://gist.github.com/straker/98a2aed6a7686d26c04810f08bfaf66b)**.

- **Cloud-native container registry workflows**, pushing all images to:  
  - **Azure Container Registry (ACR)**.

- **Kubernetes workloads on Azure AKS**, managing containerized applications at scale.

- **Kubernetes manifests** including **Deployments**, **Services**, and **Ingress** resources for scalable, fault-tolerant workloads.

- **NGINX as a unified Ingress controller**, exposing all services and games behind a single **Azure Load Balancer**.
