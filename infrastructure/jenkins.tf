resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  version          = "4.3.30"
  chart            = "jenkins"
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  create_namespace = false

  values = [
    "${file("values.jenkins.yaml")}"
  ]

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "jenkins"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.jenkins_irsa.iam_role_arn
  }

  set {
    name  = "serviceAccountAgent.create"
    value = "true"
  }

  set {
    name  = "persistence.storageClass"
    value = "ebs-sc"
  }

  set {
    name  = "serviceAccountAgent.name"
    value = "jenkins-agent-sa"
  }

  set {
    name  = "serviceAccountAgent.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.jenkins_irsa.iam_role_arn
  }

  depends_on = [
    module.eks,
    helm_release.ingress,
    helm_release.ingress_nginx,
    helm_release.external_dns,
    helm_release.cert_manager,
    kubernetes_secret.jenkins,
    kubectl_manifest.ebs-sc
  ]
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}


resource "kubernetes_secret" "jenkins" {
  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    github-username = var.github_username
    github-password = var.github_password
  }

}

resource "kubectl_manifest" "ebs-sc" {
  yaml_body = <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
  namespace: jenkins
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
EOF
}