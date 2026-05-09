terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# ======================== Сеть и подсети ========================
resource "yandex_vpc_network" "network-diplom" {
  name = "network-diplom"
}

resource "yandex_vpc_subnet" "a-subnet-diplom" {
  name           = "a-subnet-diplom"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-diplom.id
  route_table_id = yandex_vpc_route_table.gateway-route.id
}

resource "yandex_vpc_subnet" "b-subnet-diplom" {
  name           = "b-subnet-diplom"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-diplom.id
  route_table_id = yandex_vpc_route_table.gateway-route.id
}

resource "yandex_vpc_subnet" "d-subnet-diplom" {
  name           = "d-subnet-diplom"
  v4_cidr_blocks = ["192.168.30.0/24"]
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-diplom.id
  route_table_id = yandex_vpc_route_table.gateway-route.id
}

# ======================== NAT-шлюз и таблица маршрутизации ========================
resource "yandex_vpc_gateway" "gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "gateway-route" {
  name       = "gateway-route"
  network_id = yandex_vpc_network.network-diplom.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.gateway.id
  }
}

# ======================== Группы безопасности ========================
resource "yandex_vpc_security_group" "bastion-security-local" {
  name        = "bastion-security-local"
  description = "Bastion security for local ip"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "IN to 22 port from local ip"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
    port           = 22
  }

  egress {
    protocol       = "TCP"
    description    = "OUT from 22 port to local ip"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
    port           = 22
  } 

  egress {
    protocol       = "ANY"
    description    = "OUT from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}


resource "yandex_vpc_security_group" "nginx-web-security" {
  name        = "nginx-web-security"
  description = "Nginx-web security"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "ANY"
    description    = "IN to 80 port from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "OUT from 80 port to any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ANY"
    description    = "IN to 10050 port from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "OUT from 10050 port to any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }
}

resource "yandex_vpc_security_group" "zabbix-security" {
  name        = "zabbix-security"
  description = "Zabbix security"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "IN to 80 port from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "TCP"
    description    = "OUT from 80 port to any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "IN to 10051 from local ip"
    v4_cidr_blocks = ["192.168.10.0/24","192.168.20.0/24","192.168.30.0/24"]
    port           = 10051
  }

    egress {
    protocol       = "TCP"
    description    = "OUT from 10051 port to local ip"
    v4_cidr_blocks = ["192.168.10.0/24","192.168.20.0/24","192.168.30.0/24"]
    port           = 10051
  }
}

resource "yandex_vpc_security_group" "elasticsearch-security" {
  name        = "elasticsearch-security"
  description = "Elasticsearch security"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "IN to 9200 port from local ip"
    v4_cidr_blocks = ["192.168.10.0/24","192.168.20.0/24","192.168.30.0/24"]
    port           = 9200
  }

  egress {
    protocol       = "TCP"
    description    = "OUT from 9200 port to local ip"
    v4_cidr_blocks = ["192.168.10.0/24","192.168.20.0/24","192.168.30.0/24"]
    port           = 9200
  }

  ingress {
    protocol       = "ANY"
    description    = "IN to 10050 port from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "OUT from 10050 port to any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }
}

resource "yandex_vpc_security_group" "kibana-security" {
  name        = "kibana-security"
  description = "Kibana security"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "ANY"
    description    = "IN to 10050 port from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "OUT from 10050 to any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    description    = "IN to 5601 port from any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  egress {
    protocol       = "TCP"
    description    = "OUT from 5601 to any ip"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
}

resource "yandex_vpc_security_group" "filebeat-security" {
  name        = "filebeat-security"
  description = "Filebeat security"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "IN to 5044 port from local ip"
    v4_cidr_blocks = ["192.168.10.0/24","192.168.20.0/24","192.168.30.0/24"]
    port           = 5044
  }

  egress {
    protocol       = "TCP"
    description    = "OUT from 5044 to local ip"
    v4_cidr_blocks = ["192.168.10.0/24","192.168.20.0/24","192.168.30.0/24"]
    port           = 5044
  }
}
resource "yandex_vpc_security_group" "internal-ssh" {
  name        = "internal-ssh"
  description = "SSH between internal subnets"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from internal"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
    port           = 22
  }

  egress {
    protocol       = "TCP"
    description    = "SSH to internal"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound internet traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "nginx-http" {
  name        = "nginx-http"
  description = "Allow HTTP from anywhere"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "bastion-security" {
  name        = "bastion-security"
  description = "Allow SSH from anywhere"
  network_id  = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ======================== Bastion (публичный IP) ========================
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  zone        = yandex_vpc_subnet.d-subnet-diplom.zone
  platform_id = "standard-v3"
  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.d-subnet-diplom.id
    nat                = true
    ipv4               = true
    ip_address         = "192.168.30.3"
    security_group_ids = [yandex_vpc_security_group.bastion-security.id]
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
}

# ======================== Веб-сервер 1 ========================
resource "yandex_compute_instance" "nginx-web-1" {
  name        = "nginx-web-1"
  hostname    = "nginx-web-1"
  zone        = yandex_vpc_subnet.a-subnet-diplom.zone
  platform_id = "standard-v3"
  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.a-subnet-diplom.id
    ipv4               = true
    ip_address         = "192.168.10.3"
    security_group_ids = [yandex_vpc_security_group.internal-ssh.id, yandex_vpc_security_group.nginx-http.id]
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
}

# ======================== Веб-сервер 2 ========================
resource "yandex_compute_instance" "nginx-web-2" {
  name        = "nginx-web-2"
  hostname    = "nginx-web-2"
  zone        = yandex_vpc_subnet.b-subnet-diplom.zone
  platform_id = "standard-v3"
  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.b-subnet-diplom.id
    ipv4               = true
    ip_address         = "192.168.20.3"
    security_group_ids = [yandex_vpc_security_group.internal-ssh.id, yandex_vpc_security_group.nginx-http.id]
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
}

# ======================== Zabbix ========================
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  zone        = yandex_vpc_subnet.d-subnet-diplom.zone
  platform_id = "standard-v3"
  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.d-subnet-diplom.id
    ipv4               = true
    ip_address         = "192.168.30.4"
    nat                = true
    security_group_ids = [
      yandex_vpc_security_group.internal-ssh.id,
      yandex_vpc_security_group.nginx-http.id
    ]
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
}

# ======================== Elasticsearch ========================
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  zone        = yandex_vpc_subnet.a-subnet-diplom.zone
  platform_id = "standard-v3"
  resources {
    cores         = 2
    core_fraction = 20
    memory        = 4
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.a-subnet-diplom.id
    ipv4               = true
    ip_address         = "192.168.10.4"
    security_group_ids = [yandex_vpc_security_group.internal-ssh.id]
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
}

# ======================== Kibana  ========================
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  zone        = yandex_vpc_subnet.d-subnet-diplom.zone
  platform_id = "standard-v3"
  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.d-subnet-diplom.id
    ipv4               = true
    ip_address         = "192.168.30.5"
    nat                = true
    security_group_ids = [yandex_vpc_security_group.internal-ssh.id]
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
}

# ======================== Балансировщик ========================
resource "yandex_alb_target_group" "nginx-target-group" {
  name = "nginx-target-group"
  target {
    subnet_id  = yandex_vpc_subnet.a-subnet-diplom.id
    ip_address = yandex_compute_instance.nginx-web-1.network_interface[0].ip_address
  }
  target {
    subnet_id  = yandex_vpc_subnet.b-subnet-diplom.id
    ip_address = yandex_compute_instance.nginx-web-2.network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "nginx-backend-group" {
  name = "nginx-backend-group"
  session_affinity {
    connection {
      source_ip = false
    }
  }
  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.nginx-target-group.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "nginx-tf-router" {
  name   = "nginx-tf-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "nginx-virtual-host" {
  name           = "nginx-virtual-host"
  http_router_id = yandex_alb_http_router.nginx-tf-router.id
  route {
    name = "nginx-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.nginx-backend-group.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "nginx-balancer" {
  name        = "nginx-balancer"
  network_id  = yandex_vpc_network.network-diplom.id
  allocation_policy {
    location {
      zone_id   = yandex_vpc_subnet.d-subnet-diplom.zone
      subnet_id = yandex_vpc_subnet.d-subnet-diplom.id
    }
  }
  listener {
    name = "nginx-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.nginx-tf-router.id
      }
    }
  }
}

# ======================== Snapshot schedule ========================
resource "yandex_compute_snapshot_schedule" "snapshot-diplom" {
  name = "snapshot-diplom"
  schedule_policy {
    expression = "30 1 * * *"
  }
  snapshot_count = 7
  snapshot_spec {
    description = "Snapshots. Every day at 01:30"
  }
  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.nginx-web-1.boot_disk[0].disk_id,
    yandex_compute_instance.nginx-web-2.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.elasticsearch.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id
  ]
}
