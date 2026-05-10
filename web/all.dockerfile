# lazyde-web: PHP + Python + Node (reused image layers)
# ---------------------------------------------------------------------
# Unified full-stack web development image that reuses previously built
# PHP and Python variant images.
#
# Build (default source images):
#   docker build -f web/all.dockerfile -t lazyde-web:all .
#
# Build (override source image tags):
#   docker build -f web/all.dockerfile \
#     --build-arg PHP_IMAGE=lazyde-web:php8.4-node24 \
#     --build-arg PYTHON_IMAGE=lazyde-web:python3.13-node24 \
#     -t lazyde-web:all .
#
# Run:
#   docker run --rm -it -v "$PWD:/mnt/volume" lazyde-web:all

ARG PHP_IMAGE=lazyde-web:php8.3-node22
ARG PYTHON_IMAGE=lazyde-web:python3.12-node22

FROM ${PHP_IMAGE} AS php_src
FROM ${PYTHON_IMAGE} AS py_src

FROM php_src

ENV PATH="/root/.local/bin:${PATH}"

# ---------------------------------------------------------------------
# 1. Import Python runtime + tooling from prebuilt python image
# ---------------------------------------------------------------------
# Reuse Python data and uv-installed tools directly from py_src.
COPY --from=py_src /usr/local /usr/local
COPY --from=py_src /root/.local /root/.local

# ---------------------------------------------------------------------
# 2. Treesitter parsers for the web + php + python stack
# ---------------------------------------------------------------------
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ \
        'php', 'phpdoc', \
        'python', 'toml', 'yaml', \
        'html', 'css', 'scss', \
        'javascript', 'typescript', 'tsx', \
        'vue', \
        'json', 'jsonc' \
      }):wait(300000)" \
    +qa

# ---------------------------------------------------------------------
# 3. Mason tools for the web + php + python stack
# ---------------------------------------------------------------------
# Same async-polling pattern as the base image. Keep the +MasonInstall
# args and the pkgs table in sync.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall phpactor php-cs-fixer phpcs pyright ruff vtsls prettier eslint-lsp json-lsp" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'phpactor', 'php-cs-fixer', 'phpcs', 'pyright', 'ruff', 'vtsls', 'prettier', 'eslint-lsp', 'json-lsp' }; \
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
