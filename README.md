# zsh-ancient

A rich zsh configuration with **zero external dependencies**. Only requires zsh 4.3.11+ — tested to work on systems as old as CentOS 6 (glibc 2.12).

## Features

- **Pure zsh prompt** with git branch and dirty indicator
- **Comprehensive completion** with case-insensitive matching and colored output
- **History sharing** across terminals with incremental pattern search
- **Graceful degradation** — automatically uses fzf for Ctrl+R if available, otherwise falls back to built-in search
- **`~/.zshrc.local` loaded twice** — early (for PATH) and late (for overrides)

## Requirements

- zsh 4.3.11+
- That's it. No plugin manager, no Rust toolchain, no modern glibc.

## Installation

```bash
# Clone
git clone https://github.com/hangnality/zsh-ancient.git ~/.zsh-ancient

# Symlink
ln -sf ~/.zsh-ancient/zshrc ~/.zshrc

# (Optional) machine-specific config
echo 'export PATH="$HOME/.local/bin:$PATH"' > ~/.zshrc.local
```

## Optional: install modern CLI tools

The included `install_tools.sh` downloads **static/musl-linked binaries** that run on any Linux x86_64 system regardless of glibc version:

| Tool                                             | Version | Description                  |
| ------------------------------------------------ | ------- | ---------------------------- |
| [fzf](https://github.com/junegunn/fzf)           | 0.74.0  | Fuzzy finder (Go, static)    |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | 15.1.0  | Fast grep (Rust, musl)       |
| [fd](https://github.com/sharkdp/fd)              | 10.4.2  | Fast find (Rust, musl)       |
| [delta](https://github.com/dandavison/delta)     | 0.19.2  | Better git diff (Rust, musl) |

```bash
# Install to ~/.local/bin (default)
./install_tools.sh

# Or specify a custom path
./install_tools.sh ~/bin
```

Make sure the install directory is in your PATH (add to `~/.zshrc.local`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Optional: build from source (vim, tmux)

For tools that don't ship static binaries, `install_build.sh` compiles them from source into `~/.local`. It also builds their dependencies (ncurses, libevent) locally — no root or system package manager needed.

| Tool     | Version | Notes                       |
| -------- | ------- | --------------------------- |
| ncurses  | 6.6     | Dependency for tmux and vim |
| libevent | 2.0.22  | Dependency for tmux         |
| tmux     | 3.7b    |                             |
| vim      | 9.2.0782 | `--with-features=huge`      |

```bash
# Build everything into ~/.local (requires gcc + make)
./install_build.sh

# Or specify a custom prefix
./install_build.sh /opt/mytools
```

Add to `~/.zshrc.local`:

```bash
export PATH="$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:${LD_LIBRARY_PATH:-}"
```

## File structure

```
.
├── zshrc              # Main zsh config — symlink to ~/.zshrc
├── install_tools.sh   # Static binary installer (fzf, ripgrep, fd, delta)
├── install_build.sh   # Source build installer (vim, tmux, git)
└── README.md
```

## Customization

Create `~/.zshrc.local` for machine-specific settings. It is sourced both at the beginning and end of `zshrc`:

- **Early load**: PATH additions are visible to the rest of the config (e.g., fzf detection)
- **Late load**: aliases and keybindings override anything set in the main config

## License

MIT
