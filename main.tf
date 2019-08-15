terraform {
  required_version = ">= 0.12.0"
}

provider "google" {
  version     = ">= 2.8.0"
  credentials = "${file("${var.credentials}")}"
  project     = "${var.gcp_project}"
}

resource "google_project_service" "cloudresourcemanager-api" {
  project            = "${var.gcp_project}"
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute-api" {
  project            = "${var.gcp_project}"
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam-api" {
  project            = "${var.gcp_project}"
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild-api" {
  project            = "${var.gcp_project}"
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containerregistry-api" {
  project            = "${var.gcp_project}"
  service            = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containeranalysis-api" {
  project            = "${var.gcp_project}"
  service            = "containeranalysis.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "cloudkms-api" {
  project            = "${var.gcp_project}"
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
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
    created-by   = "${var.created_by}"
    create-time  = "${var.created_timestamp}"
    created-with = "terraform"
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }
}

resource "google_storage_bucket" "lts-bucket" {
  name     = "${var.cluster_name}-lts"
  location = "EU"
}

resource "google_service_account" "kaniko-sa" {
  count        = var.enable_kaniko
  account_id   = "${var.cluster_name}-ko"
  display_name = "Kaniko service account for ${var.cluster_name}"
}

resource "google_service_account_key" "kaniko-sa-key" {
  count              = var.enable_kaniko
  service_account_id = "${google_service_account.kaniko-sa[0].name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "kaniko-sa-storage-admin-binding" {
  count  = var.enable_kaniko
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.kaniko-sa[0].email}"
}

resource "google_project_iam_member" "kaniko-sa-storage-object-admin-binding" {
  count  = var.enable_kaniko
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.kaniko-sa[0].email}"
}

resource "google_project_iam_member" "kaniko-sa-storage-object-creator-binding" {
  count  = var.enable_kaniko
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.kaniko-sa[0].email}"
}

resource "google_storage_bucket" "vault-bucket" {
  count    = var.enable_vault
  name     = "${var.cluster_name}-vault"
  location = "EU"
}

resource "google_service_account" "vault-sa" {
  count        = var.enable_vault
  account_id   = "${var.cluster_name}-vt"
  display_name = "Vault service account for ${var.cluster_name}"
}

resource "google_service_account_key" "vault-sa-key" {
  count              = var.enable_vault
  service_account_id = "${google_service_account.vault-sa[0].name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "vault-sa-storage-object-admin-binding" {
  count  = var.enable_vault
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vault-sa[0].email}"
}

resource "google_project_iam_member" "vault-sa-cloudkms-admin-binding" {
  count  = var.enable_vault
  role   = "roles/cloudkms.admin"
  member = "serviceAccount:${google_service_account.vault-sa[0].email}"
}

resource "google_project_iam_member" "vault-sa-cloudkms-crypto-binding" {
  count  = var.enable_vault
  role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:${google_service_account.vault-sa[0].email}"
}

resource "google_kms_key_ring" "vault-keyring" {
  count    = var.enable_vault
  name     = "${var.cluster_name}-keyring"
  location = "${var.gcp_region}"
}

resource "google_kms_crypto_key" "vault-crypto-key" {
  count           = var.enable_vault
  name            = "${var.cluster_name}-crypto-key"
  key_ring        = "${google_kms_key_ring.vault-keyring[0].self_link}"
  rotation_period = "100000s"
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.jx-cluster.endpoint}"
  username               = "${google_container_cluster.jx-cluster.master_auth.0.username}"
  password               = "${google_container_cluster.jx-cluster.master_auth.0.password}"
  client_certificate     = "${base64decode(google_container_cluster.jx-cluster.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.jx-cluster.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.jx-cluster.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "jx-namespace" {
  metadata {
    name = "jx"
  }
}

resource "kubernetes_job" "jx-boot" {
  count = var.enable_boot
  metadata {
    name      = "jx-boot"
    namespace = "jx"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name              = "boot"
          image             = "gcr.io/jenkinsxio/builder-jx:0.1.653"
          image_pull_policy = "IfNotPresent"
          command           = ["jx"]
          args              = ["boot", "-b", "--git-url", "https://github.com/cloudbees/arcalos-boot-config", "--git-ref", "master"]
          env {
            GIT_COMMITTER_EMAIL                   = "jenkins-x@googlegroups.com"
            GIT_AUTHOR_EMAIL                      = "jenkins-x@googlegroups.com"
            GIT_AUTHOR_NAME                       = "jenkins-x-bot"
            GIT_COMMITTER_NAME                    = "jenkins-x-bot"
            JX_REQUIREMENT_TERRAFORM              = "true"
            JX_REQUIREMENT_CLUSTER_NAME           = "${var.cluster_name}"
            JX_REQUIREMENT_PROJECT                = "${var.gcp_project}"
            JX_REQUIREMENT_ZONE                   = "${var.gcp_zone}"
            JX_REQUIREMENT_ENV_GIT_OWNER          = "${var.git_owner}"
            JX_REQUIREMENT_KANIKO_SA_NAME         = "${var.cluster_name}-ko"
            JX_REQUIREMENT_VAULT_SA_NAME          = "${var.cluster_name}-vt"
            JX_REQUIREMENT_EXTERNALDNS_SA_NAME    = "${var.cluster_name}-dn"
            JX_REQUIREMENT_DOMAIN_ISSUER_URL      = "${var.domain_issuer_url}"
            JX_REQUIREMENT_DOMAIN_ISSUER_USERNAME = "${var.domain_issuer_username}"
            JX_REQUIREMENT_DOMAIN_ISSUER_PASSWORD = "${var.domain_issuer_password}"
            JX_VALUE_ADMINUSER_PASSWORD           = "${var.admin_password}"
            JX_VALUE_PIPELINEUSER_USERNAME        = "${var.pipeline_github_user}"
            JX_VALUE_PIPELINEUSER_TOKEN           = "${var.pipeline_github_token}"
            JX_VALUE_PROW_HMACTOKEN               = "${var.prow_hmac_token}"
            JX_BATCH_MODE                         = "true"
            JX_LOG_FORMAT                         = "json"
            JX_VALUE_GITPROVIDER                  = "github"
            JX_VALUE_DASHBOARDAUTHID              = "${var.dashboard_auth_id}"
            JX_VALUE_DASHBOARDAUTHSECRET          = "${var.dashboard_auth_secret}"
            JX_VALUE_DASHBOARDAUTHORG             = "${var.dashboard_auth_org}"
            JX_VALUE_DASHBOARDGRPCHOST            = "${var.dashboard_grpc_host}"
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 1
    completions   = 1
    parallelism   = 1
  }
}
