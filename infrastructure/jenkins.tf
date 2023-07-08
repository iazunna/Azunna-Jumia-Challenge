resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  version          = "4.3.30"
  chart            = "jenkins"
  namespace        = "jenkins"
  create_namespace = true

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
    kubernetes_secret.jenkins,
    kubectl_manifest.ebs-sc
  ]
}


resource "kubernetes_secret" "jenkins" {
  metadata {
    name      = "github-credentials"
    namespace = "jenkins"
  }

  data = {
    username = var.github_username
    password = var.github_password
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