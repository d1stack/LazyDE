# lazyde-web

Full-stack web development image variants layered on top of `lazyde-base`.

## What's included

### PHP variants

- **PHP** with `mbstring`, `xml`, `curl`, `zip`, `mysql`, `pgsql`, `sqlite3`, `intl`, `bcmath`, `gd`, `opcache`
- **Composer 2.8**
- **Node** + **npm**
- **TypeScript** (`tsc`)
- **Vue language server** + **TypeScript plugin**
- **vscode-langservers-extracted** (HTML, CSS, JSON, ESLint LSPs)
- **Treesitter parsers**: `php`, `phpdoc`, `html`, `css`, `scss`, `javascript`, `typescript`, `tsx`, `vue`, `json`, `jsonc`, `yaml`
- **Mason tools**: `phpactor`, `php-cs-fixer`, `phpcs`, `vtsls`, `prettier`, `eslint-lsp`, `json-lsp`

### Python variants

- **Python** (`3.11`, `3.12`, `3.13`) from official python images
- **uv** package/project manager
- **Ruff** (lint/format)
- **Pyright** (type checking)
- **Django**, **Flask**, **FastAPI** CLIs preinstalled
- **Node** + **npm**
- **TypeScript** (`tsc`)
- **Vue language server** + **TypeScript plugin**
- **vscode-langservers-extracted** (HTML, CSS, JSON, ESLint LSPs)
- **Treesitter parsers**: `python`, `toml`, `yaml`, `html`, `css`, `scss`, `javascript`, `typescript`, `tsx`, `vue`, `json`, `jsonc`
- **Mason tools**: `pyright`, `ruff`, `vtsls`, `prettier`, `eslint-lsp`, `json-lsp`

Note: Ruff is not a full replacement for Pyright. These images include both.

## Available variants

### PHP + Node

| Dockerfile                 | PHP | Node     | Notes                         |
| -------------------------- | --- | -------- | ----------------------------- |
| `php8.3-node22.dockerfile` | 8.3 | 22 (LTS) | **Recommended PHP default**   |
| `php8.3-node20.dockerfile` | 8.3 | 20 (LTS) | Older Node LTS                |
| `php8.3-node24.dockerfile` | 8.3 | 24       | Active release (LTS Oct 2026) |
| `php8.2-node20.dockerfile` | 8.2 | 20 (LTS) | Legacy Laravel/Symfony        |
| `php8.2-node22.dockerfile` | 8.2 | 22 (LTS) |                               |
| `php8.4-node22.dockerfile` | 8.4 | 22 (LTS) | Latest stable PHP             |
| `php8.4-node24.dockerfile` | 8.4 | 24       | Cutting edge                  |

### Python + Node

| Dockerfile                    | Python | Node     | Notes                           |
| ----------------------------- | ------ | -------- | ------------------------------- |
| `python3.12-node22.dockerfile`| 3.12   | 22 (LTS) | **Recommended Python default**  |
| `python3.11-node22.dockerfile`| 3.11   | 22 (LTS) | Broad compatibility             |
| `python3.13-node22.dockerfile`| 3.13   | 22 (LTS) | Newest stable Python            |
| `python3.11-node24.dockerfile`| 3.11   | 24       | Newer Node toolchain            |
| `python3.12-node24.dockerfile`| 3.12   | 24       |                                 |
| `python3.13-node24.dockerfile`| 3.13   | 24       | Most current Python + Node pair |

Need a combination not listed? Copy an existing Dockerfile and replace version strings.

## Quick start

Make sure `lazyde-base:stable` is built first:

```bash
docker build -t lazyde-base:stable .
```

Build one PHP variant:

```bash
docker build -f web/php8.3-node22.dockerfile -t lazyde-web:php8.3-node22 .
```

Build one Python variant:

```bash
docker build -f web/python3.12-node22.dockerfile -t lazyde-web:python3.12-node22 .
```

Optional custom config from the repo root:

```bash
cp -r ~/.config/nvim .config/nvim
docker build -f web/php8.3-node22.dockerfile -t lazyde-web:php8.3-node22 .
docker build -f web/python3.12-node22.dockerfile -t lazyde-web:python3.12-node22 .
```

## Running

PHP default:
```bash
docker run --rm -it -v "$PWD:/mnt/volume" lazyde-web:php8.3-node22
```

Python default:
```bash
docker run --rm -it -v "$PWD:/mnt/volume" lazyde-web:python3.12-node22
```

Convenient aliases:

```bash
alias web-nvim-py='docker run --rm -it -v "$PWD:/mnt/volume" lazyde-web:python3.12-node22'
alias web-nvim-php='docker run --rm -it -v "$PWD:/mnt/volume" lazyde-web:php8.3-node22'
```

If `.config/nvim/init.lua` or `.config/nvim/lua/` exists, the build replaces the baked-in starter config with your own. If `.config/nvim/lazy-lock.json` exists, the build restores those exact plugin revisions. If `.config/nvim` is missing or only contains the placeholder, the stock config stays in place.

## Verifying a Python variant

```bash
docker run --rm lazyde-web:python3.12-node22 python3 --version
docker run --rm lazyde-web:python3.12-node22 uv --version
docker run --rm lazyde-web:python3.12-node22 ruff --version
docker run --rm lazyde-web:python3.12-node22 pyright --version
docker run --rm lazyde-web:python3.12-node22 django-admin --version
docker run --rm lazyde-web:python3.12-node22 flask --version
docker run --rm lazyde-web:python3.12-node22 node --version
```
