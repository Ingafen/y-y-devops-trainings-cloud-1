variable "folder-id" {
    default = "bgggggggggggggg"
    type = string  
}

variable "service-account-name" {
    default = "direbo-sa"
    type = string
}

variable "container-registry-name" {
    default = "direbo-cr"
    type = string
}

variable "app-name" {
    default = "catgpt"
    type = string
    description = "application image name"
}