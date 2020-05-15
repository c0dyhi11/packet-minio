output "minio_endpoint" {
    value = format("http://%s:9000", packet_device.minio.access_public_ipv4)
}

output "minio_access_key"{
    value = random_string.minio_access_key.result
}

output "minio_access_secret"{
    value = random_string.minio_secret_key.result
}

output "minio_region_name" {
    value = "us-east-1"
}

output "minio_public_bucket_name" {
    value = "public"
}
