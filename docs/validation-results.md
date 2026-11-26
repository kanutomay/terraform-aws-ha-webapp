# Validation Results

Manual validation of one `dev` deployment on 26 November 2026 (UTC), in
us-east-1 across two Availability Zones, with the WAF enabled. Raw logs and
screenshots are in [`validations/dev/env/`](../validations/dev/env/); the AWS
account ID has been replaced with `123456789012` and email addresses with
`example.com` placeholders.

## Summary

| Area | Result | Evidence |
| --- | --- | --- |
| Provisioning | ✅ `apply` created 54 resources; `destroy` removed all 54. The state bucket is outside this lifecycle by design. | [apply log](../validations/dev/env/terraform_apply_output.log), [destroy log](../validations/dev/env/terraform_destroy_output.log) |
| Load balancing | ✅ Two healthy targets, one per AZ; repeated requests were served by both instances. | [testing log](../validations/dev/env/terraform_testing_output.log) |
| WAF | ✅ Requests with an XSS payload in the query string returned **403 Forbidden** from the AWS Common Rule Set; normal traffic was allowed. | [testing log](../validations/dev/env/terraform_testing_output.log), [traffic summary](../validations/dev/env/waf-traffic-summary.png), [rule activity](../validations/dev/env/waf-rule-activity.png) |
| Self-healing: application failure | ✅ After Apache was stopped on the us-east-1a instance, all traffic went to us-east-1b. The ASG replaced the failed instance in us-east-1a and traffic was balanced across both AZs again. | [testing log](../validations/dev/env/terraform_testing_output.log) |
| Self-healing: instance loss | ✅ After the us-east-1a instance was terminated, traffic continued from us-east-1b. The replacement reported unhealthy while bootstrapping, then healthy, and traffic was balanced again. | [testing log](../validations/dev/env/terraform_testing_output.log), [EC2 instances](../validations/dev/env/ec2-instance-replacement.png) |
| Alerting | ✅ During the application-failure test the healthy-target alarm entered **ALARM** (01:50:51 UTC) and returned to **OK** four minutes later (01:54:51 UTC) once the ASG replacement was healthy. Both emails were delivered through the confirmed SNS subscription. | [ALARM email](../validations/dev/env/healthy-target-alarm.png), [OK email](../validations/dev/env/healthy-target-recovery.png), [subscription](../validations/dev/env/sns-subscription-confirmed.png) |
| Private egress | ✅ An instance in a private subnet reached the internet through the regional NAT gateway (ICMP to an external host, 0% loss). | [testing log](../validations/dev/env/terraform_testing_output.log) |
| Access without SSH | ✅ Instances were reached through SSM Session Manager; there is no inbound SSH rule or key pair. | [testing log](../validations/dev/env/terraform_testing_output.log) |
| Instance hardening | ✅ IMDSv2 is `required` on all instances, and the provider's default tags propagate to ASG instances. | [testing log](../validations/dev/env/terraform_testing_output.log) |
| Logging | ✅ ALB access logs and VPC flow logs (Parquet, hourly partitions) were delivered to their S3 buckets. | [testing log](../validations/dev/env/terraform_testing_output.log) |

## How the tests were run

1. `terraform apply`, then confirm the SNS email subscription.
2. Check target health and ASG state with the AWS CLI.
3. Send repeated requests to the ALB DNS name and record the instance ID and
   AZ in each response.
4. Send requests with an XSS payload and confirm the WAF returns 403.
5. Stop `httpd` on one instance through Session Manager; observe traffic,
   target health, the alarm email and the ASG replacement.
6. Terminate one instance; observe traffic and the ASG replacement.
7. List the ALB access-log and VPC flow-log buckets.
8. `terraform destroy`.

## Known limitations

- Single manual run, not an automated test suite.
- Availability was sampled with repeated requests rather than measured, so
  downtime and recovery time are not quantified. A few requests during the
  termination window returned no response. An AZ-wide outage was not tested.
- Not exercised in this run: the target-5XX, ALB-5XX, CPU and
  external-availability alarms, and ASG scale-out under load.
- The external health check uses HTTP against the ALB DNS name; HTTPS and a
  custom domain are not configured.
