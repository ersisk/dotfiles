 rm -rf ~/workspace/dotfiles/.config/nvim-astrov4
 cp -r ~/.config/nvim/  ~/workspace/dotfiles/.config/nvim-astrov4
 cp -r ~/.config/sketchybar/  ~/workspace/dotfiles/.config/sketchybar/
 cp  ~/.zshrc  ~/workspace/dotfiles/.zshrc
 cp ~/.skhdrc ~/workspace/dotfiles/.skhdrc
 cp ~/.yabairc ~/workspace/dotfiles/.yabairc
 cp ~/.vimrc ~/workspace/dotfiles/.vimrc
 cp ~/.aws-fzf ~/workspace/dotfiles/.aws-fzf
 cp ~/.tmux.conf ~/workspace/dotfiles/.tmux.conf
 cp ~/.config/starship.toml ~/workspace/dotfiles/.config/starship.toml
 cp -r ~/.config/wezterm/ ~/workspace/dotfiles/.config/wezterm/
 cp -r ~/.config/envim/  ~/workspace/dotfiles/.config/nvim
 cp ~/.ideavimrc ~/workspace/dotfiles/.ideavimrc
 rm ~/workspace/dotfiles/Brewfile
 brew bundle dump --file=~/workspace/dotfiles/Brewfile
