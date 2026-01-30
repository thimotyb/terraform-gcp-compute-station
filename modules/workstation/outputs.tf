output "instance_name" {
  value       = google_compute_instance.ubuntu_workstation.name
  description = "The name of the compute instance"
}

output "instance_public_ip" {
  value       = google_compute_instance.ubuntu_workstation.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the compute instance"
}

output "instance_private_ip" {
  value       = google_compute_instance.ubuntu_workstation.network_interface[0].network_ip
  description = "The private IP address of the compute instance"
}
