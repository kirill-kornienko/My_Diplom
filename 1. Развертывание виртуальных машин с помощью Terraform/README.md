# 1. Скачиваю и устанавливаю актуальную версию Terraform
```
wget https://hashicorp-releases.yandexcloud.net/terraform/1.15.0-rc3/terraform_1.15.0-rc3_linux_amd64.zip
unzip terraform_1.15.0-rc3_linux_amd64.zip
chmod 744 terraform
mv terraform /usr/local/bin/
terraform -version
```

![terraform_install](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%B0%D0%B2%D0%BB%D0%B8%D0%B2%D0%B0%D1%8E%20terraform.png)

Создаю файл `.terraformrc` и добавляю источник, из которго будет установлен провайдер

```nano ~/.terraformrc```

```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

![terraformrc](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D1%8E%20terraformrc.png)

Для того чтобы подключаться к ВМ по SSH без пароля необходимо сгенерировать SSH ключ и поместить его в файл `meta.yaml`

Для  Yandex Cloud рекомендуется использовать алгоритм Ed25519: сгенерированные по нему ключи — самые безопасные.

Генерирую SSH ключ

```
ssh-keygen -t ed25519
```

![ssh](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D1%8E%20SSH-%D0%BA%D0%BB%D1%8E%D1%87.png)

Создаю файл `meta.yaml` с данными пользователя

```
#cloud-config
 users:
  - name: kirill
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-ed25519
```

![meta.yaml](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D1%8E%20meta.yaml.png)

Создаю `playbook Terraform` c блоком провайдера.

```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
```

![main.tf](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D1%8E%20main.tf.png)

Инициализирую провайдера

```
terraform init
```

![terraform init](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D0%98%D0%BD%D0%B8%D1%86%D0%B8%D0%B0%D0%BB%D0%B8%D0%B7%D0%B8%D1%80%D1%83%D1%8E%20%D0%BF%D1%80%D0%BE%D0%B2%D0%B0%D0%B9%D0%B4%D0%B5%D1%80%D0%B0.png)

### 2. По условиям задачи необходимо развернуть через terraform следующий ресурcы:

**Сайт. Веб-сервера. Nginx.** 

- Создать две ВМ в разных зонах, установить на них сервер nginx.

- Создать Target Group, включить в неё две созданные ВМ.
  
- Создать Backend Group, настроить backends на target group, ранее созданную. Настроить healthcheck на корень (/) и порт 80, протокол HTTP.
  
- Создать HTTP router. Путь указать — /, backend group — созданную ранее.
  
- Создать Application load balancer для распределения трафика на веб-сервера, созданные ранее. Указать HTTP router, созданный ранее, задать listener тип auto, порт 80.

```
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


```

**Мониторинг. Zabbix. Zabbix-agent.**

- Создать ВМ, развернуть на ней Zabbix. На каждую ВМ установить Zabbix Agent, настроить агенты на отправление метрик в Zabbix.

```
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

```

**Логи. Elasticsearch. Kibana. Filebeat.**

- Cоздать ВМ, развернуть на ней Elasticsearch. Установить Filebeat в ВМ к веб-серверам, настроить на отправку access.log, error.log nginx в Elasticsearch.

- Создать ВМ, развернуть на ней Kibana, сконфигурировать соединение с Elasticsearch.

```
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

```

**Сеть**

- Развернуть один VPC.

- Сервера web, Elasticsearch поместить в приватные подсети.

- Сервера Zabbix, Kibana, application load balancer определить в публичную подсеть.

- Настроить Security Groups соответствующих сервисов на входящий трафик только к нужным портам.

- Настроить ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Эта вм будет реализовывать концепцию bastion host.

```

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


```

**Резервное копирование.**

- Создать snapshot дисков всех ВМ.

- Ограничить время жизни snaphot в неделю.

- Сами snaphot настроить на ежедневное копирование.

```
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

```

### 3. Запуксаю terraform playbook.

```
terraform init
terraform plan
terraform apply
```

![terraform plan](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/terraform%20plan.png)

При развертывании с помощью terraform появлялась ошибка превышения квоты создания публичных IP, поэтому был добавлен параметр -parallelism=1

```
terraform apply -auto-approve -parallelism=1
```


![terraform apply](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/terraform%20apply.png)

![terraform_apply2](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/terraform_apply%202.png)

Проверяю что установилось

![terraform state list](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/terraform_state_list.png)

![backend](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/backend.png)

![router](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D1%80%D0%BE%D1%83%D1%82%D0%B5%D1%80.png)

![balancer](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/balancer.png)

![ВМ](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/%D0%92%D0%9C.png)

![snapshot_time](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/snapshot_diplom.png)

![snapshot](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/snapshot_disks.png)

![gateway](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/gateway.png)

![networks](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/network.png)

![route_table](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/route_table.png)

![sec_group](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/secure_group.png)

![disks](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/disks.png)

![target_group](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/target.png)

![dashboard](https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/dashboard.png)


Далее следует второй этап выполнения работы [установка и подготовка Ansible. Установка и настройка сервисов]( https://github.com/kirill-kornienko/My_Diplom/tree/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2)



