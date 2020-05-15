provider "packet" {
    auth_token = var.auth_token
}

resource "random_string" "minio_access_key" {
    length = 20
    min_upper = 1
    min_lower = 1
    min_numeric = 1
    special = false
}

resource "random_string" "minio_secret_key" {
    length = 40
    min_upper = 1
    min_lower = 1
    min_numeric = 1
    special = false
}

data "template_file" "user_data" { 
    template = file("${path.module}/templates/user_data.sh")
    vars = {
        minio_access_key = random_string.minio_access_key.result
        minio_secret_key = random_string.minio_secret_key.result
   }
}

resource "packet_device" "minio" {
    hostname = "minio" 
    plan = var.plan
    facilities = [var.facility]
    operating_system = var.operating_system
    billing_cycle = var.billing_cycle
    project_id = var.project_id
    user_data = data.template_file.user_data.rendered
}
