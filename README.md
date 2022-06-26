# A simple hello-iress microservice.

# python microservice:
- hello service
- welcome service

## In this repo you will find the following:
- Python flask application
- EKS cluster (provisioned via eksctl - control plane and nodegroup)
- Manifest file for kubernetes objects.
- AWS resources to host the application (Provisioned via Terraform).
- CICD pipeline via GitHub actions.


Provision cluster:
```sh
eksctl create cluster -f infra/eksctl/cluster/cluster-npr.yaml
```

Provision worker nodes (start this after creating provisioning your AWS resources)
```sh
eksctl create nodegroup --config-file=infra/eksctl/nodegroup/ng20220626.yaml
```

Provision k8s object
```sh
cd infra/manifests
kubectl apply -f .
```


Provision AWS resources in order:
1. s3
2. iam
3. ecr
4. alb

Move to your selected AWS resource and run the following Terraform command
```sh
terraform plan
terraform apply --auto-approve
```

**Terraform workspace is optional.


CICD Pipeline (GitHub Actions) will trigger once the following changes are met:
1. Detected change on a specific directory.
2. PR / push / commit to develop branch.


## Production Architecture plan:
1. Use ReactJS as your FrontEnd App.
2. Switch to NodeJS as your BackEnd App.
3. Add AWS CloudFront and S3 for CDN (make sure that s3 can only be accessed by CF).
4. Add AWS WAF to secure traffic and implement specific rules.
5. Can switch / use VPN and allow traffic to corp network only.
6. Add monitoring tools such as Grafana, Prometheus, Datadog or New Relic.
7. Secure application env vars by using AWS SSM - Parameters.
8. Switch to self-hosted runners for CICD.
9. Add ArgoCD for k8s object deployment.
10. Use helm chart to replace k8s manifest files.
11. Use scanning tool for dependecies of the app.


> Note: `For other clarification, let's discuss it further. Thank you.`
