provider "tfe" {
  organization = "hashicorp-sandbox-lf"
}

provider "kubernetes" {
  host  = data.tfe_outputs.rosa_cluster.values.cluster_api_url
  token = data.tfe_outputs.rosa_cluster.values.cluster_token
}
