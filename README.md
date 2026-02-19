# Erşan Işık's Dotfiles

This is the home of all my dotfiles. These are files that add custom configurations to my computer and applications, primarily the terminal.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

## How to install

My dotfiles are managed by [GNU Stow](https://www.gnu.org/software/stow/).

1. Install [homebrew](https://brew.sh/)
2. Install [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow`)
3. Clone this repository
4. Run stow command

```sh
stow . -t ~
```

# Software

- Terminal: [wezterm](https://wezfurlong.org/wezterm/index.html)
- Font: [JetbrainsMono Nerd Font](https://www.jetbrains.com/lp/mono/)
- Colors: [kanagawa](https://github.com/rebelot/kanagawa.nvim)
- Shell: [fish](https://fishshell.com/)
- Multiplexer: [tmux](https://github.com/tmux/tmux/wiki)
- Editor: [Neovim](https://neovim.io)
- Editor Config: [AstroNvim](https://astronvim.github.io/)
- Git: [lazygit](https://github.com/jesseduffield/lazygit)
- macOS package manager: [Homebrew](https://brew.sh)
- npm package manager: [pnpm](https://pnpm.io/)
