#!/usr/bin/env bash

set -e
set -x
set -u

export GKE_SA="$(jx step credential -k bdd-credentials.json -s bdd-secret -f sa.key.json)"

PROJECT=jenkins-x-bdd2

terraform -version

echo "TODO: should we create the bucket first"

cat <<EOF > terraform.tf
terraform {
  required_version = ">= 0.12.0"
  backend "gcs" {
    bucket      = "${PROJECT}-${VERSION}-terraform-state"
    prefix      = "dev"
  }
}
EOF

cat <<EOF > terraform.tfvars
created_by = "terraform-test"
created_timestamp = "unknown"
cluster_name = "${VERSION}-dev"
organisation = "${VERSION}"
cloud_provider = "gke"
gcp_zone = "europe-west1-b"
gcp_region = "europe-west1"
gcp_project = "${PROJECT}"
min_node_count = "3"
max_node_count = "5"
node_machine_type = "n1-standard-2"
node_preemptible = "false"
node_disk_size = "100"
auto_repair = "true"
auto_upgrade = "false"
enable_kubernetes_alpha = "false"
enable_legacy_abac = "false"
logging_service = "logging.googleapis.com"
monitoring_service = "monitoring.googleapis.com"
node_devstorage_role = "https://www.googleapis.com/auth/devstorage.full_control"
enable_kaniko = "1"
enable_vault = "1"
EOF

./local-plan.sh
#./local-apply.sh
#./local-destroy.sh
