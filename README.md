# AWS HA Web App: Terraform Capstone

Terraform deploys an HTTP web app across multiple Availability Zones (AZs),
demonstrating modular networking, load balancing, Auto Scaling, and monitoring.

![Application architecture](docs/architecture.png)

The diagram shows two AZs; the configuration accepts two to four. HTTPS is not
configured.

## Design decisions

| Design decision | Rationale and trade-off |
|---|---|
| Regional NAT gateway | One gateway expands across AZs automatically, with no per-AZ gateways or route tables to manage. Billed per active AZ, so it simplifies operations but doesn't reduce cost. |
| Fixed subnet offsets | Public subnets take indexes 0–3 and private subnets 4–7, so adding an AZ never renumbers existing subnets (which would force their replacement). Limits the design to four AZs. |
| Module-owned logging resources | Each log bucket lives in the module that produces the logs (ALB logs in `alb`, flow logs in `observability`), so ownership is clear and module dependencies stay one-way. |
| WAF enabled by default outside dev | Production-like environments get managed-rule protection by default, while dev avoids the cost unless `enable_waf` overrides it. |
| Route 53 alarms in `us-east-1` | Route 53 health-check metrics are published only in `us-east-1`, so the external-availability alarm and its SNS topic must live there whatever the deployment region. |
| SSM instead of SSH | IAM-controlled, audited access with no inbound management ports, bastion host or key pairs. Requires the SSM agent, an instance role and an outbound path (NAT). |
| One-way module dependencies | `network → alb → compute → observability`, wired only in the root, avoids circular references and keeps each module reusable on its own. |
| Independently managed S3 backend | State, versioning and locking live outside this stack, so `terraform destroy` can never delete its own state. Requires a one-time bootstrap of the bucket. |

## Repository

```text
docs/                   Architecture, dependency diagram, and selected evidence
envs/dev/               Root module and deployment instructions
modules/network/        VPC, subnets, routes, NAT, and S3 endpoint
modules/alb/            Load balancer, access logs, and optional WAF
modules/compute/        Launch template, Auto Scaling, and instance role
modules/observability/  Flow logs, health check, alarms, and dashboard
validations/dev/env/    Recorded validation evidence
```

See the [module dependency diagram](docs/terraform_modules_dependencies.png)
and [engineering notes](docs/engineering-notes.md).

## Deploy

Requires Terraform >= 1.11, AWS credentials with appropriate permissions, and a
separately managed S3 state bucket. Configure `AWS_PROFILE`, `TF_VAR_emails_list`,
inputs, and the backend as described in [envs/dev/README.md](envs/dev/README.md).

```sh
cd envs/dev
terraform init -backend-config="bucket=<your-state-bucket>" \
  -backend-config="key=<your-state-key>" \
  -backend-config="region=<your-state-bucket-region>"
terraform fmt -check -recursive ../..
terraform validate
terraform plan
terraform apply
terraform destroy
```

Confirm SNS subscriptions before testing.
The S3 state bucket is managed separately and is not deleted by `terraform destroy`.

## Validation evidence

A dev deployment successfully provisioned and destroyed 54 Terraform-managed
resources. Manual testing demonstrated multi-AZ load balancing, automatic
instance replacement after application and instance failures, WAF request
blocking, CloudWatch alarm and recovery notifications, and S3 log delivery.

- [Dashboard](docs/dashboard-validation.png): requests and healthy-target dips from an earlier run.
- [Alarm notification](docs/alarm-notification.png): healthy targets below minimum.
- [Recovery notification](docs/alarm-recovery.png): alarm returned to OK.

See [validation results](docs/validation-results.md) for the test overview and
[validation artifacts](validations/dev/env/) for the full recorded logs.

## Cost and future work

EC2, ALB, regional NAT, and public IPv4 incur time-based charges. Data
processing, logging, storage, monitoring, WAF, and Route 53 may also incur
charges. Destroy after use and check for remaining resources.

Future work: CI/CD with OIDC, Terraform tests, WAF logging, ALB HTTPS, and
additional environments. The external check monitors the ALB's HTTP endpoint,
not a custom domain or HTTPS journey.

## License

This project is licensed under the [MIT License](LICENSE).
