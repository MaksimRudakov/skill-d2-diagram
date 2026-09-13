# Neutral wording (EN / RU)

For diagrams shared outside the team: name the role, not the product, the vendor or the address.
Use the column that matches the diagram language (see "Output language" in SKILL.md).

## Infrastructure

| Instead of (internal) | English | Русский |
|---|---|---|
| vendor firewall model, HA pair | Firewall cluster (HA) | Межсетевой экран (HA) |
| core switch model | Network core | Сетевое ядро |
| border router model / ISP names | Border routers | Пограничные маршрутизаторы |
| internet uplinks with ISP names | Internet uplinks (2 providers) | Каналы в интернет (2 провайдера) |
| hardware load balancer model | Load balancer | Балансировщик нагрузки |
| ingress controller product | Ingress | Ingress |
| WAF product | Web application firewall | WAF |
| hypervisor product and host names | Virtualization cluster | Кластер виртуализации |
| storage array model | Storage system | Система хранения данных |
| backup product / server names | Backup storage | Хранилище резервных копий |
| S3 endpoint / bucket names | Object storage (S3-compatible) | Объектное хранилище (S3-совместимое) |
| cluster / kubeconfig context name | Kubernetes cluster (production) | Kubernetes-кластер (prod) |
| managed service of a named cloud | Managed Kubernetes / Managed PostgreSQL | Управляемый Kubernetes / PostgreSQL |
| VPN appliance / tunnel peer IPs | VPN gateway, site-to-site tunnel | VPN-шлюз, туннель site-to-site |
| jump host name | Bastion host | Бастион (jump host) |
| SSO product / realm name | Identity provider (SSO) | Провайдер учётных записей (SSO) |
| monitoring product stack | Monitoring (metrics, logs, alerts) | Мониторинг (метрики, логи, алерты) |
| VLAN 110 / 10.10.0.0/16 | Production segment | Сегмент prod |
| VLAN 120 | Development segment | Сегмент dev |
| VLAN 900 | Management segment | Сегмент управления |
| DMZ subnet | DMZ | DMZ |

## Processes and state machines

| Purpose | English | Русский |
|---|---|---|
| start / end | `Start` · `End` | `Начало` · `Конец` |
| decision edges | `yes` · `no` | `да` · `нет` |
| typical steps | `Submit request` · `Approve` · `Reject with a reason` · `Notify` | `Отправить заявку` · `Согласовать` · `Отклонить с причиной` · `Уведомить` |
| roles (swimlanes) | `Requester` · `Owner` · `On-call engineer` | `Заявитель` · `Владелец` · `Дежурный инженер` |
| states | `Open` · `In progress` · `Blocked` · `In review` · `Done` · `Cancelled` | `Открыта` · `В работе` · `Заблокирована` · `На проверке` · `Готово` · `Отменена` |
| sequence groups | `alt: …` · `loop: every 5 min` · `optional` | `вариант: …` · `цикл: каждые 5 минут` · `опционально` |

## Labels, banners, legends

| Purpose | English | Русский |
|---|---|---|
| internal banner (header comment) | `# Internal: do not share outside the team` | `# Только для команды, наружу не передавать` |
| confidential banner | `Confidential` | `Конфиденциально` |
| legend prefix | `Legend:` | `Легенда:` |
| legend flows | `blue — metrics · orange — logs · red — alerts` | `синий — метрики · оранжевый — логи · красный — алерты` |
| state | `planned` · `to be decommissioned` · `external` | `планируется` · `выводится` · `внешняя система` |
| perimeter | `Perimeter` · `Data center` · `Cloud` | `Контур` · `ЦОД` · `Облако` |
| header comment | `# Purpose: …` / `# Render: d2 --layout elk X.d2 X.svg` | `# Назначение: …` / `# Рендер: d2 --layout elk X.d2 X.svg` |
