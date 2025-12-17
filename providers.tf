provider "tfe" {
  organization = "hashicorp-sandbox-lf"
}

provider "kubernetes" {
  host     = data.tfe_outputs.rosa_cluster.values.cluster_api_url
  username = data.tfe_outputs.rosa_cluster.values.cluster_admin_username
  password = data.tfe_outputs.rosa_cluster.values.cluster_admin_password
}
