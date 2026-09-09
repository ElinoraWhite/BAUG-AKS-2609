# Do You Still Need to Be a Kubernetes Expert

This is a demo repository for a talk that I presented in September 2026 for the Brisbane Azure User Group.

This repository may contain information as presented during the talk, including demo scripts, command lines, and other relevant resources.

## Deployment

`aks-store-quickstart.yaml` is deployed to AKS by the [Deploy AKS Store](.github/workflows/deploy-aks-store.yml)
workflow. It runs on pushes to `main` that touch the manifest, and can also be started manually.

The workflow authenticates to Azure with OIDC and targets the `dev` GitHub environment, which provides:

- Secrets: `AZURE_CLIENT_ID`, `AZURE_SUBSCRIPTION_ID` and `TENANT_ID`
- Variables: `RESOURCE_GROUP_NAME`, `CLUSTER_NAME` and `KUBERNETES_NAMESPACE`

Safe guards:

- Every rendered manifest is applied with `kubectl apply --dry-run=server` first; the real deployment
  only starts once the dry run succeeds.
- Updates use a blue/green strategy. `scripts/render-bluegreen.sh` renames each Deployment to
  `<name>-<color>` and labels it with `color: <color>`, so the new (inactive) color is rolled out and
  verified alongside the running one. Traffic is only switched over by updating the Service selectors
  once every new Deployment is ready, after which the previous color is scaled down (and stays
  available for a quick roll back).

The RabbitMQ StatefulSet holds state, so it is shared between both colors and deployed unchanged.

## Support

This repository is intended for demonstration purposes and is not supported.
