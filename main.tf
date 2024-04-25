data "google_compute_network" "network" {
  name    = var.network.vpc-name
  project = var.network.project-id
}

resource "google_service_account" "sa-gke-vpc-native" {
  account_id = "sa-gke-vpc-native"
}

resource "google_container_cluster" "gke-vpc-native" {
  name     = "gke-vpc-native"
  location = "us-east4-a"

  deletion_protection = false
  network             = data.google_compute_network.network.id
  subnetwork          = var.network.subnetwork-name

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # vpc-native
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }

}

resource "google_container_node_pool" "node-pool" {
  name       = "node-pool"
  location   = "us-east4-a"
  cluster    = google_container_cluster.gke-vpc-native.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.sa-gke-vpc-native.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}