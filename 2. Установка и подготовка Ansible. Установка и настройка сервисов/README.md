### 1. Установка и подготовка Ansible.

Устанавливаю Ansible и проверяю версию

```
apt install ansible
ansible --version
```

![ansible](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/Ansible%20.png)

Создаю файл `ansible.cfg` и inventory `hosts` для выполнения задач дипломной работы.
```
sudo nano ansible.cfg
```

`ansible.cfg` заполняю следующие строки

```
inventory      = /root/hosts
host_key_checking = false
remote_user = kirill
private_key_file = /root/.ssh/id_ed25519
become=True
```
создаю файл hosts

```
nano hosts
```

`hosts` настраиваю подключение к ресурсам через ProxyCommand.

```
[nginx-web]
nginx-web-1
nginx-web-2

[zabbix]
zabbix

[elasticsearch]
elasticsearch

[kibana]
kibana

[nginx-web:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.189.206"'

[zabbix:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.189.206"'

[elasticsearch:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.189.206"'

[kibana:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.189.206"'
```

