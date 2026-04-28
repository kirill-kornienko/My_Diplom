# Скачиваю и устанавливаю актуальную версию Terraform
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


