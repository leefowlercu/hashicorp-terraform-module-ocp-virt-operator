### OpenShift Virtualization Outputs

output "openshift_cnv_namespace" {
  description = "Name of the OpenShift Virtualization namespace."
  value       = kubernetes_namespace_v1.openshift_cnv.metadata[0].name
}

output "cnv_operator_installed" {
  description = "Indicates whether the OpenShift Virtualization operator subscription was created."
  value       = kubernetes_manifest.cnv_subscription.manifest.metadata.name
}

output "cnv_hyperconverged_deployed" {
  description = "Indicates whether the HyperConverged resource was deployed."
  value       = var.enable_hyperconverged ? kubernetes_manifest.cnv_hyperconverged[0].manifest.metadata.name : null
}
