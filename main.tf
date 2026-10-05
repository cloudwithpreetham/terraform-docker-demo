terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 4.6.0"
    }
  }

  required_version = ">= 1.5.0"
}

# Configure the Docker provider
provider "docker" {}

# Pull the Docker image for the application
resource "docker_image" "nginx_image" {
  name         = "nginx:latest"
  keep_locally = false
}

# Provision a Docker container for the application
resource "docker_container" "nginx_container" {
  name  = "terraform-docker-nginx"
  image = docker_image.nginx_image.image_id
  ports {
    internal = 80
    external = 8080
  }
}

# Outputs for verification
output "nginx_container_id" {
  description = "The ID of the Nginx Docker container"
  value       = docker_container.nginx_container.id
}

output "nginx_container_name" {
  description = "The name of the Nginx Docker container"
  value       = docker_container.nginx_container.name
}

output "application_url" {
  description = "The URL to access the Nginx application"
  value       = "http://localhost:8080"
}
