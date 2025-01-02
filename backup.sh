 rm -rf ~/workspace/dotfiles/.config/nvim-astrov4
 cp -r ~/.config/nvim/  ~/workspace/dotfiles/.config/nvim-astrov4
 cp  ~/.zshrc  ~/workspace/dotfiles/.zshrc
 cp ~/.vimrc ~/workspace/dotfiles/.vimrc
 cp ~/.tmux.conf ~/workspace/dotfiles/.tmux.conf
 cp ~/.config/starship.toml ~/workspace/dotfiles/.config/starship.toml
 cp -r ~/.config/wezterm/ ~/workspace/dotfiles/.config/wezterm/
 cp -r ~/.config/ghostty/ ~/workspace/dotfiles/.config/ghostty/
 cp -r ~/.config/yazi/  ~/workspace/dotfiles/.config/yazi
 cp -r ~/.config/zed/  ~/workspace/dotfiles/.config/zed
 cp ~/.ideavimrc ~/workspace/dotfiles/.ideavimrc
 rm ~/workspace/dotfiles/Brewfile
 brew bundle dump --file=~/workspace/dotfiles/Brewfile
