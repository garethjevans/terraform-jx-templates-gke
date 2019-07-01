terraform {
  required_version = ">= 0.12.0"
}

provider "google" {
  version     = ">= 1.16.1"
  credentials = "${file("${var.credentials}")}"
  project     = "${var.gcp_project}"
}

resource "google_container_node_pool" "jx-node-pool" {
  name       = "default-pool"
  zone       = "${var.gcp_zone}"
  cluster    = "${google_container_cluster.jx-cluster.name}"
  node_count = "${var.min_node_count}"

  node_config {
    preemptible  = "${var.node_preemptible}"
    machine_type = "${var.node_machine_type}"
    disk_size_gb = "${var.node_disk_size}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "${var.node_devstorage_role}",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  management {
    auto_repair  = "${var.auto_repair}"
    auto_upgrade = "${var.auto_upgrade}"
  }

}

resource "google_container_cluster" "jx-cluster" {
  name                     = "${var.cluster_name}"
  description              = "jx k8s cluster"
  zone                     = "${var.gcp_zone}"
  enable_kubernetes_alpha  = "${var.enable_kubernetes_alpha}"
  enable_legacy_abac       = "${var.enable_legacy_abac}"
  initial_node_count       = "${var.min_node_count}"
  remove_default_node_pool = "true"
  logging_service          = "${var.logging_service}"
  monitoring_service       = "${var.monitoring_service}"

  resource_labels = {
    created-by = "${var.created_by}"
    created-timestamp = "${var.created_timestamp}"
    created-with = "terraform"
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }
}
