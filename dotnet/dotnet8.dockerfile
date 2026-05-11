# lazyde-dotnet: .NET 8
# ---------------------------------------------------------------------
# .NET-focused development image layered on top of lazyde-base.
#
# Build:
#   docker build -f dotnet/dotnet8.dockerfile -t lazyde-dotnet:dotnet8 .
#
# Run:
#   docker run --rm -it -v "$PWD:/mnt/volume" lazyde-dotnet:dotnet8

FROM lazyde-base:stable

ARG DEBIAN_FRONTEND=noninteractive
ARG DOTNET_SDK_PACKAGE=dotnet-sdk-8.0
ARG DOTNET_RUNTIME_PACKAGE=aspnetcore-runtime-8.0

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      gpg \
      unzip \
    && wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm -f /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      "${DOTNET_SDK_PACKAGE}" \
      "${DOTNET_RUNTIME_PACKAGE}" \
    && rm -rf /var/lib/apt/lists/*

# Treesitter parsers for .NET development.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'nvim-treesitter'}})" \
    "+lua require('nvim-treesitter').install({ 'c_sharp', 'json', 'xml', 'yaml' }):wait(300000)" \
    +qa

# Mason tools for the .NET stack.
RUN nvim --headless \
    "+lua require('lazy').load({plugins={'mason.nvim'}})" \
    "+MasonInstall omnisharp netcoredbg csharpier fsautocomplete" \
    "+lua \
       local registry = require('mason-registry'); \
       local pkgs = { 'omnisharp', 'netcoredbg', 'csharpier', 'fsautocomplete' }; \
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
