# Example: build a personalised LazyDE image on top of lazyde-base
# ---------------------------------------------------------------
# This Dockerfile shows how to layer your own LazyVim configuration
# on top of the lazyde-base image. The base provides Neovim, LazyVim
# starter, treesitter parsers, and a few essential Mason tools — this
# image replaces the starter config with yours and pre-installs any
# additional plugins/parsers/tools your config needs.
#
# Expected layout next to this Dockerfile:
#
#   examples/personal/
#   ├── Dockerfile         <-- you are here
#   └── nvim/              <-- copy of your ~/.config/nvim
#       ├── init.lua
#       ├── lua/
#       └── ...

FROM lazyde-base:stable

ARG DEBIAN_FRONTEND=noninteractive

# 1. Replace the LazyVim starter with your own config.
#    The starter's plugin lock and state are removed so lazy.nvim
#    re-resolves everything against your config from scratch.
RUN rm -rf /root/.config/nvim
COPY nvim /root/.config/nvim

# 2. Install plugins your config declares.
#
#    Two choices here:
#
#    a) "+Lazy! install" — installs anything new your config introduces,
#       leaves everything else alone. Faster, more forgiving during
#       config iteration, but stale starter plugins stay on disk if your
#       config disables or replaces them.
#
#    b) "+Lazy! sync" — installs new plugins, updates existing ones,
#       AND removes anything no longer referenced. Produces a leaner
#       image whose state matches your config exactly. Recommended for
#       reproducible/published images.
#
#    Pick whichever fits your workflow. The default below is sync;
#    swap to install if you prefer.
RUN nvim --headless "+Lazy! sync" +qa

# 3. (Optional) Install additional treesitter parsers your config uses.
#    Edit the list to match what you actually need.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ 'python', 'json', 'yaml', 'toml' }):wait(300000)" \
    +qa

# 4. (Optional) Install additional Mason tools your config expects.
#    Same async-polling pattern the base image uses — keep the package
#    list in the +MasonInstall line and the pkgs table in sync.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall pyright ruff prettier" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'pyright', 'ruff', 'prettier' }; \
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

# 5. (Optional) Install OS-level dependencies your tooling needs.
#    For example, Python for pyright/ruff to actually inspect code,
#    or Node if you use any Node-based language servers directly.
# RUN apt-get update && apt-get install -y --no-install-recommends \
#       python3 python3-venv \
#     && rm -rf /var/lib/apt/lists/*

WORKDIR /mnt/volume
CMD ["/usr/local/bin/nvim"]
