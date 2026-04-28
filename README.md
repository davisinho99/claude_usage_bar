# Claude Usage Bar

Muestra el consumo de tu sesión de Claude en la barra de título del terminal, en tiempo real.

## Qué es

Un plugin para [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que añade una barra visual del context window en la barra de título de tu terminal. Así sabes en todo momento cuánto contexto te queda sin tener que llamar a `/usage` manualmente.

```
████████░░░░░░░░░░░░░  63% · 52k / 200k tokens
```

- 20 bloques: `█` consumido, `░` restante
- Muestra porcentaje y tokens consumidos
- Se actualiza automáticamente con cada llamada a una tool

## Requisitos

- **Claude Code** >= 1.0
- **macOS o Linux** (usa `printf "\e]"` para escape de terminal)
- API key de Anthropic configurada (el plugin necesita `/usage`)

## Instalación

### Opción 1 — GitHub Marketplace

```bash
# Añadir desde tu repositorio (sustituye por tu usuario/repo)
claude plugins marketplace add github:davisinho99/claude_usage_bar

# Instalar
claude plugins install usage-bar
```

### Opción 2 — Instalación local

```bash
# Clonar el repositorio
git clone https://github.com/davisinho99/claude_usage_bar.git
cd claude-usage-bar

# Instalar desde ruta local
claude plugins marketplace add ./plugin/claude-code --scope user
claude plugins install usage-bar
```

### Opción 3 — Copia manual

```bash
# Copiar la carpeta del plugin
cp -r plugin/claude-code ~/.claude/plugins/usage-bar/

# Habilitar en settings
claude plugins enable usage-bar
```

## Cómo funciona

El plugin usa **3 hooks** de Claude Code:

| Hook | Qué hace |
|------|----------|
| `SessionStart` | Lanza un proceso en segundo plano que hace polling de `/usage` cada 3 segundos |
| `PreToolUse` | Lee el último dato cacheado y actualiza la barra en la barra de título |
| `Stop` | Limpia el proceso en segundo plano y los archivos temporales |

El polling no ocurre en cada tool call (sería lento). El monitor escribe en `/tmp/claude-usage.json` y `PreToolUse` solo lee ese JSON ya cacheado. Así no añade latencia.

## Desinstalación

```bash
claude plugins uninstall usage-bar
```

## FAQ

**¿Puedo cambiar el intervalo de polling?**

Sí, edita `scripts/session-start.sh` y cambia el valor de `INTERVAL` (actualmente 3 segundos):

```bash
INTERVAL=5  # segundos entre actualizaciones
```

**¿Puedo cambiar el formato de la barra?**

Edita la función `draw_bar()` en `scripts/pre-tool-use.sh`. Los bloques actuales:

```bash
FILLED="█"    # tokens consumidos
EMPTY="░"     # tokens restantes
TOTAL=20      # número de bloques
```

**¿No ves la barra?**

- Comprueba que tu terminal muestra el título:
  ```bash
  echo -e "\e]2:test\a"
  ```
  Debería cambiar el título de la ventana.
- Si usas **tmux**: funciona por defecto en sesiones nuevas. En sesiones existentes puede que necesites:
  ```bash
  set -g set-titles on
  ```
- Si usas **screen**: añade `hardstatus string` o `caption string` a tu `.screenrc`.
- Verifica que el plugin está activo:
  ```bash
  claude plugins list
  ```

**El plugin no funciona en sesiones SSH o root**

El comando `/usage` de Claude Code tiene restricciones de seguridad y no funciona en sesiones con privilegios elevados. Esto es una limitación de Claude Code, no del plugin.

## Estructura del plugin

```
.
├── plugin/
│   └── claude-code/          # Carpeta que va a ~/.claude/plugins/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Metadatos del plugin
│       ├── hooks/
│       │   ├── hooks.json   # Definición de hooks
│       │   └── stop.sh      # Cleanup hook
│       └── scripts/
│           ├── session-start.sh   # Monitor en segundo plano
│           ├── pre-tool-use.sh    # Actualiza barra de título
│           └── stop.sh           # Cleanup del monitor
└── README.md
```

## Licencia

MIT