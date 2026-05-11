# lazyde-qt: Qt 6
# ---------------------------------------------------------------------
# Qt/QML-focused development image layered on top of lazyde-base.
#
# Build:
#   docker build -f qt/qt6.dockerfile -t lazyde-qt:qt6 .
#
# Run:
#   docker run --rm -it -v "$PWD:/mnt/volume" lazyde-qt:qt6

FROM lazyde-base:stable

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      pkg-config \
      ninja-build \
      clangd \
      libglib2.0-dev \
      qt6-base-dev \
      qt6-declarative-dev \
      qt6-tools-dev-tools \
      qml6-module-qtquick \
      qml6-module-qtquick-controls \
      python3 \
      python3-pip \
      python3-venv \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# Optional Qt-for-Python tooling used by some projects.
RUN pip3 install --break-system-packages PySide6

# Treesitter parsers for Qt/C++ projects.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ 'cpp', 'cmake', 'qmljs', 'json', 'yaml' }):wait(300000)" \
    +qa

# Mason tools for C++/CMake workflows.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall clangd neocmakelsp" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'clangd', 'neocmakelsp' }; \
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
