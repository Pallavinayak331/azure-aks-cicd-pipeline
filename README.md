# Azure End-to-End DevOps Pipeline — Provisioning to Production

A complete DevOps workflow built and executed on Azure: infrastructure
provisioned via the Azure Portal and CLI, a containerized app built and
pushed through Azure Container Registry, deployed to Azure Kubernetes
Service, and automated end-to-end with an Azure DevOps CI/CD pipeline —
including a Kubernetes health-check gate before every release, and Azure
Boards configured with sprint planning and workflow automation.

Every step below was executed and verified live (not just written as code) —
screenshots of each stage are in [`docs/screenshots/`](docs/screenshots/).

## What this demonstrates

- Provisioning secure Azure infrastructure from scratch (networking, storage, compute)
- Building, tagging, and pushing a Docker image to a private container registry
- Deploying and exposing an application on a managed Kubernetes cluster
- Designing a CI/CD pipeline with a **scripted health-check gate** — deployment
  only proceeds if the cluster is verified healthy first
- Configuring Agile project tracking with a custom workflow automation rule

## Architecture
