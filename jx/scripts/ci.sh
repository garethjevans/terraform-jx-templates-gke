#!/usr/bin/env bash

set -e
set -x
set -u

export GH_USERNAME="jenkins-x-bot-test"
export GH_OWNER="cb-kubecd"

export GH_CREDS_PSW="$(jx step credential -s jenkins-x-bot-test-github)"
export JENKINS_CREDS_PSW="$(jx step credential -s  test-jenkins-user)"
export GKE_SA="$(jx step credential -k bdd-credentials.json -s bdd-secret -f sa.key.json)"

PROJECT=jenkins-x-bdd2
BUCKET_NAME=$(echo "${PROJECT}-${VERSION}-terraform-state" | tr '[:upper:]' '[:lower:]' | sed 's/\./-/g')
SAFE_VERSION=$(echo "v${VERSION}" | tr '[:upper:]' '[:lower:]' | sed 's/\./-/g')
gcloud auth activate-service-account --key-file $GKE_SA
echo "create the bucket first"
gsutil mb -l EU -p ${PROJECT} gs://${BUCKET_NAME}

echo "checking terraform version"
terraform -version

echo "checking formatting"
terraform fmt -check

cat <<EOF > terraform.tf
terraform {
  required_version = ">= 0.12.0"
  backend "gcs" {
    bucket      = "${BUCKET_NAME}"
    prefix      = "dev"
  }
}
EOF

DATE=$(date +%a-%b-%d-%Y-%M-%H-%S | tr '[:upper:]' '[:lower:]')
cat <<EOF > terraform.tfvars
created_by = "terraform-test"
created_timestamp = "${DATE}"
cluster_name = "${SAFE_VERSION}-dev"
organisation = "${SAFE_VERSION}"
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
enable_boot = "0"
EOF

./local-apply.sh
./local-destroy.sh
