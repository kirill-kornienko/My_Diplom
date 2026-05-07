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

```bash
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

```yaml
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
      src: /home/kirill/index.nginx-ubuntu.html
      dest: /var/www/html/index.html

  - name: "4/4 restart Nginx"
    shell: |
      systemctl daemon-reload
      systemctl enable nginx
      systemctl restart nginx

```
создаю `playbook-zabbix.yaml`

```
nano playbook-zabbix.yaml
```

```yaml
---
- name: "Install Zabbix 6.0 on Ubuntu 22.04 with PostgreSQL 14"
  hosts: zabbix
  become: true

  tasks:
    - name: "1/9 Install acl and python3-psycopg2"
      apt:
        name:
          - acl
          - python3-psycopg2
        state: present

    - name: "2/9 Update apt cache"
      apt:
        update_cache: yes

    - name: "3/9 Install PostgreSQL 14 and contrib"
      apt:
        name:
          - postgresql-14
          - postgresql-contrib-14
        state: present

    - name: "4/9 Download Zabbix release package"
      get_url:
        url: https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_6.0+ubuntu22.04_all.deb
        dest: /home/kirill/zabbix-release.deb

    - name: "5/9 Install Zabbix release package"
      apt:
        deb: /home/kirill/zabbix-release.deb

    - name: "6/9 Update apt after adding repo"
      apt:
        update_cache: yes

    - name: "7/9 Install Zabbix components"
      apt:
        name:
          - zabbix-server-pgsql
          - zabbix-frontend-php
          - php8.1-pgsql
          - zabbix-apache-conf
          - zabbix-sql-scripts
          - zabbix-agent
        state: present

    - name: "8/9 Create PostgreSQL user and database"
      shell: |
        sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '123456789';" || true
        sudo -u postgres psql -c "CREATE DATABASE zabbix OWNER zabbix;" || true
      changed_when: false

    - name: "9/9 Import Zabbix schema"
      shell: |
        zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix || true
      changed_when: false

    - name: "10/9 Configure DB password and restart services"
      shell: |
        sed -i 's/# DBPassword=/DBPassword=123456789/g' /etc/zabbix/zabbix_server.conf
        systemctl restart zabbix-server zabbix-agent apache2
        systemctl enable zabbix-server zabbix-agent apache2
      changed_when: false

```

создаю `playbook-zabbix-agent.yaml`

```
nano playbook-zabbix-agent.yaml
```

```yaml
---
- name: "Install Zabbix Agent on Ubuntu"
  hosts: all
  become: true

  tasks:
    - name: "1/7 Update apt cache"
      apt:
        update_cache: yes

    - name: "2/7 Install prerequisites (wget)"
      apt:
        name: wget
        state: present

    - name: "3/7 Download Zabbix release package (force)"
      shell: |
        wget -O /home/kirill/zabbix-release.deb https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_6.0+ubuntu22.04_all.deb

    - name: "4/7 Verify that file exists"
      stat:
        path: /home/kirill/zabbix-release.deb
      register: deb_file

    - name: "5/7 Install Zabbix release package"
      apt:
        deb: "/home/kirill/zabbix-release.deb"
      when: deb_file.stat.exists

    - name: "6/7 Update apt after adding repo"
      apt:
        update_cache: yes

    - name: "7/7 Install Zabbix agent"
      apt:
        name: zabbix-agent
        state: latest

    - name: "8/7 Configure Zabbix agent (set Server IP)"
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^Server=127.0.0.1'
        replace: 'Server=192.168.30.4'
      notify: restart zabbix-agent

  handlers:
    - name: restart zabbix-agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: yes

```

создаю `playbook-elasticsearch.yaml`

```
nano playbook-elasticsearch.yaml
```

```yaml
---
- name: "install elasticsearch on Ubuntu"
  hosts: elasticsearch
  become: true

  tasks:
    - name: "1/6 install Java 17 and prerequisites"
      apt:
        name:
          - gnupg
          - apt-transport-https
          - openjdk-17-jre-headless
        state: present

    - name: "2/6 download elasticsearch 7.17.9 deb package"
      shell: |
        mkdir -p /home/kirill
        wget -O /home/kirill/elasticsearch-7.17.9-amd64.deb https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/elasticsearch-7.17.9-amd64.deb
      args:
        creates: /home/kirill/elasticsearch-7.17.9-amd64.deb

    - name: "3/6 verify that file exists"
      stat:
        path: /home/kirill/elasticsearch-7.17.9-amd64.deb
      register: deb_file

    - name: "4/6 install elasticsearch from deb"
      apt:
        deb: /home/kirill/elasticsearch-7.17.9-amd64.deb
      when: deb_file.stat.exists

    - name: "5/6 copy elasticsearch.yml"
      copy:
        src: /home/kirill/elasticsearch.yml
        dest: /etc/elasticsearch/elasticsearch.yml
        owner: root
        group: elasticsearch
        mode: '0644'
      notify: restart elasticsearch

    - name: "6/6 enable and start elasticsearch"
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

создаю `playbook-kibana.yaml`

```
nano playbook-kibana.yaml
```

```yaml
---
- name: "install kibana on Ubuntu"
  hosts: kibana
  become: true

  tasks:
    - name: "1/5 install prerequisites"
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
        deb: "/home/kirill/kibana-7.17.9-amd64.deb"

    - name: "4/5 copy kibana.yml configuration"
      copy:
        src: /home/kirill/kibana.yml
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

```yaml
---
- name: "install filebeat for nginx-web-1"
  hosts: nginx-web-1
  become: true

  tasks:
    - name: "1/5 install prerequisites"
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
        deb: "/home/kirill/filebeat-7.17.9-amd64.deb"

    - name: "4/5 copy filebeat.yml configuration"
      copy:
        src: /home/kirill/filebeat.yml
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

```yaml
---
- name: "install filebeat for nginx-web-2"
  hosts: nginx-web-2
  become: true

  tasks:
    - name: "1/5 install prerequisites"
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
        deb: "/home/kirill/filebeat-7.17.9-amd64.deb"

    - name: "4/5 copy filebeat.yml configuration"
      copy:
        src: /home/kirill/filebeat.yml
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
```bash
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Дипломная работа по профессии «Системный администратор»</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        h1 { margin: 0; font-size: 28px; }
        h4 { margin: 10px 0 0; font-weight: normal; }
        main {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h3 {
            color: #2c3e50;
            border-bottom: 2px solid #2c3e50;
            padding-bottom: 10px;
        }
        ol { list-style-type: none; padding: 0; }
        li {
            margin: 15px 0;
            padding: 10px;
            background-color: #ecf0f1;
            border-radius: 5px;
            transition: 0.3s;
        }
        li:hover { background-color: #d5dbdb; }
        a {
            text-decoration: none;
            color: #2980b9;
            font-weight: bold;
            display: block;
        }
        a:hover { text-decoration: underline; }
        .description {
            font-size: 14px;
            color: #555;
            margin-top: 5px;
        }
        footer {
            text-align: center;
            margin-top: 20px;
            color: #777;
            font-size: 12px;
        }
    </style>
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
                <ol>
                    <li>
                        <a href="https://github.com/kirill-kornienko/My_Diplom/tree/main/1.%20%D0%A0%D0%B0%D0%B7%D0%B2%D0%B5%D1%80%D1%82%D1%8B%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D1%85%20%D0%BC%D0%B0%D1%88%D0%B8%D0%BD%20%D1%81%20%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C%D1%8E%20Terraform">
                            📁 1. Развертывание виртуальных машин с помощью Terraform
                        </a>
                        <div class="description">Создание инфраструктуры в Yandex Cloud: VPC, подсети, ВМ, security groups, балансировщик.</div>
                    </li>
                    <li>
                        <a href="https://github.com/kirill-kornienko/My_Diplom/tree/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2">
                            📁 2. Установка и подготовка Ansible. Установка сервисов
                        </a>
                        <div class="description">Настройка nginx, Zabbix, Elasticsearch, Kibana, Filebeat с помощью Ansible.</div>
                    </li>
                    <li>
                        <a href="https://github.com/kirill-kornienko/My_Diplom/tree/main/3.%20%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0%20%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D0%BE%D0%B2%20%D0%B8%20%D0%B2%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5%20%D0%B7%D0%B0%D0%B4%D0%B0%D1%87">
                            📁 3. Проверка ресурсов и выполнение задач
                        </a>
                        <div class="description">Финальная проверка, настройка дашбордов Zabbix, Kibana, резервное копирование.</div>
                    </li>
                </ol>
            </section>
        </article>
    </main>
    <footer>
        <p>Дипломная работа по профессии «Системный администратор» | Кирилл Корниенко | 2026</p>
    </footer>
</body>
</html>

```
создаю конфигурационные файлы:

```
nano elasticsearch.yml
```

```yaml
# ======================== Elasticsearch Configuration =========================
luster.name: kirill-diplom
node.name: node-1
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false

```

```
nano kibana.yml
```

```yaml
#============================= Kibana =========================================
server.port: 5601
server.host: 0.0.0.0
server.publicBaseUrl: "http://130.193.46.192:5601"   

elasticsearch.hosts: ["http://192.168.10.4:9200"]
```

```
nano filebeat.yml
```

```yaml
#===================== Filebeat Configuration =====================
ilebeat.inputs:
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
      fields: ["beat", "input_type", "host", "agent"]

```

```
nano filebeat2.yml
```

```yaml
#=================== Filebeat2 Configuration =======================
ilebeat.inputs:
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
      fields: ["beat", "input_type", "host", "agent"]

```

### Сайт

Устанавливаю сервер nginx на две ВМ. Заменаяю стандартный файл на `index.nginx-ubuntu.html`

![ansible_nginx](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook%20nginx.png)


### Мониторинг. Zabbix. Zabbix-agent.

Разворачива Zabbix

![zabbix](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook-zabbix1.png)
![zabbix2](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook-zabbix2.png)

На каждую ВМ устанавливаю Zabbix Agent

![zabbix-agent](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-zabbix-agent1.png)

![zabbix-agent2](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-zabbix-agent2.png)


### Логи. Elasticsearch. Kibana. Filebeat.

Разворачиваю на ВМ Elasticsearch

![elasticsearch](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook-elastic.png)

Разворачиваю на другой ВМ Kibana, конфигурирую соединение с Elasticsearch

![kibana](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook-kibana.png)

Устанавливаю Filebeat в ВМ к веб-серверам, настраиваю на отправку access.log, error.log nginx в Elasticsearch.

![filebeat](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook-filebeat.png)

![filebeat2](https://github.com/kirill-kornienko/My_Diplom/blob/main/2.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BF%D0%BE%D0%B4%D0%B3%D0%BE%D1%82%D0%BE%D0%B2%D0%BA%D0%B0%20Ansible.%20%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0%20%D0%B8%20%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D0%BE%D0%B2/ansible-playbook-filebeat2.png)

### Все сервисы через ansible развернуты.

Далее третий этап дипломной паботы [Проверка ресурсов и выполнение задач](https://github.com/kirill-kornienko/My_Diplom/tree/main/3.%20%D0%9F%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0%20%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D0%BE%D0%B2%20%D0%B8%20%D0%B2%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5%20%D0%B7%D0%B0%D0%B4%D0%B0%D1%87)





