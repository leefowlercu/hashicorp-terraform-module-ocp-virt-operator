### OpenShift Virtualization Resources

# Create the openshift-cnv namespace
resource "kubernetes_namespace_v1" "openshift_cnv" {
  metadata {
    name = "openshift-cnv"
    labels = {
      "openshift.io/cluster-monitoring" = "true"
    }
  }
}

# Create OperatorGroup for OpenShift Virtualization
resource "kubernetes_manifest" "cnv_operator_group" {
  manifest = {
    apiVersion = "operators.coreos.com/v1"
    kind       = "OperatorGroup"
    metadata = {
      name      = "kubevirt-hyperconverged-group"
      namespace = kubernetes_namespace_v1.openshift_cnv.metadata[0].name
    }
    spec = {
      targetNamespaces = [kubernetes_namespace_v1.openshift_cnv.metadata[0].name]
    }
  }
}

# Create Subscription for OpenShift Virtualization operator
resource "kubernetes_manifest" "cnv_subscription" {
  manifest = {
    apiVersion = "operators.coreos.com/v1alpha1"
    kind       = "Subscription"
    metadata = {
      name      = "kubevirt-hyperconverged"
      namespace = kubernetes_namespace_v1.openshift_cnv.metadata[0].name
    }
    spec = {
      channel             = "stable"
      name                = "kubevirt-hyperconverged"
      source              = "redhat-operators"
      sourceNamespace     = "openshift-marketplace"
      installPlanApproval = "Automatic"
    }
  }

  depends_on = [kubernetes_manifest.cnv_operator_group]
}

# Create HyperConverged resource to deploy OpenShift Virtualization
resource "kubernetes_manifest" "cnv_hyperconverged" {
  count = var.enable_hyperconverged ? 1 : 0

  manifest = {
    apiVersion = "hco.kubevirt.io/v1beta1"
    kind       = "HyperConverged"
    metadata = {
      name      = "kubevirt-hyperconverged"
      namespace = kubernetes_namespace_v1.openshift_cnv.metadata[0].name
    }
    spec = {}
  }

  depends_on = [kubernetes_manifest.cnv_subscription]
}
