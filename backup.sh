 rm -rf ~/workspace/personal/dotfiles/.config/nvim/lua/user
 rm -rf ~/workspace/personal/dotfiles/.config/nvim-not-distro
 rm -rf ~/workspace/personal/dotfiles/.config/astrov4
 rm -rf ~/workspace/personal/dotfiles/.config/nvim
 cp -r ~/.config/nvim/  ~/workspace/personal/dotfiles/.config/nvim-astrov4
 cp -r ~/.config/sketchybar/  ~/workspace/personal/dotfiles/.config/sketchybar/
 cp  ~/.zshrc  ~/workspace/personal/dotfiles/.zshrc
 cp ~/.skhdrc ~/workspace/personal/dotfiles/.skhdrc
 cp ~/.yabairc ~/workspace/personal/dotfiles/.yabairc
 cp ~/.vimrc ~/workspace/personal/dotfiles/.vimrc
 cp ~/.aws-fzf ~/workspace/personal/dotfiles/.aws-fzf
 cp ~/.tmux.conf ~/workspace/personal/dotfiles/.tmux.conf
 cp ~/.config/starship.toml ~/workspace/personal/dotfiles/.config/starship.toml
 cp -r ~/.config/wezterm/ ~/workspace/personal/dotfiles/.config/wezterm/
 cp -r ~/.config/envim/  ~/workspace/personal/dotfiles/.config/nvim
 cp ~/.ideavimrc ~/workspace/personal/dotfiles/.ideavimrc
 rm ~/workspace/personal/dotfiles/Brewfile
 brew bundle dump --file=~/workspace/personal/dotfiles/Brewfile
