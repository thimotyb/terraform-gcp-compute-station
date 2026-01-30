module "workstation" {
  source = "./modules/workstation"

  gcp_project   = var.gcp_project
  gcp_region    = var.gcp_region
  gcp_zone      = var.gcp_zone
  instance_name = var.instance_name
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  user_email    = var.user_email
}
