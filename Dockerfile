FROM debian:trixie-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG NVIM_VERSION=stable
ARG TREE_SITTER_VERSION=v0.26.8

# Build dependencies for Neovim. Kept in the builder stage so they
# don't bloat the final image.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      curl \
      build-essential \
      cmake \
      ninja-build \
      gettext \
      libtool \
      libtool-bin \
      autoconf \
      automake \
      pkg-config \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# Build Neovim from source
RUN git clone https://github.com/neovim/neovim.git /tmp/neovim && \
    cd /tmp/neovim && \
    git fetch --all --tags -f && \
    git checkout ${NVIM_VERSION} && \
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/usr/local && \
    make install && \
    strip /usr/local/bin/nvim

# Install tree-sitter CLI from prebuilt release binary.
# Auto-detect arch so this works on both linux/amd64 and linux/arm64.
RUN case "$(dpkg --print-architecture)" in \
      amd64) TS_ARCH=x64 ;; \
      arm64) TS_ARCH=arm64 ;; \
      *) echo "Unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/tree-sitter.zip \
      "https://github.com/tree-sitter/tree-sitter/releases/download/${TREE_SITTER_VERSION}/tree-sitter-cli-linux-${TS_ARCH}.zip" && \
    unzip -p /tmp/tree-sitter.zip tree-sitter > /usr/local/bin/tree-sitter && \
    chmod +x /usr/local/bin/tree-sitter && \
    rm /tmp/tree-sitter.zip && \
    strip /usr/local/bin/tree-sitter


# ---- Final stage ----------------------------------------------------------
FROM debian:trixie-slim

LABEL maintainer="Aliaksandr Yurchyk <alexweb.fi@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive

# Runtime dependencies only.
# - git: required by lazy.nvim to clone plugins
# - lazygit: LazyVim's built-in git UI
# - fd-find: file finder used by Telescope (binary is `fdfind` on Debian)
# - ripgrep: live grep for Telescope
# - curl: used by various plugins / mason fallbacks
# - xclip: clipboard support (optional but commonly expected)
# - ca-certificates: TLS for git clones over https
# - locales: avoid locale warnings in TUI
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      lazygit \
      fd-find \
      ripgrep \
      curl \
      xclip \
      locales \
      gcc \
      libc6-dev \
      fzf \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled binaries from builder
COPY --from=builder /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=builder /usr/local/share/nvim /usr/local/share/nvim
COPY --from=builder /usr/local/lib/nvim /usr/local/lib/nvim
COPY --from=builder /usr/local/bin/tree-sitter /usr/local/bin/tree-sitter

ENV LANG=C.UTF-8

# Install LazyVim starter
RUN git clone https://github.com/LazyVim/starter /root/.config/nvim && \
    rm -rf /root/.config/nvim/.git

# Bootstrap plugins (headless). Tree-sitter parsers are skipped here because
# LazyVim ships its own treesitter setup; we trigger parser installation
# explicitly afterwards.
RUN rm -rf /root/.local/share/nvim/lazy/nvim-treesitter \
           /root/.local/share/nvim/lazy/nvim-treesitter-textobjects \
           /root/.local/share/nvim/site/parser

RUN nvim --headless "+Lazy! install" +qa

RUN nvim --headless "+Lazy! sync nvim-treesitter" +qa

RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ 'bash', 'diff', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'vim', 'vimdoc', 'query', 'regex' }):wait(300000)" \
    +qa

# Install Mason tools at build time so first launch is silent.
# Mason installs are async, so we trigger them then poll the registry
# until all requested packages report as installed (or 5 min elapse).
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall lua-language-server stylua shfmt" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'lua-language-server', 'stylua', 'shfmt' }; \
       local deadline = vim.loop.now() + 300000; \
       while vim.loop.now() < deadline do \
         local done = true; \
         for _, name in ipairs(pkgs) do \
           if not registry.is_installed(name) then done = false; break end \
         end; \
         if done then break end; \
         vim.wait(1000); \
       end" \
    +qa

# Download blink.cmp's prebuilt fuzzy matcher (.so) directly.
# blink.cmp ships a Rust-compiled fuzzy matching library
# (libblink_cmp_fuzzy.so) that lazy.nvim would otherwise try to download
# at first launch via an async callback. We fetch it at build time so the
# image is fully self-contained and there's no first-run download.
#
# The version must match the lazy.nvim-resolved tag of blink.cmp. We read
# the tag from the plugin's git checkout, then pull the matching release
# asset from GitHub.
RUN set -eux; \
    cd /root/.local/share/nvim/lazy/blink.cmp; \
    BLINK_VERSION="$(git describe --tags --abbrev=0)"; \
    case "$(dpkg --print-architecture)" in \
      amd64) BLINK_TARGET=x86_64-unknown-linux-gnu ;; \
      arm64) BLINK_TARGET=aarch64-unknown-linux-gnu ;; \
      *) echo "Unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;; \
    esac; \
    mkdir -p target/release; \
    curl -fsSL -o target/release/libblink_cmp_fuzzy.so \
      "https://github.com/Saghen/blink.cmp/releases/download/${BLINK_VERSION}/${BLINK_TARGET}.so"; \
    echo "${BLINK_VERSION}" > target/release/version.txt


WORKDIR /mnt/volume
CMD ["/usr/local/bin/nvim"]
