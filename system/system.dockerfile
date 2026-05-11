# lazyde-system:stable (clang + rust toolchain)
# ---------------------------------------------------------------------
# Systems development image layered on top of lazyde-base.
#
# Build:
#   docker build -f system/system.dockerfile -t lazyde-system:stable .
#
# Run:
#   docker run --rm -it -v "$PWD:/mnt/volume" lazyde-system:stable

FROM lazyde-base:stable

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      clang \
      lld \
      rustc \
      cargo \
      rustfmt \
      rust-clippy \
      cmake \
      pkg-config \
      build-essential \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# Treesitter parsers for systems languages.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ 'c', 'cpp', 'rust', 'cmake', 'toml' }):wait(300000)" \
    +qa

# Mason tools for systems workflows.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall clangd neocmakelsp codelldb" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'clangd', 'neocmakelsp', 'codelldb' }; \
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
