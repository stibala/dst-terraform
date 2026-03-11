provider "kubernetes" {
  config_path    = "~/.kube/config" # path to the kubernetes configuration file
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "mysql" { 
  name = "mysql"
  namespace = "wordpress"
  chart = "${path.module}/charts/mysql-chart"

  values = [ file("${path.module}/charts/mysql-chart/values.yaml") ]

  create_namespace = true
 }

resource "helm_release" "wordpress" {
  # Definition of the helm_release resource
  name = "wordpress" # We assign it a name corresponding to that of the chart during its installation.
  namespace = "wordpress" # We specify the namespace in which the chart will be installed.
  chart = "${path.module}/charts/wordpress-chart" # We indicate the path of the chart directory by defining it relative to the Terraform module directory.

  values = [
        file("${path.module}/charts/wordpress-chart/values.yaml") # We specify the path of the values.yaml file by defining it relative to the Terraform module directory. 
  ]
  depends_on = [ 
	helm_release.mysql # We enforce the prior installation of the mysql-chart before deploying the wordpress-chart. 
  ]
}
