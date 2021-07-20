variable "rds_dns_name" {
  default     = ""
  description = "the DNS name of the RDS database."
}

variable "nlb_tg_arn" {
  type        = string
  default     = ""
  description = "Network Log Balancer Target Group arn."
}

variable "max_lookup_per_invocation" {
  type 		  = string
  default 	  = "10"
  description = "Maximum number of invocations of DNS lookup"
}
