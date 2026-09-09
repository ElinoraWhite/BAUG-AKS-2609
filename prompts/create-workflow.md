# Pipeline for deploying aks-store-quickstart.yaml to AKS

Create a GitHub actions workflow to deploy the application to Azure using OIDC credentials.

Use the following safe guards.

- Before doing the actual deployment, try a dry run. If that completes then proceed with the deployment.
- Use a blue green deployment strategy for follow up updates.

You will deploy to the AKS cluster using the `dev` GitHub environment.

The following secrets already exist for the GitHub `dev` environment:

- `AZURE_SUBSCRIPTION_ID`
- `TENANT_ID`

The following GitHub environment variables already exist in the GitHub `dev` environment:

- `AZURE_CLIENT_ID`
- `RESOURCE_GROUP_NAME`
- `CLUSTER_NAME`
- `KUBERNETES_NAMESPACE`
