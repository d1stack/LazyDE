# lazyde-web

Full-stack web development image — PHP, Node, TypeScript, Vue, HTML, CSS — layered on top of `lazyde-base`.

## What's included

Same set of tools across every variant:

- **PHP** with `mbstring`, `xml`, `curl`, `zip`, `mysql`, `pgsql`, `sqlite3`, `intl`, `bcmath`, `gd`, `opcache`
- **Composer 2.8** for PHP dependency management
- **Node** + **npm** from the official Docker image
- **TypeScript** (`tsc`) globally installed
- **Vue language server** + **TypeScript plugin** for Vue 3 projects
- **vscode-langservers-extracted** providing HTML, CSS, JSON, and ESLint LSPs
- **Treesitter parsers**: `php`, `phpdoc`, `html`, `css`, `scss`, `javascript`, `typescript`, `tsx`, `vue`, `json`, `jsonc`, `yaml`
- **Mason tools**: `phpactor`, `php-cs-fixer`, `phpcs`, `vtsls`, `prettier`, `eslint-lsp`, `json-lsp`

## Available variants

Each variant has its own Dockerfile. Pick the one that matches your project:

| Dockerfile                      | PHP | Node     | Notes                          |
| ------------------------------- | --- | -------- | ------------------------------ |
| `php8.3-node22.dockerfile`      | 8.3 | 22 (LTS) | **Recommended default**        |
| `php8.3-node20.dockerfile`      | 8.3 | 20 (LTS) | Older Node LTS                 |
| `php8.3-node24.dockerfile`      | 8.3 | 24       | Active release (LTS Oct 2026)  |
| `php8.2-node20.dockerfile`      | 8.2 | 20 (LTS) | Legacy Laravel/Symfony         |
| `php8.2-node22.dockerfile`      | 8.2 | 22 (LTS) |                                |
| `php8.4-node22.dockerfile`      | 8.4 | 22 (LTS) | Latest stable PHP              |
| `php8.4-node24.dockerfile`      | 8.4 | 24       | Cutting edge                   |

Need a combination not listed? Copy any of the existing Dockerfiles and search-and-replace the version strings — there are only two, both in self-explanatory places.

## Quick start

Make sure `lazyde-base:stable` is built first:

```bash
podman build -t lazyde-base:stable ../..
```

Then build the variant you want, using `-f` to point at the right Dockerfile:

```bash
podman build -f php8.3-node22.dockerfile -t lazyde-web:php8.3-node22 .
```

For Docker, swap `podman` for `docker` — same flags.

### Building all variants

A simple Makefile is included:

```bash
make list              # see what's available
make php8.3-node22     # build a single variant
make all               # build all seven variants
```

The Makefile uses `podman` by default. Override with `make php8.3-node22 CONTAINER_TOOL=docker` if needed.

## Running

```bash
podman run --rm -it -v "$PWD:/mnt/volume" lazyde-web:php8.3-node22
```

Convenient alias for daily use:

```bash
alias web-nvim='podman run --rm -it -v "$PWD:/mnt/volume" lazyde-web:php8.3-node22'
```

## Verifying a built image

```bash
podman run --rm lazyde-web:php8.3-node22 php --version
podman run --rm lazyde-web:php8.3-node22 node --version
podman run --rm lazyde-web:php8.3-node22 composer --version
podman run --rm lazyde-web:php8.3-node22 tsc --version
```

## Notes on version choices

- **Node 22 is the current LTS** (codename Jod, supported until April 2027) and the recommended default for production work.
- **PHP 8.3** offers the best balance between modern language features and library compatibility right now. PHP 8.4 is also production-ready but has a smaller library ecosystem behind it.
- **PHP versions come from [packages.sury.org](https://deb.sury.org/)**, the de facto standard repo for current PHP releases on Debian/Ubuntu. This is why multiple PHP versions are available across the variants.
