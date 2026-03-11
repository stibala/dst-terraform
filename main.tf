provider "kubernetes" {
  config_path    = "~/.kube/config" # path to the kubernetes configuration file
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.9.0"
    }
  }
}

resource "kubernetes_secret" "datascientest-mysql-password" {
 metadata {
   name = "datascientest-mysql-password"
 }
 data = {
   password = "Datascientest123@" # the password will have the value Datascientest123@
 }
}

resource "kubernetes_secret" "datascientest-mysql-user" {
 metadata {
   name = "datascientest-mysql-user"
 }
 data = {
   user = "root" # the user will have the value root
 }
}

resource "kubernetes_deployment" "datascientest_wordpress" {

  metadata {
    name   = "datascientest-wordpress"
    labels = local.datascientest_wordpress
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.datascientest_wordpress
    }

    template {
      metadata {
        labels = local.datascientest_wordpress
      }

      spec {
        container {
          name  = "datascientest-wordpress"
          image = "wordpress:4.8-apache"

          port {
            container_port = 80
          }

          env {
            name  = "WORDPRESS_DB_HOST"
            value = "mysql-service"
          }

          env {
            name = "WORDPRESS_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "datascientest-mysql-password"
                key  = "password"
              }
            }
          }

          env {
            name = "WORDPRESS_DB_USER"
            value_from {
              secret_key_ref {
                name = "datascientest-mysql-user"
                key  = "user"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress-service" {
 metadata {
   name = "wordpress-service"
 }
 spec {
   selector = local.datascientest_wordpress # retrieves the values declared in the datascientest-wordpress variable to route requests to the correct pods
   port {
     port        = 80 # Open port, here we are talking about a web service listening on port 80
     target_port = 80 # Target port
     node_port = 32000 # port open on each node
   }
   type = "NodePort" # NodePort service type that will allow access from each node of the cluster on port 32000
 }
}

resource "kubernetes_deployment" "mysql" {
 metadata {
   name = "mysql"
   labels = local.datascientest-mysql # retrieves the values declared in the variable datascientest-mysql
 }
 spec {
   replicas = 1
   selector {
     match_labels = local.datascientest-mysql
   }
   template {
     metadata {
       labels = local.datascientest-mysql
     }
     spec {
       container {
         image = "mysql:5.6" # image to use for the mysql deployment
         name  = "mysql"
         port {
           container_port = 3306
         }
         env {
           name = "MYSQL_ROOT_PASSWORD" # declaration of the value of MYSQL_ROOT_PASSWORD to be retrieved from the secret mysql-pass
           value_from {
             secret_key_ref {
               name = "datascientest-mysql-password"
               key = "password"
             }
           }
         }
       }
     }
   }
 }
}

resource "kubernetes_service" "mysql-service" {
 metadata {
   name = "mysql-service"
 }
 spec {
   selector = local.datascientest-mysql
   port {
     port        = 3306
     target_port = 3306
   }
   type = "NodePort"
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

