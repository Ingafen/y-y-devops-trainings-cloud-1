terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_vpc_network" "direbo-vpc" {
}

resource "yandex_vpc_subnet" "direbo-vpc-subnet" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.direbo-vpc.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

resource "yandex_container_registry" "ycr" {
  name = var.container-registry-name
}

locals {
  ycr-id = yandex_container_registry.ycr.id
  service-accounts = toset([
    var.service-account-name
  ])
  catgpt-sa-roles = toset([
    "container-registry.images.puller",
    "monitoring.editor",
  ])
}
resource "yandex_iam_service_account" "service-accounts" {
  for_each = local.service-accounts
  name     = "${var.folder-id}-${each.key}"
}
resource "yandex_resourcemanager_folder_iam_member" "catgpt-roles" {
  for_each  = local.catgpt-sa-roles
  folder_id = var.folder-id
  member    = "serviceAccount:${yandex_iam_service_account.service-accounts[var.service-account-name].id}"
  role      = each.key
}

data "yandex_compute_image" "coi" {
  family = "container-optimized-image"
}
resource "yandex_compute_instance" "catgpt-1" {
    platform_id        = "standard-v2"
    service_account_id = yandex_iam_service_account.service-accounts[var.service-account-name].id
    resources {
      cores         = 2
      memory        = 1
      core_fraction = 5
    }
    scheduling_policy {
      preemptible = true
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.direbo-vpc-subnet.id}"
      nat = true
    }
    boot_disk {
      initialize_params {
        type = "network-hdd"
        size = "30"
        image_id = data.yandex_compute_image.coi.id
      }
    }
    metadata = {
      docker-compose = templatefile("${path.module}/docker-compose.yaml", {cr-id = local.ycr-id, app-name = var.app-name})
      ssh-keys  = "ubuntu:${file("${path.module}/.ssh/devops-training.pub")}"
    }
}

output "docker-compose" {
  value = yandex_compute_instance.catgpt-1.metadata["docker-compose"]
}