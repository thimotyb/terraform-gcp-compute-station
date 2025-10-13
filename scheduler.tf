########################################
# Cloud Scheduler - Auto Shutdown VM   #
########################################

# Note: Enable required APIs manually before running terraform:
# gcloud services enable compute.googleapis.com --project=cegeka-gcp-awareness
# gcloud services enable cloudscheduler.googleapis.com --project=cegeka-gcp-awareness

# Service account for Cloud Scheduler
resource "google_service_account" "scheduler_sa" {
  account_id   = "vm-scheduler-sa"
  display_name = "VM Scheduler Service Account"
  project      = var.gcp_project
}

# Grant permissions to stop instances
resource "google_project_iam_member" "scheduler_compute_admin" {
  project = var.gcp_project
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Cloud Scheduler Job - Stop VM at 22:30 every day
resource "google_cloud_scheduler_job" "stop_vm_nightly" {
  name        = "stop-ubuntu-workstation-nightly"
  description = "Stop Ubuntu workstation every night at 22:30 CET"
  schedule    = "30 22 * * *"  # 22:30 every day
  time_zone   = "Europe/Rome"  # CET/CEST timezone
  project     = var.gcp_project
  region      = var.gcp_region

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.gcp_project}/zones/${var.gcp_zone}/instances/${google_compute_instance.ubuntu_workstation.name}/stop"

    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}

