# Configuración de Claude Code

> Una configuración de Claude Code probada en batalla con hooks personalizados, 7 agentes, 6 reglas, 25 comandos, más de 30 habilidades — diseñada para trabajar junto al plugin [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (OMC).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-2.1.79+-blue.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![OMC](https://img.shields.io/badge/OMC-4.9.0+-green.svg)](https://github.com/Yeachan-Heo/oh-my-claudecode)

Construido sobre configuraciones e ideas de:
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Colección completa de configuraciones del ganador del hackathon de Anthropic.
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — Directrices de codificación de Karpathy como habilidades de Claude Code.
- [claude-code-tips](https://github.com/ykdojo/claude-code-tips) — Consejos prácticos y el plugin `dx`.

## Arquitectura

Este repositorio proporciona **configuraciones personalizadas** que complementan el plugin OMC:

| Capa | Fuente | Qué proporciona |
|-------|--------|------------------|
| **Plugin OMC** | `oh-my-claudecode@omc` | 18 agentes base, 27 habilidades (team, autopilot, ralph, ultrawork, etc.), 11 eventos de hook, prompt de orquestación CLAUDE.md |
| **Este Repo** | `claude-code-setup` | 7 agentes personalizados, 8 hooks personalizados, 6 reglas, 25 comandos, 30+ habilidades, plantillas MCP, config de seguridad granular de OMC |

```
~/.claude/
├── settings.json              # Permisos, variables de entorno, plugins (incl. OMC)
├── agents/                    # 7 agentes personalizados + 18 de OMC (fusionados)
├── rules/                     # 6 reglas globales (cargadas en el prompt del sistema)
├── hooks/
│   └── hooks.json             # 8 hooks personalizados (2 eventos) — los hooks de OMC están separados
├── commands/                  # 25 comandos slash
├── scripts/
│   ├── hooks/ensure-coauthor.sh  # Ejecución forzada de Co-Authored-By en commits de Git
│   ├── *.sh                      # Scripts de utilidad
│   └── ci/                       # 5 scripts de validación de CI
└── skills/                    # 30+ paquetes de habilidades (fusionados con las habilidades del plugin OMC)
```

## Inicio Rápido

```bash
# 1. Clonar e instalar la configuración personalizada
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git
cd claude-code-setup
bash install.sh

# 2. Instalar el plugin OMC (en una sesión de Claude Code)
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode

# 3. Instalar OMC CLI
npm install -g oh-my-claude-sisyphus@latest
omc install
```

Usa `--dry-run` para previsualizar los cambios sin modificar nada:

```bash
bash install.sh --dry-run
```

## Qué Incluye

### Agentes Personalizados (7)

Especialistas en lenguaje/herramientas que no tienen equivalente en OMC:

| Modelo | Agente | Propósito |
|-------|-------|---------|
| **Sonnet** | `e2e-runner` | Generación y ejecución de pruebas E2E de Playwright |
| **Sonnet** | `refactor-cleaner` | Detección de código muerto (knip, depcheck, ts-prune) |
| **Sonnet** | `python-reviewer` | Verificaciones de PEP 8, type hints, ruff/mypy/bandit |
| **Haiku** | `database-reviewer` | Optimización de PostgreSQL, revisión de esquemas, RLS |
| **Haiku** | `doc-updater` | Generación de documentación y codemaps |
| **Haiku** | `go-reviewer` | Revisión de Go idiomático, concurrencia y manejo de errores |
| **Haiku** | `go-build-resolver` | Resolución de errores de construcción/vet de Go |

> OMC proporciona 18 agentes base (arquitecto, planificador, ejecutor, revisor de código, etc.) a través del plugin.

### Hooks Personalizados (8 hooks, 2 eventos)

Estos son hooks de flujo de trabajo personalizados que complementan los hooks de orquestación de OMC:

| Evento | Hook | Función |
|-------|------|----------|
| **PreToolUse** | dev server block | Bloquea `npm run dev` etc. fuera de tmux (exit 1) |
| **PreToolUse** | tmux reminder | Advierte cuando comandos de larga duración se ejecutan fuera de tmux |
| **PreToolUse** | ensure-coauthor | Bloquea git commit sin el trailer `Co-Authored-By` (exit 2) |
| **PreToolUse** | git push review | Recordatorio antes de hacer git push |
| **PreToolUse** | md file block | Bloquea la creación de archivos .md/.txt aleatorios |
| **PostToolUse** | PR URL logger | Registra la URL del PR después de `gh pr create` |
| **PostToolUse** | Prettier format | Auto-formatea archivos JS/TS después de ediciones (async) |
| **PostToolUse** | TypeScript check | Ejecuta `tsc --noEmit` después de ediciones de TS (async) |

> OMC proporciona hooks de orquestación (detección de palabras clave, seguridad de contexto, gestión de sesiones, etc.) a través del plugin; no hay solapamiento con estos hooks personalizados.

### Reglas (6)

| Regla | Enfoque |
|------|-------|
| `coding-style.md` | Inmutabilidad, organización de archivos (<800 líneas), manejo de errores |
| `engineering.md` | Pensar antes de codificar, simplicidad primero, cambios quirúrgicos, política de pruebas escalonadas |
| `git-workflow.md` | Commits convencionales, flujo de trabajo de PR, implementación de funcionalidades |
| `mcp-priority.md` | Preferencia de stack local SearXNG + Crawl4AI sobre APIs en la nube |
| `orchestration.md` | Política de delegación de 3 carriles: bucle principal, subagentes de Claude, ejecutor Codex |
| `security.md` | Gestión de secretos, validación de entradas, checklist de OWASP |

### Comandos (25)

| Comando | Descripción |
|---------|-------------|
| `/plan` | Análisis de requerimientos y plan de implementación |
| `/tdd` | Ejecución de TDD (RED, GREEN, REFACTOR) |
| `/code-review` | Revisión de código con agente |
| `/build-fix` | Corregir errores de construcción |
| `/test-coverage` | Análisis de cobertura |
| `/e2e` | Generación de pruebas E2E (Playwright) |
| `/refactor-clean` | Limpieza de código muerto |
| `/checkpoint` | Guardar punto de control |
| `/verify` | Ejecutar verificación |
| `/orchestrate` | Orquestación multi-agente |
| `/sessions` | Gestión de sesiones |
| `/learn` | Extraer patrones |
| `/skill-create` | Crear habilidad a partir de patrones |
| `/evolve` | Evolucionar instintos en habilidades |
| `/python-review` | Revisión de código Python |
| `/go-review` / `/go-build` / `/go-test` | Flujos de trabajo de Go |
| `/update-codemaps` / `/update-docs` | Documentación |
| `/eval` | Evaluación de sesión |
| `/setup-pm` | Detección del gestor de paquetes |
| `/instinct-*` | Gestión de instintos (estado, exportar, importar) |

### Habilidades (30+)

**Web**: `frontend-patterns`, `backend-patterns`, `coding-standards`

**Python**: `python-patterns`, `python-testing`, `django-patterns`, `django-security`, `django-tdd`, `django-verification`

**Go**: `golang-patterns`, `golang-testing`

**Java/Spring**: `springboot-patterns`, `springboot-security`, `springboot-tdd`, `jpa-patterns`, `java-coding-standards`

**Base de Datos**: `postgres-patterns`, `clickhouse-io`

**Seguridad**: `security-review` (incluye seguridad de infraestructura en la nube)

**Flujo de Trabajo**: `tdd-workflow`, `verification-loop`, `eval-harness`, `iterative-retrieval`, `strategic-compact`

**Aprendizaje**: `continuous-learning-v2` (sistema basado en instintos con agente observador y CLI)

## Servidores MCP

### Globales (16 servidores, configurados en `~/.claude.json`)

| Servidor | Tipo | Descripción |
|--------|------|-------------|
| `github` | HTTP | GitHub Copilot MCP (PRs, issues, repos) |
| `firecrawl` | stdio | Web scraping — solo `firecrawl_agent` (limitado a 500 créditos) |
| `supabase` | HTTP | Base de datos Supabase, auth, storage |
| `vercel` | HTTP | Despliegue en Vercel |
| `railway` | stdio | Despliegue en Railway |
| `cloudflare-*` | HTTP | Docs, builds de Workers, bindings, observabilidad |
| `clickhouse` | HTTP | Analítica de ClickHouse |
| `magic` | stdio | Componentes de Magic UI |
| `filesystem` | stdio | Operaciones de sistema de archivos |
| `sequential-thinking` | stdio | Cadenas de razonamiento estructurado |
| `context7` | stdio | Búsqueda de documentación en vivo |
| `c4ai-sse` | SSE | Crawl4AI vía Docker (localhost:11235) — herramienta principal de scraping |
| `playwright` | stdio | Automatización de navegador con Playwright |

### Prioridad de MCP: Stack Local Primero

La regla `mcp-priority.md` impone un flujo de trabajo local de **SearXNG + Crawl4AI** sobre las APIs en la nube:

```
Búsqueda  ->  SearXNG (curl localhost:8888)     gratis, ilimitado, local
Scraping  ->  Crawl4AI (c4ai-sse MCP)           gratis, ilimitado, local
Respaldo  ->  WebSearch (integrado) / Firecrawl  limitado por tasa, tiene costo
```

Usa `config/claude.json.template` como punto de partida para tu `~/.claude.json`.

## Configuración de Seguridad de OMC

`config/claude-omc.config.jsonc` se instala en `~/.config/claude-omc/config.jsonc` y aplica un endurecimiento granular de OMC (fijación de auto-actualizaciones, límites de iteración, rutas de herramientas restringidas) sin el modo general `OMC_SECURITY=strict`, que desactiva las habilidades del proyecto y los servidores MCP remotos.

## Permisos

El archivo `settings.json` incluye un modelo de permisos cuidadosamente ajustado:

- **Permitir**: Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, y herramientas CLI comunes (git, npm, python, etc.)
- **Denegar**: `rm -rf /`, `rm -rf ~`, `sudo`, lectura de archivos `.env` (12 variantes)
- **Preguntar**: `git push`, comandos `docker`
- **Modo Predeterminado**: `acceptEdits`

## Plugins

| Plugin | Fuente | Propósito |
|--------|--------|---------|
| `oh-my-claudecode@omc` | [GitHub](https://github.com/Yeachan-Heo/oh-my-claudecode) | Orquestación multi-agente (team, autopilot, ralph, ultrawork) |
| `dx@ykdojo` | [GitHub](https://github.com/ykdojo/claude-code-tips) | Experiencia de desarrollador (clone, half-clone, handoff, gha) |
| `clangd-lsp` | claude-plugins-official | Servidor de lenguaje C/C++ |

## Personalización

- **Añadir agentes**: Crea archivos `.md` en `agents/` con frontmatter (nombre, descripción, herramientas, modelo).
- **Añadir reglas**: Crea archivos `.md` en `rules/` — se cargan en el prompt del sistema de cada sesión.
- **Añadir comandos**: Crea archivos `.md` en `commands/` — accesibles vía `/nombre-del-comando`.
- **Añadir hooks**: Edita `hooks/hooks.json` — los hooks personalizados se ejecutan junto a los hooks del plugin OMC.
- **Añadir habilidades**: Crea directorios en `skills/` con un archivo `SKILL.md`.

## Licencia

MIT
