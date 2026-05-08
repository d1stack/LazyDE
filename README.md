<p align="center">
  <img src="banner.svg" alt="LazyDE — a containerised LazyVim distribution" width="680">
</p>

# LazyDE

> A lean, layered container distribution of [LazyVim](https://www.lazyvim.org/) — Neovim as a development environment, in Docker.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Neovim](https://img.shields.io/badge/neovim-stable-57A143?logo=neovim&logoColor=white)
![LazyVim](https://img.shields.io/badge/LazyVim-starter-blueviolet)
![Base](https://img.shields.io/badge/base-debian%20trixie--slim-A81D33?logo=debian&logoColor=white)
![Status](https://img.shields.io/badge/status-active-brightgreen)

---

## Why this exists

If you've ever tried to share a Neovim setup across machines — your laptop, a remote dev box, a colleague's workstation, a CI runner — you know the pain. Plugin managers download things on first launch. Mason needs a working compiler chain. Treesitter parsers compile per platform. The first 90 seconds of "I just want to edit a file" become "wait, why is `lua_ls` not installing?"

**LazyDE solves this by baking everything into a container.** You get a fully provisioned LazyVim environment that opens instantly — no first-run downloads, no Mason popups, no parser compilation surprises. Just `nvim` and you're editing.

It's also designed to be **layered**. The base image is intentionally minimal — it knows how to be Neovim, and that's it. Language-specific tooling (Python LSPs, .NET SDKs, PHP toolchains) lives in downstream images that build *on top* of this one, so you only carry what you actually use.

### Isolation as a security boundary

A modern Neovim setup pulls hundreds of plugins, language servers, and binaries from third parties — all running with your full user privileges and free to read your SSH keys, cloud credentials, and home directory. Running LazyVim inside a container draws a hard boundary around that risk: plugins only see what you explicitly mount in, typically just the current project. Every downstream image inherits the same isolation, and because each only carries what it needs, the supply-chain surface stays smaller too.

---

## Quick start

Pull or build the base image, then run:

```bash
# Build locally
docker build -t lazyde-base:stable .
# or: podman build -t lazyde-base:stable .

# Open Neovim in your current directory
docker run --rm -it -w /mnt/volume -v "$PWD:/mnt/volume" lazyde-base:stable
# or: podman run --rm -it -w /mnt/volume -v "$PWD:/mnt/volume" lazyde-base:stable
```

That's it. Neovim opens in `/mnt/volume` with all plugins, parsers, and Mason tools ready.

### Recommended shell alias

```bash
alias nvim='docker run --rm -it -w /mnt/volume -v "$PWD:/mnt/volume" lazyde-base:stable'
# or: alias nvim='podman run --rm -it -w /mnt/volume -v "$PWD:/mnt/volume" lazyde-base:stable'
```

Now you can `cd` into any project and just type `nvim`.

---

## What's inside

The base image ships a deliberately minimal set of tools — enough to be a productive Neovim environment for editing config files, shell scripts, and documentation, plus the runtime hooks that downstream language images extend.

### Core

| Component         | Notes                                                     |
| ----------------- | --------------------------------------------------------- |
| Neovim (stable)   | Built from source, stripped, statically linked where possible |
| LazyVim starter   | Pre-cloned, plugins pre-installed via `Lazy! install`     |
| tree-sitter CLI   | Prebuilt binary from upstream releases                    |

### Runtime tools

| Tool         | Why it's here                                             |
| ------------ | --------------------------------------------------------- |
| `git`        | Required by `lazy.nvim` to manage plugins                 |
| `lazygit`    | LazyVim's built-in git UI                                 |
| `fd`         | File finder for Telescope (`fd-find` symlinked to `fd`)   |
| `ripgrep`    | Live grep backend for Telescope                           |
| `curl`       | Used by Mason and various plugins                         |
| `xclip`      | Clipboard integration                                     |
| `gcc` + `libc6-dev` | Needed by nvim-treesitter to compile parsers       |

### Pre-installed treesitter parsers

A small "always useful" set: `bash`, `diff`, `lua`, `luadoc`, `markdown`, `markdown_inline`, `vim`, `vimdoc`, `query`, `regex`. Language-specific parsers (Python, PHP, TypeScript, etc.) live in the downstream images.

### Pre-installed Mason tools

- `lua-language-server` — for editing your nvim config
- `stylua` — Lua formatter
- `shfmt` — shell script formatter

---

## Build & customization

The Dockerfile exposes a few build args you can override:

| Arg                    | Default     | Purpose                                  |
| ---------------------- | ----------- | ---------------------------------------- |
| `NVIM_VERSION`         | `stable`    | Neovim git ref to build (tag/branch/sha) |
| `TREE_SITTER_VERSION`  | `v0.26.8`   | tree-sitter CLI release tag              |

### Examples

Pin to a specific Neovim release:

```bash
docker build --build-arg NVIM_VERSION=v0.10.2 -t lazyde-base:v0.10.2 .
# or: podman build --build-arg NVIM_VERSION=v0.10.2 -t lazyde-base:v0.10.2 .
```

Track Neovim nightly:

```bash
docker build --build-arg NVIM_VERSION=nightly -t lazyde-base:nightly .
# or: podman build --build-arg NVIM_VERSION=nightly -t lazyde-base:nightly .
```

Tag both `stable` and `latest` at once:

```bash
docker build -t lazyde-base:stable -t lazyde-base:latest .
# or: podman build -t lazyde-base:stable -t lazyde-base:latest .
```

### Verifying the build

```bash
docker run --rm lazyde-base:stable nvim --version
docker run --rm lazyde-base:stable sh -c 'which fd lazygit rg tree-sitter git'
# or: podman run --rm lazyde-base:stable nvim --version
# or: podman run --rm lazyde-base:stable sh -c 'which fd lazygit rg tree-sitter git'
```

---

## Layering your own LazyVim config
 
The base image ships LazyVim's starter config. To use your own configuration, build a downstream image that copies in your `~/.config/nvim` and pre-installs whatever extra plugins, parsers, and Mason tools your config needs.
 
A worked example lives in [`examples/personal/`](examples/personal/). The short version:
 
```dockerfile
FROM lazyde-base:stable
 
# Replace the starter with your config
RUN rm -rf /root/.config/nvim
COPY nvim /root/.config/nvim
 
# Sync any new plugins your config introduces
RUN nvim --headless "+Lazy! sync" +qa

# OR
RUN nvim --headless "+Lazy! install" +qa
 
# Optionally install extra parsers and Mason tools — see the example
# for the full async-aware Mason install pattern.
```
 
Build and run:
 
```bash
cp -r ~/.config/nvim ./nvim
docker build -t lazyde-personal:stable .
docker run --rm -it -w /mnt/volume -v "$PWD:/mnt/volume" lazyde-personal:stable
```
 

## Roadmap

The base image is the foundation. Language-specific flavors stack on top — each adds its own treesitter parsers, Mason tools, and runtime SDKs.

| Image              | Status     | What it adds                                              |
| ------------------ | ---------- | --------------------------------------------------------- |
| `lazyde-base`      | ✅ Released | Neovim + LazyVim + core tooling                           |
| `lazyde-python`    | 🚧 Planned | Python venv, `pyright`, `ruff`, parsers (python/toml/yaml)|
| `lazyde-web`       | 🚧 Planned | Node, TypeScript LSP, Vue LSP, parsers (ts/tsx/html/css)  |
| `lazyde-php`       | 🚧 Planned | PHP, `phpactor`, `php-cs-fixer`, composer                 |
| `lazyde-dotnet`    | 🚧 Planned | .NET SDK, `omnisharp`, `csharpier`, `netcoredbg`          |
| `lazyde-systems`   | 💭 Idea    | C/C++/Rust toolchains, `clangd`, `cmake-language-server`  |
| `lazyde-full`      | 💭 Idea    | Everything, for when you don't want to choose             |

Each downstream image will follow the same conventions: pre-installed parsers, pre-installed Mason tools, no first-launch downloads.

---

## Project structure

```
lazyde/
├── Dockerfile            # The base image build
├── README.md             # You're reading it
└── (future)
    ├── python/Dockerfile
    ├── web/Dockerfile
    ├── php/Dockerfile
    └── dotnet/Dockerfile
```

---

## Design principles

A few rules this project tries to follow:

1. **Reproducible builds.** Every external download is version-pinned. No "latest from main" surprises.
2. **No first-run work.** If a tool is meant to be available, it's installed at build time — never lazily on first launch.
3. **Layered, not monolithic.** The base stays minimal; language tooling is opt-in via downstream images.
4. **Multi-stage where it matters.** Build dependencies (cmake, ninja, gettext) stay in the builder stage and never bloat the final image.

---

## Contributing

Contributions are welcome. The project is in early days, so the easiest ways to help right now:

- File issues for things that don't work or could be cleaner
- Propose a downstream language image (or build one and PR it)
- Improve build times or shrink final image sizes

---

## License

Apache — see [LICENSE](LICENSE).

LazyVim, Neovim, and all bundled tools retain their respective licenses.
