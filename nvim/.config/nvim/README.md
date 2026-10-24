# Neovim configuration

A small setup using Neovim's built-in LSP and completion, Telescope, Tree-sitter,
Bufferline, and the Tokyonight theme. Tested with Neovim 0.12.6.

## Files

- `init.lua`: loads options, bootstraps Lazy, then loads plugins, LSP settings, and keymaps.
- `lua/options.lua`: indentation and completion menu settings.
- `lua/plugins.lua`: plugin dependencies and setup.
- `lua/lsp.lua`: language-server settings, automatic LSP completion, and format-on-save.
- `lua/keymaps.lua`: personal shortcuts. The leader key is `\`.
- `after/ftplugin/`: line-comment defaults for Objective-C and Objective-C++.
- `lazy-lock.json`: pinned plugin revisions.

## Tools and installation

Lazy installs the configured plugins on first startup. Git, a C compiler, Make,
and the Tree-sitter CLI are needed to install/build the plugins and parsers.
Telescope's live grep uses `rg` (ripgrep).

| Tool | Source | Purpose |
| --- | --- | --- |
| `clangd` | System `PATH` | C/C++/Objective-C/CUDA language support and formatting |
| `clang-format` | System `PATH` | GLSL formatting on save |
| `cmake-language-server` | Mason | CMake language support |
| `glsl_analyzer` | Mason | GLSL language support |

Mason uses `PATH = "append"`, so existing system/Homebrew tools take priority.
It ensures the CMake and GLSL servers are installed and enables them automatically.
The LSP configuration explicitly enables system clangd. There is no Mason install
requirement for clangd or clang-format.

On this Mac, the checked paths are `/usr/bin/clangd` (Apple) and
`/opt/homebrew/bin/clang-format` (Homebrew). Check Neovim's selections with:

```vim
:lua print(vim.fn.exepath("clangd"))
:lua print(vim.fn.exepath("clang-format"))
```

C-family formatting uses clangd's embedded formatter. GLSL formatting invokes
`clang-format` directly. Both read the project's `.clang-format`, but their
formatter versions can differ. See [clangd's formatting documentation](https://clangd.llvm.org/features.html#formatting).

Tree-sitter installs parsers for C, C++, CMake, and Lua and enables highlighting
and indentation for those filetypes. Telescope loads its native FZF sorter.

Bufferline displays open buffers as tabs along the top, using the current theme.
Click a buffer to switch to it, or use `:bnext` / `:bprevious`. `:bdelete` closes
the current buffer. Existing keybindings are unchanged. File icons use
`nvim-web-devicons` and need a Nerd Font in the terminal.

## Completion and shortcuts

Neovim's native automatic completion shows language-server suggestions while
typing in attached buffers. A small guard skips automatic requests when only
whitespace precedes the cursor, then delegates to Neovim's LSP omnifunc.
There is no additional completion plugin. `noselect` keeps suggestions from
being accepted automatically.

| Keys | Action |
| --- | --- |
| `Ctrl-X Ctrl-O` in insert mode | Request language-server completion |
| `Ctrl-N` / `Ctrl-P` in insert mode | Keyword completion, or move through an open completion menu |
| `Ctrl-Y` / `Ctrl-E` | Accept / dismiss completion |
| `gcc` | Toggle a line comment; accepts a count, such as `5gcc` |
| `gc` after a visual selection | Toggle comments on the selected lines |
| `Ctrl+/` in normal mode | Shortcut for native `gcc` (terminal support may vary) |
| `F2` | Go to definition |
| `F3` | Switch between source/header with clangd attached |
| `\ff`, `\fg`, `\fb`, `\fh` | Find files, live grep, buffers, help |
| `\p` / `\P` in normal mode | Paste from the system clipboard |
| `\y` / `\d` in visual mode | Copy / cut to the system clipboard |

Neovim's LSP defaults also provide `K` for hover, `grn` for rename, `grr` for
references, and `gra` for code actions. Commenting uses Neovim's native `gc`
mappings; Comment.nvim is not required. Objective-C and Objective-C++ use `//`
comments. See `:help commenting` and `:help lsp-defaults`.

Saving C-family buffers formats through an attached clangd, regardless of file
extension (including `.cc`, `.cxx`, and `.cu`). Saving GLSL buffers runs
`clang-format`. Other filetypes are left alone. For a manual C-family formatting
request, use `:lua vim.lsp.buf.format()`.

## Project workflow

Run these from the project's root:

```sh
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

The generated `build/compile_commands.json` supplies include paths, compiler
flags, and the language standard to clangd. If clangd does not find it, add this
to the project's `.clangd` file:

```yaml
CompileFlags:
  CompilationDatabase: build
```

Alternatively, link `compile_commands.json` from the project root to the generated file.
See [clangd's compilation database documentation](https://clangd.llvm.org/installation#compile_commandsjson).

Restart Neovim after changing this configuration. Use `:checkhealth vim.lsp`
to inspect language servers, `:Mason` to manage Mason tools, and `:Lazy` to
manage plugins.

## CMake server installation workaround

The installed `cmake-language-server` is 0.1.11 with pygls 1.3.1. Its existing
Mason environment uses Apple's Python. This server version requires Python
below 3.14 and can fail with pygls 2.x.

If reinstalling this version fails to find a supported Python, close Neovim
and launch it with Apple's Python first on `PATH`:

```sh
PATH=/usr/bin:/bin:/opt/homebrew/bin:/usr/sbin:/sbin /opt/homebrew/bin/nvim
```

Run `:MasonInstall cmake-language-server`. If the installed server then reports
`ImportError: cannot import name 'LanguageServer' from 'pygls.server'`, pin pygls
inside that server's environment:

```sh
~/.local/share/nvim/mason/packages/cmake-language-server/venv/bin/python -m pip install 'pygls>=1.1.1,<2'
```

This workaround leaves the default Homebrew Python unchanged. See the
[upstream dependency issue](https://github.com/regen100/cmake-language-server/issues/101).
