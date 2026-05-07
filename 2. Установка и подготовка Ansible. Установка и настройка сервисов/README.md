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
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.190.38"'

[zabbix:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.190.38"'

[elasticsearch:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.190.38"'

[kibana:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q kirill@81.26.190.38"'
```

### Создаю и запускаю Ansible-playbooks для установки и конфигурирования сервисов указанных в задании

создаю `playbook-nginx-web.yaml`

```
nano playbook-nginx-web.yaml
```

```
---
- name: "install nginx --> replacing a file index.nginx-ubuntu.html --> restart nginx"
  hosts: nginx-web
  become: true

  tasks:
  - name: "1/4 apt update"
    apt:
      update_cache: yes

  - name: "2/4 install nginx"
    apt:
      name: nginx
      state: latest

  - name: "3/4 replacing a file 'index.nginx-ubuntu.html' for nginx-web"
    copy:
      src: /root/index.nginx-ubuntu.html
      dest: /var/www/html/index.nginx-ubuntu.html

  - name: "4/4 restart Nginx"
    systemd:
      name: nginx
      state: restarted
```
создаю `playbook-zabbix.yaml`

```
nano playbook-zabbix.yaml
```

```
---
- name: "download and install zabbix on Ubuntu 24"
  hosts: zabbix
  become: true

  tasks:
  - name: "1/8 apt update"
    apt:
      update_cache: yes

  - name: "2/8 install postgresql"
    apt:
      name: postgresql
      state: latest

  - name: "3/8 download zabbix release package"
    get_url:
      url: https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-5+ubuntu24.04_all.deb
      dest: "/home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb"

  - name: "4/8 install zabbix release package"
    apt:
      deb: /home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb

  - name: "5/8 apt update again (after adding zabbix repo)"
    apt:
      update_cache: yes

  - name: "6/8 install zabbix server, frontend, agent and postgresql modules"
    apt:
      name:
        - zabbix-server-pgsql
        - zabbix-frontend-php
        - php8.3-pgsql
        - zabbix-apache-conf
        - zabbix-sql-scripts
        - zabbix-agent
      state: latest

  - name: "7/8 create user and database zabbix, import schema, configure DB password"
    shell: |
      su - postgres -c 'psql --command "CREATE USER zabbix WITH PASSWORD '\''123456789'\'';"'
      su - postgres -c 'psql --command "CREATE DATABASE zabbix OWNER zabbix;"'
      zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
      sed -i 's/# DBPassword=/DBPassword=123456789/g' /etc/zabbix/zabbix_server.conf

  - name: "8/8 restart and enable zabbix-server and apache2"
    shell: |
      systemctl restart zabbix-server apache2
      systemctl enable zabbix-server apache2
```

создаю `playbook-zabbix-agent.yaml`

```
nano playbook-zabbix-agent.yaml
```

```
---
- name: "download and install zabbix-agent on Ubuntu 24"
  hosts: all
  become: true

  tasks:
  - name: "1/7 apt update"
    apt:
      upgrade: yes
      update_cache: yes

  - name: "2/7 download zabbix release package (Ubuntu 24)"
    get_url:
      url: https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-5+ubuntu24.04_all.deb
      dest: "/home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb"

  - name: "3/7 install zabbix release package"
    apt:
      deb: /home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb

  - name: "4/7 apt update again (after adding repo)"
    apt:
      update_cache: yes

  - name: "5/7 install zabbix-agent"
    apt:
      name: zabbix-agent
      state: latest

  - name: "6/7 configure zabbix_agentd.conf (Server IP = 192.168.30.4)"
    replace:
      path: /etc/zabbix/zabbix_agentd.conf
      regexp: '^Server=127.0.0.1'
      replace: 'Server=192.168.30.4'

  - name: "7/7 restart and enable zabbix-agent"
    systemd:
      name: zabbix-agent
      state: restarted
      enabled: yes
```

создаю `playbook-elasticsearch.yaml`

```
nano playbook-elasticsearch.yaml
```

```
---
- name: "download and install elasticsearch on Ubuntu 24"
  hosts: elasticsearch
  become: true

  tasks:
  - name: "1/5 install gnupg and apt-transport-https"
    apt:
      name:
        - gnupg
        - apt-transport-https
      state: present

  - name: "2/5 download elasticsearch 7.17.9 deb package"
    get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/elasticsearch-7.17.9-amd64.deb
      dest: "/home/kirill/elasticsearch-7.17.9-amd64.deb"

  - name: "3/5 install elasticsearch from deb"
    apt:
      deb: /home/kirill/elasticsearch-7.17.9-amd64.deb

  - name: "4/5 copy custom elasticsearch.yml configuration"
    copy:
      src: /root/elasticsearch.yml
      dest: /etc/elasticsearch/elasticsearch.yml
      owner: root
      group: elasticsearch
      mode: '0644'
    notify: restart elasticsearch

  - name: "5/5 enable and start elasticsearch"
    systemd:
      name: elasticsearch
      enabled: yes
      state: started

  handlers:
    - name: restart elasticsearch
      systemd:
        name: elasticsearch
        state: restarted
```

создаю `playbook-kibana`

```
nano playbook-kibana.yaml
```

```
---
- name: "download and install kibana on Ubuntu 24"
  hosts: kibana
  become: true

  tasks:
  - name: "1/5 install gnupg and apt-transport-https"
    apt:
      name:
        - gnupg
        - apt-transport-https
      state: present

  - name: "2/5 download kibana 7.17.9 deb package"
    get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/k/kibana/kibana-7.17.9-amd64.deb
      dest: "/home/kirill/kibana-7.17.9-amd64.deb"

  - name: "3/5 install kibana from deb"
    apt:
      deb: /home/kirill/kibana-7.17.9-amd64.deb

  - name: "4/5 copy custom kibana.yml configuration"
    copy:
      src: /root/kibana.yml
      dest: /etc/kibana/kibana.yml
      owner: root
      group: kibana
      mode: '0644'
    notify: restart kibana

  - name: "5/5 enable and start kibana"
    systemd:
      name: kibana
      enabled: yes
      state: started

  handlers:
    - name: restart kibana
      systemd:
        name: kibana
        state: restarted
```

создаю `playbook-filebeat.yaml`

```
nano playbook-filebeat.yaml
```

```
---
- name: "download and install filebeat for nginx-web-1 (Ubuntu 24)"
  hosts: nginx-web-1
  become: true

  tasks:
  - name: "1/5 install gnupg and apt-transport-https"
    apt:
      name:
        - gnupg
        - apt-transport-https
      state: present

  - name: "2/5 download filebeat 7.17.9 deb package"
    get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/f/filebeat/filebeat-7.17.9-amd64.deb
      dest: "/home/kirill/filebeat-7.17.9-amd64.deb"

  - name: "3/5 install filebeat from deb"
    apt:
      deb: /home/kirill/filebeat-7.17.9-amd64.deb

  - name: "4/5 copy custom filebeat.yml configuration"
    copy:
      src: /root/filebeat.yml
      dest: /etc/filebeat/filebeat.yml
      owner: root
      group: root
      mode: '0644'
    notify: restart filebeat

  - name: "5/5 enable and start filebeat"
    systemd:
      name: filebeat
      enabled: yes
      state: started

  handlers:
    - name: restart filebeat
      systemd:
        name: filebeat
        state: restarted
```

создаю `playbook-filebeat2.yaml`

```
nano playbook-filebeat2.yaml
```

```
---
- name: "download and install filebeat for nginx-web-2 (Ubuntu 24)"
  hosts: nginx-web-2
  become: true

  tasks:
  - name: "1/5 install gnupg and apt-transport-https"
    apt:
      name:
        - gnupg
        - apt-transport-https
      state: present

  - name: "2/5 download filebeat 7.17.9 deb package"
    get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/f/filebeat/filebeat-7.17.9-amd64.deb
      dest: "/home/kirill/filebeat-7.17.9-amd64.deb"

  - name: "3/5 install filebeat from deb"
    apt:
      deb: /home/kirill/filebeat-7.17.9-amd64.deb

  - name: "4/5 copy custom filebeat2.yml configuration"
    copy:
      src: /root/filebeat2.yml
      dest: /etc/filebeat/filebeat.yml
      owner: root
      group: root
      mode: '0644'
    notify: restart filebeat

  - name: "5/5 enable and start filebeat"
    systemd:
      name: filebeat
      enabled: yes
      state: started

  handlers:
    - name: restart filebeat
      systemd:
        name: filebeat
        state: restarted
```
создаю ссылку на файл с сайтом

```
nano index.nginx-ubuntu.html
```
```
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Дипломная работа по профессии «Системный администратор»</title>
    <!-- Атрибут href можно оставить, если у вас есть файл стилей. Или удалите строку полностью -->
    <!-- <link rel="stylesheet" href="./styles/style.css"> -->
</head>
<body>
    <header>
        <h1>Дипломная работа по профессии<br> «Системный администратор»</h1>
        <h4>Выполнил: Кирилл Корниенко</h4>
        <h4>Группа: SYS-52</h4>
    </header>

    <main>
        <article>
            <section>
                <h3>Дипломная работа состоит из трех частей:</h3>
                <nav>
                    <ol>
                        <li><a href="https://github.com/kirill-kornienko/My_Diplom/blob/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform/README.md">Развертывание виртуальной инфраструктуры</a></li>
                        <li><a href="https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/README.md">Установка и настройка Ansible и сервисов</a></li>
                        <li><a href="https://github.com/kirill-kornienko/My_Diplom/blob/main/3.%20%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0%20%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D0%BE%D0%B2%20%D0%B8%20%D0%B2%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5%20%D0%B7%D0%B0%D0%B4%D0%B0%D1%87/README.md">Финальная проверка всех компонентов</a></li>
                    </ol>
                </nav>
            </section>
        </article>
    </main>
</body>
</html>
```
создаю конфигурационные файлы:

```
nano elasticsearch.yml
```

```
# ======================== Elasticsearch Configuration =========================
#
# ---------------------------------- Cluster -----------------------------------
#
cluster.name: kirill-diplom
#
# ------------------------------------ Node ------------------------------------
#
node.name: node-1
#
# ----------------------------------- Paths ------------------------------------
#
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
#
# ----------------------------------- Memory -----------------------------------
#
#bootstrap.memory_lock: true
#
# ---------------------------------- Network -----------------------------------
#
network.host: 0.0.0.0
http.port: 9200
#
# --------------------------------- Discovery ----------------------------------
#
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
#
# ---------------------------------- Security ----------------------------------
#
```

```
nano kibana.yml
```

```
server.port: 5601
server.host: 0.0.0.0
server.publicBaseUrl: "http://81.26.190.89:5601"   # замените на реальный внешний IP вашей kibana

elasticsearch.hosts: ["http://192.168.10.4:9200"]
```

```
nano filebeat.yml
```

```
###################### Filebeat Configuration #########################
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log

output.elasticsearch:
  hosts: ["192.168.10.4:9200"]
  index: "nginx-web-1"

processors:
  - drop_fields:
      fields: ["beat", "input_type", "prospector", "input", "host", "agent", "ecs"]
```

```
nano filebeat2.yml
```

```
###################### Filebeat Configuration #########################
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log

output.elasticsearch:
  hosts: ["192.168.10.4:9200"]
  index: "nginx-web-2"

processors:
  - drop_fields:
      fields: ["beat", "input_type", "prospector", "input", "host", "agent", "ecs"]
```

### Сайт

Устанавливаю сервер nginx на две ВМ. Заменаяю стандартный файл на `index.nginx-ubuntu.html`

```
!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Дипломная работа по профессии «Системный администратор»</title>
        <!-- <link rel="stylesheet" href="./styles/style.css"> -->
</head>
<body>
    <header>
        <h1>Дипломная работа по профессии<br> «Системный администратор»</h1>
        <h4>Выполнил: Кирилл Корниенко</h4>
        <h4>Группа: SYS-52</h4>
    </header>

    <main>
        <article>
            <section>
                <h3>Дипломная работа состоит из трех этапов:</h3>
                <nav>
                    <ol>
                        <li><a href="https://github.com/kirill-kornienko/My_Diplom/blob/main/[1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1>](https://github.com/kirill-kornienko/My_Diplom/tree/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform)>
                        <li><a href="https://github.com/kirill-kornienko/My_Diplom/blob/main/[2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0>](https://github.com/kirill-kornienko/My_Diplom/tree/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2)>
                        <li><a href="https://github.com/kirill-kornienko/My_Diplom/blob/main/[3.%20%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0](https://github.com/kirill-kornienko/My_Diplom/tree/main/3.%20%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0%20%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D0%BE%D0%B2%20%D0%B8%20%D0%B2%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5%20%D0%B7%D0%B0%D0%B4%D0%B0%D1%87)>
                    </ol>
                </nav>
            </section>
        </article>
    </main>
</body>
</html>

```
### Мониторинг. Zabbix. Zabbix-agent.

Разворачива Zabbix

```

---
- name: "download and install zabbix on Ubuntu 24"
  hosts: zabbix
  become: true

  tasks:
  - name: "1/8 apt update"
    apt:
      update_cache: yes

  - name: "2/8 install postgresql"
    apt:
      name: postgresql
      state: latest

  - name: "3/8 download zabbix release package"
    get_url:
      url: https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-5+ubuntu24.04_all.deb
      dest: "/home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb"

  - name: "4/8 install zabbix release package"
    apt:
      deb: /home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb

  - name: "5/8 apt update again (after adding zabbix repo)"
    apt:
      update_cache: yes

  - name: "6/8 install zabbix server, frontend, agent and postgresql modules"
    apt:
      name:
        - zabbix-server-pgsql
        - zabbix-frontend-php
        - php8.3-pgsql
        - zabbix-apache-conf
        - zabbix-sql-scripts
        - zabbix-agent
      state: latest

  - name: "7/8 create user and database zabbix, import schema, configure DB password"
    shell: |
      su - postgres -c 'psql --command "CREATE USER zabbix WITH PASSWORD '\''123456789'\'';"'
      su - postgres -c 'psql --command "CREATE DATABASE zabbix OWNER zabbix;"'
      zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
      sed -i 's/# DBPassword=/DBPassword=123456789/g' /etc/zabbix/zabbix_server.conf

  - name: "8/8 restart and enable zabbix-server and apache2"
    shell: |
      systemctl restart zabbix-server apache2
      systemctl enable zabbix-server apache2
```

На каждую ВМ устанавливаю Zabbix Agent

```
- name: "download and install zabbix-agent on Ubuntu 24"
  hosts: all
  become: true

  tasks:
  - name: "1/7 apt update"
    apt:
      upgrade: yes
      update_cache: yes

  - name: "2/7 download zabbix release package (Ubuntu 24)"
    get_url:
      url: https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-5+ubuntu24.04_all.deb
      dest: "/home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb"

  - name: "3/7 install zabbix release package"
    apt:
      deb: /home/kirill/zabbix-release_6.0-5+ubuntu24.04_all.deb

  - name: "4/7 apt update again (after adding repo)"
    apt:
      update_cache: yes

  - name: "5/7 install zabbix-agent"
    apt:
      name: zabbix-agent
      state: latest

  - name: "6/7 configure zabbix_agentd.conf (Server IP = 192.168.30.4)"
    replace:
      path: /etc/zabbix/zabbix_agentd.conf
      regexp: '^Server=127.0.0.1'
      replace: 'Server=192.168.30.4'

  - name: "7/7 restart and enable zabbix-agent"
    systemd:
      name: zabbix-agent
      state: restarted
      enabled: yes
```
### Логи. Elasticsearch. Kibana. Filebeat.

Разворачиваю на ВМ Elasticsearch

```
---
- name: "download and install elasticsearch on Ubuntu 24"
  hosts: elasticsearch
  become: true

  tasks:
  - name: "1/5 install gnupg and apt-transport-https"
    apt:
      name:
        - gnupg
        - apt-transport-https
      state: present

  - name: "2/5 download elasticsearch 7.17.9 deb package"
    get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/elasticsearch-7.17.9-amd64.deb
      dest: "/home/kirill/elasticsearch-7.17.9-amd64.deb"

  - name: "3/5 install elasticsearch from deb"
    apt:
      deb: /home/kirill/elasticsearch-7.17.9-amd64.deb

  - name: "4/5 copy custom elasticsearch.yml configuration"
    copy:
      src: /root/elasticsearch.yml
      dest: /etc/elasticsearch/elasticsearch.yml
      owner: root
      group: elasticsearch
      mode: '0644'
    notify: restart elasticsearch

  - name: "5/5 enable and start elasticsearch"
    systemd:
      name: elasticsearch
      enabled: yes
      state: started

  handlers:
    - name: restart elasticsearch
      systemd:
        name: elasticsearch
        state: restarted
```

Разворачиваю на другой ВМ Kibana, конфигурирую соединение с Elasticsearch

```
---
- name: "download and install kibana on Ubuntu 24"
  hosts: kibana
  become: true

  tasks:
  - name: "1/5 install gnupg and apt-transport-https"
    apt:
      name:
        - gnupg
        - apt-transport-https
      state: present

  - name: "2/5 download kibana 7.17.9 deb package"
    get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/k/kibana/kibana-7.17.9-amd64.deb
      dest: "/home/kirill/kibana-7.17.9-amd64.deb"

  - name: "3/5 install kibana from deb"
    apt:
      deb: /home/kirill/kibana-7.17.9-amd64.deb

  - name: "4/5 copy custom kibana.yml configuration"
    copy:
      src: /root/kibana.yml
      dest: /etc/kibana/kibana.yml
      owner: root
      group: kibana
      mode: '0644'
    notify: restart kibana

  - name: "5/5 enable and start kibana"
    systemd:
      name: kibana
      enabled: yes
      state: started

  handlers:
    - name: restart kibana
      systemd:
        name: kibana
        state: restarted
```

Устанавливаю Filebeat в ВМ к веб-серверам, настраиваю на отправку access.log, error.log nginx в Elasticsearch.

```
###################### Filebeat Configuration #########################
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log

output.elasticsearch:
  hosts: ["192.168.10.4:9200"]
  index: "nginx-web-1"

processors:
  - drop_fields:
      fields: ["beat", "input_type", "prospector", "input", "host", "agent", "ecs"]
```

```
###################### Filebeat Configuration #########################
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log

output.elasticsearch:
  hosts: ["192.168.10.4:9200"]
  index: "nginx-web-2"

processors:
  - drop_fields:
      fields: ["beat", "input_type", "prospector", "input", "host", "agent", "ecs"]
```
### Все сервисы через ansible развернуты.

Далее третий этап дипломной паботы [Ghjdthrf ресурсов и выполнение задач](https://github.com/kirill-kornienko/My_Diplom/tree/main/3.%20%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0%20%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D0%BE%D0%B2%20%D0%B8%20%D0%B2%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5%20%D0%B7%D0%B0%D0%B4%D0%B0%D1%87)





