output "cluster_endpoint" {
  value = "${google_container_cluster.jx-cluster.endpoint}"
}

output "cluster_username" {
  value = "${google_container_cluster.jx-cluster.master_auth.0.username}"
}

output "cluster_password" {
  value = "${google_container_cluster.jx-cluster.master_auth.0.password}"
}

output "cluster_client_certificate" {
  value = "${google_container_cluster.jx-cluster.master_auth.0.client_certificate}"
}

output "cluster_client_key" {
  value = "${google_container_cluster.jx-cluster.master_auth.0.client_key}"
}

output "cluster_cluster_ca_certificate" {
  value = "${google_container_cluster.jx-cluster.master_auth.0.cluster_ca_certificate}"
}

output "cluster_master_version" {
  value = "${google_container_cluster.jx-cluster.master_version}"
}

output "lts-bucket" {
  value = "${google_storage_bucket.lts-bucket.name}"
}

output "vault-bucket" {
  value = "${google_storage_bucket.vault-bucket[0].name}"
}

output "vault-sa" {
  value = "${google_service_account.vault-sa[0].account_id}"
}

output "vault-sa-private-key" {
  value = "${google_service_account_key.vault-sa-key[0].private_key}"
}

output "kaniko-sa" {
  value = "${google_service_account.kaniko-sa[0].account_id}"
}

output "kaniko-sa-private-key" {
  value = "${google_service_account_key.kaniko-sa-key[0].private_key}"
}
