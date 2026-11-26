locals {
  enable_waf = coalesce(var.enable_waf, var.environment != "dev")
}
