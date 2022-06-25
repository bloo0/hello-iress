
# Target Groups
output "tg_arn" {
  #description = "A list of target groups spefified as argument to this module"
  value       = module.alb.*.target_group_arns
}