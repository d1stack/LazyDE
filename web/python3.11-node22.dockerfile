# lazyde-web: Python 3.11 + Node 22
# ---------------------------------------------------------------------
# Full-stack web development image (Python, JS/TS, HTML, CSS, Vue)
# layered on top of lazyde-base.
#
# Build:
#   podman build -f web/python3.11-node22.dockerfile \
#                -t lazyde-web:python3.11-node22 .
#
# Run:
#   podman run --rm -it -v "$PWD:/mnt/volume" lazyde-web:python3.11-node22

FROM lazyde-base:stable

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

# ---------------------------------------------------------------------
# 1. Python 3.11 + pip + build deps
# ---------------------------------------------------------------------
COPY --from=python:3.11-slim /usr/local /usr/local

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      build-essential \
      pkg-config \
      libffi-dev \
      libssl-dev \
      libpq-dev \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# uv (fast Python package/project manager)
COPY --from=ghcr.io/astral-sh/uv:0.7.2 /uv /uvx /usr/local/bin/

# Python tooling and frameworks for web development.
RUN uv tool install ruff \
    && uv tool install pyright \
    && uv tool install django \
    && uv tool install flask \
    && uv tool install 'fastapi[standard]'

# ---------------------------------------------------------------------
# 2. Node 22 + npm
# ---------------------------------------------------------------------
COPY --from=node:22-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:22-slim /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# ---------------------------------------------------------------------
# 3. Global npm tools
# ---------------------------------------------------------------------
# - typescript:                     tsc compiler for CLI use
# - @vue/language-server + plugin:  Vue 3 LSP
# - vscode-langservers-extracted:   HTML, CSS, JSON, ESLint LSPs
RUN npm install -g --omit=dev \
      typescript \
      @vue/language-server \
      @vue/typescript-plugin \
      vscode-langservers-extracted \
    && npm cache clean --force

# ---------------------------------------------------------------------
# 4. Treesitter parsers for the web + python stack
# ---------------------------------------------------------------------
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ \
        'python', 'toml', 'yaml', \
        'html', 'css', 'scss', \
        'javascript', 'typescript', 'tsx', \
        'vue', \
        'json', 'jsonc' \
      }):wait(300000)" \
    +qa

# ---------------------------------------------------------------------
# 5. Mason tools for the web + python stack
# ---------------------------------------------------------------------
# Same async-polling pattern as the base image. Keep the +MasonInstall
# args and the pkgs table in sync.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall pyright ruff vtsls prettier eslint-lsp json-lsp" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'pyright', 'ruff', 'vtsls', 'prettier', 'eslint-lsp', 'json-lsp' }; \
       local deadline = vim.loop.now() + 600000; \
       while vim.loop.now() < deadline do \
         local done = true; \
         for _, name in ipairs(pkgs) do \
           if not registry.is_installed(name) then done = false; break end \
         end; \
         if done then break end; \
         vim.wait(1000); \
       end" \
    +qa

COPY .config/nvim /tmp/lazyde-custom-nvim

RUN set -eux; \
    if [ -f /tmp/lazyde-custom-nvim/init.lua ] || [ -d /tmp/lazyde-custom-nvim/lua ]; then \
      rm -rf /root/.config/nvim; \
      cp -R /tmp/lazyde-custom-nvim /root/.config/nvim; \
      rm -rf /root/.local/share/nvim/lazy /root/.local/state/nvim/lazy; \
      if [ -f /root/.config/nvim/lazy-lock.json ]; then \
        nvim --headless "+Lazy! restore" +qa; \
      else \
        nvim --headless "+Lazy! install" +qa; \
      fi; \
    else \
      echo "No custom Neovim config found in .config/nvim; keeping stock config."; \
    fi; \
    rm -rf /tmp/lazyde-custom-nvim

WORKDIR /mnt/volume
CMD ["/usr/local/bin/nvim"]
