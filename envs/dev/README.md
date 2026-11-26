# Dev Root Module

## Overview

Connects the network, ALB, compute, and observability modules for one
deployment. The S3 backend is managed separately from these resources.

## Configuration and deployment

1. Use Terraform >= 1.11 and an AWS profile with permissions for the resources,
   state bucket, and SSM access. Use an AWS region that supports the regional
   NAT gateway configuration.
2. Create an S3 state bucket separately, enable versioning and block public
   access. Configure access to the state object and S3 lock file. The Terraform
   backend enables encryption and S3-native locking; it does not create or
   configure the bucket.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust the project,
   region, AZs, CIDR, instance type, and ASG sizes. Supply two to four distinct
   available AZs in the selected region. Set `enable_waf` explicitly or leave it
   `null` to enable WAF outside `dev`.
4. Remove `emails_list` from the copied `terraform.tfvars` before setting
   `TF_VAR_emails_list`: Terraform gives `.tfvars` values precedence over
   environment variables. Use an address you control, and confirm the SNS
   subscription email. Email addresses are included in Terraform state and may
   appear in plan output; protect state and console output.
5. Initialize with your own backend values, check formatting and validate the
   configuration, then review and apply the plan:

   ```sh
   export AWS_PROFILE="<your-aws-profile>"
   export TF_VAR_emails_list='["you@example.com"]'
   terraform init \
     -backend-config="bucket=<your-state-bucket>" \
     -backend-config="key=<your-state-key>" \
     -backend-config="region=<your-state-bucket-region>"
   terraform fmt -check -recursive ../..
   terraform validate
   terraform plan
   terraform apply
   ```

   The example address is a placeholder, not a notification destination. The
   backend uses partial configuration, so supply all three values above. If
   changing an already initialized backend, follow Terraform's reinitialization
   instructions and handle existing state carefully.

6. Review `terraform output` and open the ALB DNS name. When finished, run
   `terraform destroy`. Dev log buckets use `force_destroy`, which deletes their
   contents. Outside dev, nonempty log buckets may prevent destruction until
   handled separately. The state bucket is not destroyed by this configuration.

The example `.tfvars` file contains an email placeholder; do not commit real
email addresses, credentials, plans, state, or local variable files.

## Updating generated references

From the project directory, regenerate the sections between the terraform-docs
markers without replacing the handwritten text:

```sh
for module in network alb compute observability; do
  terraform-docs markdown table --hide header,footer,providers,modules,data-sources \
    --lockfile=false --output-file README.md --output-mode inject "modules/$module"
done
terraform-docs markdown table --hide header,footer,providers,data-sources \
  --lockfile=false --output-file README.md --output-mode inject envs/dev
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alb"></a> [alb](#module\_alb) | ../../modules/alb | n/a |
| <a name="module_compute"></a> [compute](#module\_compute) | ../../modules/compute | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/network | n/a |
| <a name="module_observability"></a> [observability](#module\_observability) | ../../modules/observability | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | The maximum size of the auto scaling group | `number` | n/a | yes |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | The minimum size of the auto scaling group | `number` | n/a | yes |
| <a name="input_azs"></a> [azs](#input\_azs) | The availability zones | `list(string)` | n/a | yes |
| <a name="input_emails_list"></a> [emails\_list](#input\_emails\_list) | The list of email addresses for notifications | `list(string)` | n/a | yes |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Flag to enable WAF | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The instance type for the compute module | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | n/a | yes |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block for the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alb_info"></a> [alb\_info](#output\_alb\_info) | Information about the ALB and associated resources |
| <a name="output_compute_info"></a> [compute\_info](#output\_compute\_info) | Information about the compute module |
| <a name="output_deployment_input_info"></a> [deployment\_input\_info](#output\_deployment\_input\_info) | Information about the deployment |
| <a name="output_observability_info"></a> [observability\_info](#output\_observability\_info) | Information about the observability module |
| <a name="output_private_subnets_info"></a> [private\_subnets\_info](#output\_private\_subnets\_info) | Private subnets keyed by AZ |
| <a name="output_public_subnets_info"></a> [public\_subnets\_info](#output\_public\_subnets\_info) | Public subnets keyed by AZ |
| <a name="output_vpc_info"></a> [vpc\_info](#output\_vpc\_info) | Extended information for the VPC |
<!-- END_TF_DOCS -->