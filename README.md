# aws-resource-iac

Modular, production-oriented Terraform for AWS: a VPC, a secured S3 bucket, and an EC2-assumable IAM role scoped to that bucket. Remote state lives in S3 with **native state locking** (`use_lockfile = true`), so no DynamoDB table is needed.

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.10.0` |
| AWS provider | `~> 5.70` |
| AWS credentials | Supplied via environment, profile, or SSO. Never commit credentials. |

## Layout

```
.
├── bootstrap/        # One-time: creates the S3 state bucket (local state)
├── modules/
│   ├── vpc/          # VPC, public/private subnets, IGW, route tables
│   ├── s3/           # Versioned, AES256-encrypted, fully private bucket
│   └── iam/          # EC2 role + least-privilege S3 policy + instance profile
├── main.tf           # Root module, providers, S3 backend
├── variables.tf
├── outputs.tf
└── terraform.tfvars  # Default values
```

## Architecture

```
module.s3_storage ──bucket_arn──▶ module.iam_app_role   (policy scoped to that bucket only)
module.vpc                                              (independent network layer)
```

- **vpc**: DNS hostnames and resolution enabled; public subnets route `0.0.0.0/0` to the Internet Gateway; private subnets use a route table with no internet route.
- **s3**: versioning, default AES256 encryption, and all four public access block settings enabled.
- **iam**: trusts `ec2.amazonaws.com`; policy allows `ListBucket`/`GetBucketLocation` on the bucket and `Get/Put/DeleteObject` (plus `GetObjectVersion`) on its objects only.

All resources carry an `Environment` tag; the provider also applies default tags (`Environment`, `ManagedBy`, `Project`).

## Getting started

### 1. Bootstrap the state bucket (once per account)

```bash
cd bootstrap
# edit terraform.tfvars: state_bucket_name must be globally unique
terraform init
terraform apply
```

The bootstrap uses local state, because the bucket cannot store its own state before it exists. Keep that state file safe (it is git-ignored).

### 2. Deploy the infrastructure

```bash
cd ..
terraform init -backend-config="bucket=<state-bucket-name>"
# add -backend-config="region=<region>" if not us-east-1
terraform plan
terraform apply
```

Edit `app_bucket_name` in [terraform.tfvars](terraform.tfvars) first; S3 bucket names are global.

## Remote backend and locking

The backend block in [main.tf](main.tf) sets `use_lockfile = true`. Terraform writes a `<key>.tflock` object using S3 conditional writes, which prevents concurrent runs from corrupting state. The bucket name is passed at init time, since backend blocks cannot use variables.

Grant your CI/operator principal `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the state key and its `.tflock`, plus `s3:ListBucket` on the bucket.

## Inputs (root)

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | Deployment region | `us-east-1` |
| `project_name` | Resource name prefix | required |
| `environment` | `dev`, `staging`, or `prod` | required |
| `vpc_cidr` | VPC CIDR | `10.0.0.0/16` |
| `availability_zones` | AZs for subnets | required |
| `public_subnet_cidrs` | Public subnet CIDRs | required |
| `private_subnet_cidrs` | Private subnet CIDRs | required |
| `app_bucket_name` | Application bucket name | required |
| `bucket_force_destroy` | Allow deleting a non-empty bucket | `false` |

## Outputs (root)

`vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `bucket_arn`, `app_role_arn`, `app_instance_profile_name`.

## Development

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

## Notes

- `terraform.tfvars` is committed with non-secret defaults. Put secrets in git-ignored files or environment variables (`TF_VAR_*`).
- Private subnets have no NAT gateway; add one if workloads need outbound internet.
- The state bucket has `prevent_destroy` enabled and expires noncurrent versions after 90 days.
