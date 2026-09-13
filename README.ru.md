# skill-d2-diagram

[English](README.md) · **Русский**

Скилл для [Claude Code](https://docs.claude.com/en/docs/claude-code), который превращает описание в схему на [D2](https://d2lang.com):
архитектура и инфраструктура, блок-схемы процессов, sequence-диаграммы, ER-схемы, UML-классы, конечные автоматы, оргструктуры —
в едином стиле, с визуальной самопроверкой, а для реальных систем — по фактам и с проверками перед передачей наружу.

<p align="center">
  <img src="examples/network.svg" alt="Сегментация сети" width="24%">
  <img src="examples/deployment.svg" alt="Развёртывание" width="24%">
  <img src="examples/monitoring.svg" alt="Мониторинг" width="24%">
  <img src="examples/backup-ru.svg" alt="Резервное копирование" width="24%">
</p>
<p align="center">
  <img src="examples/access-request.svg" alt="Блок-схема процесса" width="24%">
  <img src="examples/sso-login.svg" alt="Sequence-диаграмма" width="24%">
  <img src="examples/orders-schema.svg" alt="ER-схема" width="24%">
  <img src="examples/ticket-lifecycle.svg" alt="Конечный автомат" width="24%">
</p>

```
› нарисуй сегментацию сети для аудиторов
› нарисуй sequence входа через SSO с MFA
› вот миграция, нарисуй ER-схему
› нарисуй схему процесса согласования отпуска
› draw the backup scheme of the prod cluster
```

## Зачем

Схемы, нарисованные агентом, часто выдуманы, разнородны, нечитаемы и раскрывают лишнее. Скилл заставляет агента:

- **выбирать правильный тип схемы** — блок-схема, sequence, ER, UML-классы, конечный автомат, иерархия или архитектура, с проверенными сниппетами D2 для каждого;
- **рисовать только проверенное** (для реальных систем) — `kubectl`, IaC и конфиг-репозитории, актуальная документация; противоречия озвучиваются, а не сглаживаются;
- **использовать одну палитру** — зоны, узлы, фигуры процессов и состояний, 8 типов потоков, которые не путаются между собой;
- **смотреть на результат** — рендер SVG + PNG с ELK, просмотр PNG, исправление нечитаемых раскладок и «простыней» 5:1;
- **не раскрывать внутреннее** — отдельные внешняя и внутренняя версии плюс сканер IP, MAC, email, хостов и вашего deny-списка;
- **ловить молчаливые ошибки D2** — неизвестные классы, подписи и члены классов, обрезанные на `#`, нечитаемые таблицы, `d2 validate`, пропускающий сломанные файлы.

## Что внутри

| Путь | Назначение |
|---|---|
| [`SKILL.md`](SKILL.md) | процесс, которому следует агент |
| [`references/diagram-types.md`](references/diagram-types.md) | какой тип схемы выбрать, проверенные сниппеты для каждого |
| [`references/style.md`](references/style.md) | палитра (блок `classes` для копирования) |
| [`references/patterns.md`](references/patterns.md) | приёмы раскладки и проверенные грабли D2 |
| [`references/terms.md`](references/terms.md) | нейтральные формулировки для внешних схем на английском и русском |
| [`scripts/anonymity-check.sh`](scripts/anonymity-check.sh) | ищет данные, которые нельзя передавать наружу |
| [`scripts/class-check.sh`](scripts/class-check.sh) | ищет используемые, но не объявленные классы (d2 их молча игнорирует) |
| [`examples/`](examples) | примеры схем каждого типа с отрендеренными SVG |
| [`tests/test.sh`](tests/test.sh) | тесты скриптов, документации, примеров и каждой описанной грабли |

## Требования

| | Версия | Проверка |
|---|---|---|
| Claude Code | любая актуальная | `claude --version` |
| d2 | **≥ 0.7.1**, протестировано на **0.9.0** (ELK встроен) | `d2 --version` |
| bash | 3.2+ (macOS, Linux, WSL, Git Bash) — только для скриптов | `bash --version` |

## Установка

### 1. Скилл

Личный скилл (для всех проектов):

```bash
git clone https://github.com/MaksimRudakov/skill-d2-diagram.git ~/.claude/skills/d2-diagram
```

Скилл проекта (вместе с репозиторием):

```bash
git clone https://github.com/MaksimRudakov/skill-d2-diagram.git .claude/skills/d2-diagram
```

Храните клоны в другом месте — клонируйте куда удобно и сделайте симлинк: `ln -s "$PWD/skill-d2-diagram" ~/.claude/skills/d2-diagram`.

Windows (PowerShell): `git clone https://github.com/MaksimRudakov/skill-d2-diagram.git "$env:USERPROFILE\.claude\skills\d2-diagram"`.

Репозиторий называется `skill-d2-diagram`, а сам скилл — `d2-diagram`: клонируйте в папку `d2-diagram`, как выше.
Обновление — `git pull`; изменения подхватываются в новой сессии Claude Code.

### 2. d2

| ОС | Команда |
|---|---|
| macOS | `brew install d2` |
| macOS / Linux, с фиксацией версии | `curl -fsSL https://d2lang.com/install.sh \| sh -s -- --version v0.9.0` (сначала с `--dry-run`, чтобы увидеть, что сделает скрипт) |
| Windows | `d2-v0.9.0-windows-amd64.msi` со страницы [релизов](https://github.com/d2lang/d2/releases/tag/v0.9.0) |
| Любая, есть Go | `go install oss.terrastruct.com/d2@v0.9.0` |

### 3. Проверка

```bash
d2 --version
cd ~/.claude/skills/d2-diagram
bash scripts/anonymity-check.sh examples/network.d2            # anonymity-check.sh: clean
bash scripts/anonymity-check.sh examples/network-internal.d2   # 10 находок — так задумано
```

Затем в Claude Code: `нарисуй схему трёхзвенного веб-приложения` или `нарисуй блок-схему процесса релиза`.

## Язык

Инструкции скилла на английском, язык схем выбирается так:

1. настройка в `CLAUDE.md` проекта или пользователя главнее всего — строка `d2-diagram: language: ru`;
2. иначе язык вашего запроса (пишете по-русски — подписи и легенда на русском);
3. иначе английский.

Нейтральные термины и легенды на обоих языках — в [`references/terms.md`](references/terms.md).
Шрифт d2 по умолчанию отображает кириллицу, см. [`examples/backup-ru.d2`](examples/backup-ru.d2).

## Проверки

### class-check.sh

```bash
bash scripts/class-check.sh diagram.d2
# diagram.d2:12: unknown class 'toool'
```

D2 рендерит схему с опечаткой в имени класса без ошибки — просто без стиля.

### anonymity-check.sh

```bash
bash scripts/anonymity-check.sh [--deny FILE] [--allow FILE] [--skip-comments] diagram.d2
# diagram.d2:7: ipv4: 10.20.0.1/24
# diagram.d2:9: hostname: db01.corp.internal
# diagram.d2:12: deny: FortiGate
```

| Находит | Примечания |
|---|---|
| `ipv4` | адреса и CIDR с проверкой октетов; `v1.2.3.4` и `1.2.3.4.5` — не IP |
| `ipv6` | полные и сокращённые через `::` |
| `mac` | `aa:bb:…`, `aa-bb-…`, `aabb.ccdd.eeff` |
| `email` | |
| `hostname` | FQDN с реальным или внутренним TLD (`.com`, `.kz`, `.internal`, `.local`, `.svc`, …); имена файлов вроде `values.yaml` и пути D2 вроде `infra.db` не срабатывают |
| `deny` | ваши регулярные выражения: вендоры, внутренние домены, имена кластеров |

Паттерны проекта положите в `.d2-anonymity-deny`, согласованные исключения — в `.d2-anonymity-allow`
(по одному ERE на строку) рядом со схемами — они подхватываются автоматически.
Коды выхода: `0` чисто, `1` есть находки, `2` ошибка вызова.

Это эвристическая страховка, а не DLP-система: агент всё равно просматривает схему, и вам стоит тоже.

## Разработка

```bash
bash tests/test.sh              # ~120 проверок; проверки d2 пропускаются, если d2 не установлен
REQUIRE_D2=1 bash tests/test.sh # как в CI
shellcheck scripts/*.sh tests/*.sh
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) гоняет тесты на Ubuntu и на macOS с системным
`/bin/bash` 3.2 и BSD-утилитами, на закреплённой и проверенной по контрольной сумме версии d2, плюс shellcheck и gitleaks.
У каждой грабли из `references/patterns.md` есть тест: если релиз d2 изменит поведение, CI упадёт,
а не оставит устаревший совет. Заметки для контрибьюторов: [`CLAUDE.md`](CLAUDE.md).

## Лицензия

[MIT No Attribution (MIT-0)](LICENSE) — копируйте, изменяйте, распространяйте и используйте коммерчески без указания авторства.
