variable "project_name" {
  default = "aiopsplatform"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_single_natgateway" {
  type    = bool
  default = true
}