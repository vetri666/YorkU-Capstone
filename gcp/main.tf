terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("gcp-key.json")   # your downloaded service account key
  project     = var.project_id
  region      = var.region
}

# ── VPC Network ──────────────────────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = "migration-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "migration-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# ── GKE Cluster ──────────────────────────────────────────────────────────────
resource "google_container_cluster" "primary" {
  name     = "migration-gke-cluster"
  location = var.zone          # zonal cluster = free-tier friendly
  deletion_protection = false
  # Minimal node pool — remove default and manage separately
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Keep logging/monitoring minimal to stay within free tier
  logging_service    = "none"
  monitoring_service = "none"
}

# ── Node Pool (e2-micro stays within free tier) ───────────────────────────────
resource "google_container_node_pool" "primary_nodes" {
  name       = "migration-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1              # 1 node keeps costs at $0 on free tier

  node_config {
    machine_type = "e2-small" # e2-micro may be too small for GKE system pods
    disk_size_gb = 30
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = "migration-demo"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }
}
