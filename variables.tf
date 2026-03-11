locals {
  datascientest_wordpress = {
    App  = "datascientest-wordpress"
    Tier = "frontend"
  }
  datascientest-mysql = {
    App  = "datascientest_wordpress"
    Tier = "mysql"
  }
}
