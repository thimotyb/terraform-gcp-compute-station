variable "gcp_project" {
  type        = string
  description = "The GCP project ID"
}

variable "gcp_region" {
  type        = string
  description = "The region for resources"
}

variable "gcp_zone" {
  type        = string
  description = "The zone for the compute instance"
}

variable "instance_name" {
  type        = string
  description = "The name of the compute instance"
}

variable "machine_type" {
  type        = string
  description = "The machine type for the compute instance"
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB"
}

variable "user_email" {
  type        = string
  description = "User email for IAP tunnel access"
}

variable "startup_script_content" {
  type        = string
  description = "The content of the startup script. If not provided, the default internal script will be used."
  default     = null
}
