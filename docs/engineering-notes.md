# Engineering Notes

These notes summarize design choices and lessons from building the capstone.
See [validation results](validation-results.md) for what was actually observed.

## Module boundaries and data flow

- The root module composes network, ALB, compute, and observability modules.
  Child modules expose outputs that the root passes to other modules as inputs;
  Terraform uses those references to build its dependency graph.
- Security groups and log buckets live with the components that own them.
  This avoids separate modules that would only wrap individual resources.
- The ALB is one regional load balancer using public subnets in multiple AZs,
  rather than a separate load balancer per AZ.

## Networking

- Subnet CIDRs are derived from the VPC CIDR using `cidrsubnet`: public offsets
  start at zero and private offsets at four. This avoids hardcoding a subnet for
  each AZ, but the offset depends on the AZ's position in the input list.
  Reordering that list can change CIDRs and force subnet replacement, even
  though the resources are keyed by AZ.
- A regional NAT gateway in automatic mode simplifies outbound connectivity
  compared with managing zonal gateways and their addresses individually. Check
  regional support and charges before deploying. An S3 gateway endpoint is
  associated with the private route table.

## Compute and operations

- Instances accept HTTP from the ALB security group and use Systems Manager
  instead of inbound SSH. Session Manager still needs suitable IAM permissions
  and network connectivity.
- User data obtains an IMDSv2 token before reading the instance ID and AZ, then
  creates the page before starting Apache. The launch template requires
  IMDSv2. Bootstrap failures can prevent targets from becoming healthy.
- The ASG uses ELB health checks and a launch-template version reference with a
  rolling instance refresh. Its tags explicitly propagate to instances; provider
  default tags on the ASG alone do not automatically propagate to instances.

## Configuration and monitoring

- `coalesce` allows an explicit WAF override while defaulting to enabled outside
  dev. Unlike `try`, it selects a fallback when the first value is `null`.
- Terraform variable files take precedence over `TF_VAR_` environment variables.
  Remove the example email value from the local variable file if using
  `TF_VAR_emails_list`; email addresses remain in state and may appear in plan
  output.
- ALB-generated and target-generated 5xx metrics identify different failure
  sources. A healthy-target alarm complements the unhealthy-target alarm, and
  the dashboard shows ASG desired and in-service capacity.
- Route 53 health-check metrics and their alarm use `us-east-1`. Deployments in
  other regions create an additional SNS topic there; each email subscription
  must be confirmed. The check covers the ALB's HTTP endpoint, not HTTPS or a
  custom-domain user journey.
- The S3 backend is managed separately from application resources. Its
  versioning and access controls must be configured separately. Log buckets
  use `force_destroy` in dev; nonempty buckets outside dev can block destroy.

## Follow-up

Potential improvements include CI/CD with OIDC, a maintained Terraform test
suite, WAF logging, HTTPS, and additional environments. The module reference
sections are generated with terraform-docs; regeneration instructions are in
the [dev root README](../envs/dev/README.md).
