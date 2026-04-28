# Claude Usage Bar

Muestra el consumo de tu sesión de Claude en la **statusLine** de Claude Code, en tiempo real.

## Qué es

Un plugin para [Claude Code](https://docs.anthropic.com/en/docs/claude-code) que añade una barra visual del context window en la barra de estado integrada de Claude Code. Funciona como el plugin [caveman](https://github.com/juliusbrussee/caveman).

```
[████████████░░░░░░░░░] 63% In:52k CR:12k CW:6k
```

- 20 bloques: `█` consumido, `░` restante
- Muestra porcentaje, tokens de entrada, cache read y cache write
- Se actualiza cada 5 segundos automáticamente
- Colores: verde <60%, amarillo 60-84%, rojo ≥85%

## Requisitos

- **Claude Code** >= 1.0
- **macOS o Linux**
- **python3** (para parsear JSON, fallback a grep)
- API key de Anthropic configurada (el plugin necesita `/usage`)

## Instalación

### Opción 1 — GitHub Marketplace

```bash
# Añadir desde tu repositorio
claude plugins marketplace add github:davisinho99/claude_usage_bar

# Instalar
claude plugins install usage-bar
```

### Opción 2 — Instalación local

```bash
# Clonar el repositorio
git clone https://github.com/davisinho99/claude_usage_bar.git
cd claude_usage_bar

# Añadir marketplace desde la raíz del repo
claude plugins marketplace add ./ --scope user

# Instalar plugin
claude plugins install usage-bar
```

## Activar la barra

Después de instalar, ejecuta el script de activación:

```bash
bash ~/.claude/plugins/usage-bar/0.1.0/scripts/install.sh
```

O manual, añade esto a `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/usage-bar/0.1.0/scripts/statusline.sh"
  }
}
```

Reinicia Claude Code para ver la barra.

## Desinstalación

```bash
# Desinstalar plugin
claude plugins uninstall usage-bar

# Quitar la barra de statusLine — edita ~/.claude/settings.json
# y elimina la entrada "statusLine"
```

## Cómo funciona

El plugin usa **2 hooks** de Claude Code:

| Hook | Qué hace |
|------|----------|
| `SessionStart` | Lanza un proceso en segundo plano que hace polling de `/usage` cada 5 segundos y escribe en `/tmp/claude-usage.json` |
| `Stop` | Limpia el proceso en segundo plano y los archivos temporales |

La **statusLine** es una feature built-in de Claude Code que ejecuta `statusline.sh` continuamente y muestra su salida en la barra de estado. El script lee del JSON cacheado — no añade latencia.

## FAQ

**¿Puedo cambiar el intervalo de polling?**

Sí, edita `scripts/session-start.sh` y cambia:

```bash
POLL_INTERVAL=5  # segundos entre actualizaciones
```

**¿Puedo cambiar el formato de la barra?**

Edita los valores en `scripts/statusline.sh`:

```bash
BAR_LEN=20        # número de bloques
COLOR="\\033[1;32m"   # verde (<60%)
COLOR="\\033[1;33m"   # amarillo (60-84%)
COLOR="\\033[1;31m"   # rojo (≥85%)
```

**La barra no aparece**

1. Verifica que el plugin está activo:
   ```bash
   claude plugins list
   ```
2. Comprueba que `statusLine` está en `~/.claude/settings.json`
3. Comprueba que `python3` está instalado
4. Reinicia Claude Code

**El plugin no funciona en sesiones SSH o root**

El comando `/usage` de Claude Code tiene restricciones de seguridad y no funciona en sesiones con privilegios elevados. Esto es una limitación de Claude Code, no del plugin.

## Estructura del plugin

```
.
├── .claude-plugin/
│   └── marketplace.json    # Marketplace config
├── plugin/claude-code/
│   ├── .claude-plugin/
│   │   └── plugin.json   # Plugin metadata
│   ├── hooks/
│   │   ├── hooks.json   # Hook definitions (SessionStart, Stop)
│   │   └── stop.sh      # Cleanup hook
│   └── scripts/
│       ├── session-start.sh  # Background monitor
│       ├── statusline.sh    # StatusLine output (se ejecuta contínuamente)
│       ├── stop.sh          # Monitor cleanup
│       └── install.sh       # Activa statusLine en settings.json
└── README.md
```

## Créditos

Inspirado en [caveman](https://github.com/juliusbrussee/caveman) de Julius Brussee — que me enseñó cómo usar `statusLine`.

## Licencia

MIT
