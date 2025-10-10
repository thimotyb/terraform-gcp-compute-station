########################################
# Cloud Scheduler - Auto Shutdown VM   #
########################################

# Note: Enable required APIs manually before running terraform:
# gcloud services enable compute.googleapis.com --project=cegeka-gcp-awareness
# gcloud services enable cloudscheduler.googleapis.com --project=cegeka-gcp-awareness

# Note: Service account creation requires iam.serviceAccounts.create permission
# If you get permission errors, create the service account manually:
# 1. Go to IAM & Admin > Service Accounts
# 2. Create service account: vm-scheduler-sa
# 3. Grant role: Compute Instance Admin (v1)
# Then uncomment the resources below and update with the email

# Service account for Cloud Scheduler
# resource "google_service_account" "scheduler_sa" {
#   account_id   = "vm-scheduler-sa"
#   display_name = "VM Scheduler Service Account"
#   project      = var.gcp_project
# }

# Grant permissions to stop instances
# resource "google_project_iam_member" "scheduler_compute_admin" {
#   project = var.gcp_project
#   role    = "roles/compute.instanceAdmin.v1"
#   member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
# }

# Cloud Scheduler Job - Stop VM at 22:30 every day
# NOTE: Commented out because it requires service account setup
# To enable auto-shutdown:
# 1. Create service account manually (see note above)
# 2. Uncomment this resource
# 3. Update service_account_email with your SA email
# 4. Run terraform apply
# resource "google_cloud_scheduler_job" "stop_vm_nightly" {
#   name        = "stop-ubuntu-workstation-nightly"
#   description = "Stop Ubuntu workstation every night at 22:30 CET"
#   schedule    = "30 22 * * *"  # 22:30 every day
#   time_zone   = "Europe/Rome"  # CET/CEST timezone
#   project     = var.gcp_project
#   region      = var.gcp_region
#
#   http_target {
#     http_method = "POST"
#     uri         = "https://compute.googleapis.com/compute/v1/projects/${var.gcp_project}/zones/${var.gcp_zone}/instances/${google_compute_instance.ubuntu_workstation.name}/stop"
#
#     oauth_token {
#       service_account_email = "vm-scheduler-sa@${var.gcp_project}.iam.gserviceaccount.com"
#     }
#   }
#
#   depends_on = [
#     google_project_service.scheduler_api
#   ]
# }

