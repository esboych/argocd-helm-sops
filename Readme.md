# GitOps Repository with ArgoCD, Helm, and SOPS

This repository implements a GitOps approach for Kubernetes deployments using ArgoCD, Helm charts, and encrypted secrets with SOPS and Google KMS.

## Repository Structure

```
.
├── .sops.yaml                           # SOPS encryption configuration
├── argocd/
│   └── applicationsets/                 # ArgoCD ApplicationSet definitions
│       ├── environments-appset.yaml     # Main ApplicationSet for environments
│       └── multi-cluster.yaml           # Optional multi-cluster deployment
└── charts/                              # Helm charts
    ├── backend-api/                     # Backend API service
    │   ├── Chart.yaml                   # Chart definition and dependencies
    │   ├── values.yaml                  # Default values
    │   ├── templates/                   # Helm templates
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   ├── configmap.yaml
    │   │   └── _helpers.tpl
    │   └── environments/                # Environment-specific configurations
    │       ├── dev-values.yaml          # Dev environment values
    │       ├── prod-values.yaml         # Production environment values
    │       ├── secrets-dev.enc.yaml     # Encrypted secrets for dev
    │       └── secrets-prod.enc.yaml    # Encrypted secrets for prod
    ├── frontend/                        # Frontend web application
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   ├── templates/
    │   │   ├── deployment.yaml
    │   │   ├── service.yaml
    │   │   ├── ingress.yaml
    │   │   ├── configmap.yaml
    │   │   └── _helpers.tpl
    │   └── environments/
    │       ├── dev-values.yaml
    │       ├── prod-values.yaml
    │       ├── secrets-dev.enc.yaml
    │       └── secrets-prod.enc.yaml
    └── nginx-ingress/                   # Nginx Ingress Controller
        ├── Chart.yaml                   # Uses nginx-ingress as dependency
        ├── values.yaml
        └── environments/
            ├── dev-values.yaml
            └── prod-values.yaml
```

## Prerequisites

- Kubernetes cluster
- ArgoCD installed with helm-secrets plugin
- Google KMS key configured
- SOPS installed locally

## Setup Instructions

### 1. Configure SOPS with KMS

Ensure you have access to the KMS key and the `.sops.yaml` file is configured correctly:

```yaml
creation_rules:
  - path_regex: secrets-dev\.yaml$
    gcp_kms: projects/k8s-1-dev/locations/global/keyRings/argocd-keyring/cryptoKeys/argocd-key
  - path_regex: secrets-prod\.yaml$
    gcp_kms: projects/k8s-1-dev/locations/global/keyRings/argocd-keyring/cryptoKeys/argocd-key
  - path_regex: .*/environments/secrets-dev\.enc\.yaml$
    gcp_kms: projects/k8s-1-dev/locations/global/keyRings/argocd-keyring/cryptoKeys/argocd-key
  - path_regex: .*/environments/secrets-prod\.enc\.yaml$
    gcp_kms: projects/k8s-1-dev/locations/global/keyRings/argocd-keyring/cryptoKeys/argocd-key
```

### 2. Encrypt Secrets

Create and encrypt your secrets:

```bash
# Create temporary secret file
cat > secrets-temp.yaml << EOF
auth:
  apiKey: your-secret-api-key
EOF

# Encrypt it
sops --encrypt \
  --gcp-kms projects/k8s-1-dev/locations/global/keyRings/argocd-keyring/cryptoKeys/argocd-key \
  secrets-temp.yaml > charts/frontend/environments/secrets-dev.enc.yaml

# Delete unencrypted file
rm secrets-temp.yaml
```

### 3. Deploy the ApplicationSet

Apply the ApplicationSet to your ArgoCD instance:

```bash
kubectl apply -f argocd/applicationsets/environments-appset.yaml
```

### 4. Verify Deployment

Check the Applications in ArgoCD:

```bash
kubectl get applications -n argocd
```

Or use the ArgoCD UI to see the applications being created and deployed.

## Working with this Repository

### Adding a New Application

1. Create a new Helm chart in the `charts/` directory
2. Ensure it follows the same structure with `environments/` folder
3. Create and encrypt secrets if needed
4. Push changes to Git - the ApplicationSet will automatically deploy it

### Updating Secrets

1. Decrypt the secret file:
   ```bash
   sops --decrypt charts/frontend/environments/secrets-dev.enc.yaml
   ```

2. Edit the file directly (SOPS will open it in your editor):
   ```bash
   sops charts/frontend/environments/secrets-dev.enc.yaml
   ```

3. Commit and push the changes

### Manual Helm Testing

Test your Helm charts locally before committing:

```bash
# Update dependencies
helm dependency update charts/backend-api

# Test rendering templates
helm template charts/backend-api -f charts/backend-api/values.yaml -f charts/backend-api/environments/dev-values.yaml

# For charts with secrets, use helm-secrets plugin
helm secrets template charts/backend-api -f charts/backend-api/values.yaml -f charts/backend-api/environments/dev-values.yaml -f charts/backend-api/environments/secrets-dev.enc.yaml
```

## ApplicationSet Details

The main ApplicationSet uses a matrix generator that combines:
1. A Git generator to discover all charts in the `charts/` directory
2. A list generator for environments (dev and prod)

For each combination, it creates an ArgoCD Application that:
- Points to the specific chart
- Uses environment-specific values
- Configures the helm-secrets plugin for secret decryption
- Deploys to the appropriate namespace

## Best Practices

1. **Never commit unencrypted secrets** to the repository
2. **Use specific versions** for Helm chart dependencies
3. **Test changes locally** before pushing to Git
4. **Keep values files focused** on their environment-specific settings
5. **Use descriptive commit messages** that explain the purpose of changes

## Troubleshooting

### Secret Decryption Issues

If ArgoCD cannot decrypt secrets:
- Verify ArgoCD's service account has access to the KMS key
- Check that the helm-secrets plugin is properly configured in ArgoCD
- Verify the secret file path matches what's expected in the ApplicationSet

### ArgoCD Application Sync Failures

Check the sync status and logs in ArgoCD UI or:
```bash
kubectl describe application <app-name> -n argocd
kubectl logs deployment/argocd-repo-server -n argocd
```

### ApplicationSet Not Creating Applications

Check the ApplicationSet controller logs:
```bash
kubectl logs deployment/argocd-applicationset-controller -n argocd
```
