# lazyde-web: PHP 8.3 + Node 24
# ---------------------------------------------------------------------
# Full-stack web development image (PHP, JS/TS, HTML, CSS, Vue) layered
# on top of lazyde-base.
#
# Build:
#   podman build -f php8.3-node24.dockerfile \
#                -t lazyde-web:php8.3-node24 .
#
# Run:
#   podman run --rm -it -v "$PWD:/mnt/volume" lazyde-web:php8.3-node24

FROM lazyde-base:stable

ARG DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------
# 1. PHP 8.3 + extensions + Composer
# ---------------------------------------------------------------------
# PHP packages come from Sury's repo (deb.sury.org), the standard source
# for current PHP versions on Debian. Debian's own apt only carries one
# PHP version per release.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release \
    && curl -fsSL https://packages.sury.org/php/apt.gpg \
       | gpg --dearmor -o /usr/share/keyrings/sury-php-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/sury-php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
       > /etc/apt/sources.list.d/sury-php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php8.3 \
        php8.3-cli \
        php8.3-mbstring \
        php8.3-xml \
        php8.3-curl \
        php8.3-zip \
        php8.3-mysql \
        php8.3-pgsql \
        php8.3-sqlite3 \
        php8.3-intl \
        php8.3-bcmath \
        php8.3-gd \
        php8.3-opcache \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Composer 2.8 (current stable).
COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

# ---------------------------------------------------------------------
# 2. Node 24 + npm
# ---------------------------------------------------------------------
COPY --from=node:24-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:24-slim /usr/local/lib/node_modules /usr/local/lib/node_modules

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
# 4. Treesitter parsers for the web stack
# ---------------------------------------------------------------------
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ \
        'php', 'phpdoc', \
        'html', 'css', 'scss', \
        'javascript', 'typescript', 'tsx', \
        'vue', \
        'json', 'jsonc', 'yaml' \
      }):wait(300000)" \
    +qa

# ---------------------------------------------------------------------
# 5. Mason tools for the web stack
# ---------------------------------------------------------------------
# Same async-polling pattern as the base image. Keep the +MasonInstall
# args and the pkgs table in sync.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall phpactor php-cs-fixer phpcs vtsls prettier eslint-lsp json-lsp" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'phpactor', 'php-cs-fixer', 'phpcs', 'vtsls', 'prettier', 'eslint-lsp', 'json-lsp' }; \
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

WORKDIR /mnt/volume
CMD ["/usr/local/bin/nvim"]
