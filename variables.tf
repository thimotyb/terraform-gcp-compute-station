#####################################
# Create Storage Bucket - Variables #
#####################################

variable "bucket-name" {
  type        = string
  description = "The name of the Google Storage Bucket to create"
}

variable "storage-class" {
  type        = string
  description = "The storage class of the Google Storage Bucket to create"
}

#####################################
# Compute Instance - Variables      #
#####################################

variable "instance_name" {
  type        = string
  description = "The name of the compute instance"
  default     = "ubuntu-workstation"
}

variable "machine_type" {
  type        = string
  description = "The machine type for the compute instance (e2-highmem-4 = 4 vCPU, 32GB RAM - most cost-effective)"
  default     = "e2-highmem-4"
}

variable "gcp_zone" {
  type        = string
  description = "The zone where the compute instance will be created"
  default     = "europe-west1-c"
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB (400GB recommended for cost savings)"
  default     = 400
}

variable "user_email" {
  type        = string
  description = "Your GCP user email for IAP tunnel access"
}
