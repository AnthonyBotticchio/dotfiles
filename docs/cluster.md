# Development on Frontenac

Research checked 4 November 2026 against this repository's configuration and primary documentation. The recommendation is SSH + remote tmux + Neovim + Git, with Vim available for quick edits. Keeping this Neovim configuration is reasonable; manage where its external tools run.

## Is Neovim with these plugins bad practice?

No. UC Riverside's HPC documentation teaches tmux and Neovim together and supports custom extensions. Luxembourg's HPC documentation explicitly suggests Neovim with plugins for advanced terminal editing. Neither implies every plugin or language server is suitable for every login node. [UCR terminal environments](https://hpcc.ucr.edu/manuals/hpc_cluster/terminalide/), [ULHPC login-node guidance](https://hpc-docs.uni.lu/connect/access/).

CAC says Frontenac computations must be started through Slurm and provides software through Lmod. Its acceptable-use policy requires users to share CPU, disk, and other resources. My recommendation is to use the full editor, language servers, builds, tests, debugging, and plugin setup in an interactive allocation. Use Vim for quick login-node edits when you want to avoid starting language servers. This is a conservative workflow recommendation, not a published CAC ban on Neovim or LSP. [CAC Frontenac overview](https://cac.queensu.ca/systems/traditional-hpc/), [CAC acceptable use](https://cac.queensu.ca/security-policies/acceptable-usage/).

| Current component | Assessment and practice |
| --- | --- |
| Tokyonight, Bufferline, devicons | Keep them. These provide editor UI; they do not submit work or index the project. Select a Nerd Font in your laptop's terminal for icons. |
| Telescope + native FZF | Keep them. The native sorter needs Make and a C compiler during installation; live grep needs `rg`. Search from the source repository, avoiding broad scans of home, project storage, or datasets. |
| Tree-sitter | Keep it. Parser installation compiles code, so do first setup and updates in an allocation. The pinned plugin requires Neovim 0.12+, Tree-sitter CLI 0.26.1+, curl, tar, and a C compiler. Its documentation explicitly advises against installing the CLI through npm. |
| Mason + mason-lspconfig | Keep them. This config automatically installs the CMake, GLSL, and Rust servers and enables installed servers. First startup therefore needs download access and each server's installation dependencies, including Python/pip/venv for the CMake server. |
| clangd / rust-analyzer | Use in an allocation, especially with larger projects. Language servers are separate processes; a terminal editor does not make their indexing free. This config enables clangd from `PATH`. |
| Format on save | Keep it. C-family files use clangd; GLSL uses `clang-format`; Rust uses `rustfmt`. Load or install those tools when using the corresponding languages. |

The UI assessment is an inference from the checked plugin specifications, not a measured performance comparison. Tree-sitter's requirements, Telescope's build instructions, and Mason's automatic behavior are documented upstream. [Tree-sitter requirements](https://github.com/nvim-treesitter/nvim-treesitter#requirements), [Telescope requirements](https://github.com/nvim-telescope/telescope.nvim#installation), [native FZF build](https://github.com/nvim-telescope/telescope-fzf-native.nvim#installation), [Mason requirements](https://github.com/mason-org/mason.nvim#requirements), [automatic server enabling](https://github.com/mason-org/mason-lspconfig.nvim#automatically-enable-installed-servers).

clangd's background index parses the entire compilation database and writes an index cache. For a project that becomes expensive, its documented `Index: { Background: Skip }` setting disables background indexing; it does not eliminate all parsing or enforce a memory limit. Prefer allocating enough resources for the project. [clangd indexing](https://clangd.llvm.org/design/indexing), [clangd configuration](https://clangd.llvm.org/config#index).

## Recommended tools

| Purpose | Tools |
| --- | --- |
| Connect and preserve a session | Your local SSH client; tmux on Frontenac |
| Edit and track source | Neovim, Vim, Git |
| Search and transfer files | ripgrep, standard `find`, rsync; `fd` is optional |
| Select the cluster toolchain | `module avail`, `module spider`, `module load`, `module list` |
| Build C/C++/MPI projects | Site compiler and MPI modules; CMake and Make or Ninja as required by the project |
| Debug and inspect | GDB or the site's supported debugger; `top -u "$USER"`; project-specific profilers when needed |
| Schedule and inspect jobs | `srun`/`salloc`, `sbatch`, `squeue -u "$USER"`, `sacct`, `scancel` |

Use site compiler/MPI modules for project builds; Mason supplies editor services, not the cluster's MPI toolchain. Load the same project environment before configuring CMake and launching Neovim. Generate `compile_commands.json` on the cluster so clangd sees the actual include paths and flags. If a compiler wrapper still hides system headers, consult clangd's driver guidance rather than copying macOS include paths. [Lmod user guide](https://lmod.readthedocs.io/en/latest/010_user.html), [clangd compilation database](https://clangd.llvm.org/installation#compile_commandsjson), [clangd system headers](https://clangd.llvm.org/guides/system-headers).

## Bootstrap

The normal Linux bootstrap installs system packages using `sudo` and apt/dnf. Use the explicit cluster mode on Frontenac:

```sh
git clone https://github.com/AnthonyBotticchio/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./bootstrap.sh --cluster --backup
export PATH="$HOME/.local/bin:$PATH"
```

Run the bootstrap in the interactive compute shell described below. It:

- Checks for Git, Vim, tmux, curl, tar, gzip, unzip, Make, Perl, ripgrep (`rg`), Python 3, and a C compiler before changing files. Missing tools produce an actionable error; load the site's modules or install them in your account and retry.
- Reuses Stow on `PATH`, or builds GNU Stow 2.4.1 with a user-owned prefix and one Make job.
- Reuses Neovim 0.12+ and Tree-sitter CLI 0.26.1+, or installs official Linux release binaries under `~/.local/opt` with links in `~/.local/bin`. Automatic binary downloads support x86-64 and ARM64. Other architectures need compatible tools already on `PATH`.
- Links the existing `vim`, `nvim`, `tmux`, and `git` packages using the regular backup-aware installer.
- Runs `install-zsh.sh --cluster`: reuses Zsh or builds Zsh 5.9.2 under `~/.local`, then installs Oh My Zsh and Powerlevel10k and backs up and links `.zshrc` and `.p10k.zsh`. A source build needs `xz`, a C compiler, and ncurses development files from the site. [Official Zsh releases](https://www.zsh.org/pub/).

It does not need administrator privileges or change your login shell. Run `zsh` after setup; the linked `.zshrc` already adds `~/.local/bin` to `PATH`. Keep that directory on `PATH` in other shells too. Reload any required modules in future sessions. The script uses the current `HOME` for software and `DOTFILES_TARGET` (default `HOME`) for config links, matching `install.sh`.

The bootstrap downloads the latest stable Neovim and Tree-sitter binaries only when required; it does not pin those executable versions. Plugins use the existing `lazy-lock.json`. Official binary compatibility still depends on the node's architecture and system libraries; the script runs each downloaded executable before activating it. If it fails, use a compatible site module or a user-space source build. Stow is installed from the official GNU release. [Neovim installation](https://github.com/neovim/neovim/blob/master/INSTALL.md), [Tree-sitter installation](https://tree-sitter.github.io/tree-sitter/creating-parsers/1-getting-started.html), [GNU Stow](https://www.gnu.org/software/stow/).

For editor services, make `clangd` available on `PATH`; add `clang-format` for GLSL and `rustfmt` for Rust. Mason downloads the remaining configured servers. Python needs working pip and venv support for the CMake server. Node.js is not required by this configuration's selected plugins/servers, though individual projects may need it. Use `:checkhealth` after installation.

If downloads are restricted from compute nodes, follow CAC's supported transfer/install procedure. Existing installations can be reused without the bootstrap downloading anything. A fresh Neovim data directory still requires Lazy/plugin/server downloads and native builds; this script does not promise offline plugin setup. To link configs alone when Stow is already available:

```sh
./install.sh --dry-run vim nvim tmux git
./install.sh --backup vim nvim tmux git
```

## Frontenac workflow

From your laptop:

```sh
ssh YOUR_USERNAME@login.cac.queensu.ca
```

On the login node, inspect the available tools and start tmux. The module names below are searches, not claims that CAC provides these packages:

```sh
module spider neovim
module spider tmux
module spider ripgrep
module list
tmux new-session -A -s dev
```

Load the actual modules returned by the site. Inside tmux, request an interactive compute shell, for example:

```sh
srun --ntasks=1 --cpus-per-task=2 --mem=4G --time=01:00:00 --pty bash -l
hostname
module list
```

This is a sample resource request, not a verified account-specific allocation. Adjust memory/CPUs/time to the project and add `--account` if your allocation requires it. Frontenac 2.0 says partition and QoS selection are automatic based on the resource request; do not hard-code old partition names. `srun` creates an allocation when needed and runs the shell on the allocated node. [Frontenac 2.0 changes](https://cac.queensu.ca/frontenac2/), [Slurm srun](https://slurm.schedmd.com/srun.html).

In the compute shell, load the project/development modules, run the bootstrap once, then:

```sh
export PATH="$HOME/.local/bin:$PATH"
cd ~/git/dotfiles
nvim
```

Let the first plugin installation finish, check `:Lazy` and `:Mason`, and run `:checkhealth`. Restart Neovim if newly installed servers have not attached. Then work from the project's source root. Use `:Lazy restore` when restoring the committed plugin revisions; `:Lazy update` intentionally advances them. [Lazy commands](https://lazy.folke.io/usage).

Keep tmux on the login node and enter allocations from its panes. With this repo's keybindings, detach using **Ctrl-Space, d**, then reconnect with `tmux attach -t dev`. Tmux survives a dropped SSH connection, but does not extend a Slurm time limit, preserve a process through a node reboot, or migrate sessions between login nodes. Save before an allocation ends. [UCR tmux guidance](https://hpcc.ucr.edu/manuals/hpc_cluster/terminalide/).

For small login-node edits, `vim file` uses this repo's lightweight Vim configuration. `nvim -u NONE -i NONE file` starts Neovim without the plugin/LSP configuration. The regular `nvim` command retains the full shared configuration; the bootstrap adds no automatic login-node detection or alternate editor profile.

## Verification limits

The CAC public overview, Frontenac 2.0 notice, and acceptable-use policy were accessible. The detailed CAC software wiki could not be retrieved during this research, so exact module names, installed versions, current login-node limits, and outbound network access remain unverified. Other centres' guidance establishes that this workflow is common, not that their particular policies apply to Frontenac. Check the site's current wiki or CAC support when those details matter.

No SSH connection, cluster installation, or Slurm job was performed as part of this change. Local validation checks the bootstrap in temporary homes and verifies config linking without modifying the active home configuration.
