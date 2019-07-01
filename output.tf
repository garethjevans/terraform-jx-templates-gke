output "cluster_endpoint" {
  value = "${google_container_cluster.jx-cluster.endpoint}"
}

output "cluster_master_version" {
  value = "${google_container_cluster.jx-cluster.master_version}"
}
