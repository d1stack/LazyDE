# Personal LazyDE example

A reference image showing how to layer your own LazyVim configuration on top of `lazyde-base`. Use it as a starting point for your own Dockerfile.

## Quick start

1. Make sure the base image is built locally:

   ```bash
   podman build -t lazyde-base:stable ../..
   ```

2. Copy your LazyVim config next to this Dockerfile:

   ```bash
   cp -r ~/.config/nvim ./nvim
   ```

3. Build your personalised image:

   ```bash
   podman build -t lazyde-personal:stable .
   ```

4. Run it:

   ```bash
   podman run --rm -it -v "$PWD:/mnt/volume" lazyde-personal:stable
   ```

   Or set up an alias in your shell:

   ```bash
   alias mynvim='podman run --rm -it -v "$PWD:/mnt/volume" lazyde-personal:stable'
   ```

## What the Dockerfile does

The build performs five steps, each of which can be customised:

1. **Replace the LazyVim starter** with your own `nvim/` directory.
2. **Install plugins** declared by your config. Defaults to `Lazy! sync` (clean state, removes anything unused) — switch to `Lazy! install` if you prefer to keep starter plugins around. See the comment block in the Dockerfile for the tradeoff.
3. **Install extra treesitter parsers** your config uses (Python, JSON, YAML, TOML in this example).
4. **Install extra Mason tools** (`pyright`, `ruff`, `prettier` in this example).
5. **Install OS-level dependencies** if your tools need them (Python, Node, etc.) — commented out by default.

Edit the parser list in step 3 and the Mason package list in step 4 to match what your config actually uses. The `+MasonInstall` arguments and the `pkgs = { ... }` table need to stay in sync — the polling loop reads from the latter to know when to exit.

## Tips

- Keep your `nvim/` directory in version control alongside this Dockerfile so the image is fully reproducible.
- If your config uses environment variables (e.g. for API keys or paths), pass them at runtime with `-e VAR=value` rather than baking them into the image.
- For language-specific setups (Python, Node, .NET, etc.), you may prefer to base your image on one of the upcoming `lazyde-{language}` images instead of `lazyde-base` — they ship the SDK and language servers pre-installed.
