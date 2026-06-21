#!/bin/bash

set -euo pipefail

dotfiles_dir=$(cd "$(dirname "$0")"; pwd)
mkdir -p "${HOME}/.config/nvim"

if ! vim --version | grep -q '2nd user vimrc file'; then
  for name in vim vimrc vimrc.bundles; do
    rm -rf "${HOME}/.${name}"
    ln -s "${dotfiles_dir}/${name}" "${HOME}/.${name}"
  done
fi
for name in config/nvim/init.lua; do
  rm -rf "${HOME}/.${name}"
  ln -s "${dotfiles_dir}/${name}" "${HOME}/.${name}"
done

nvim +PlugInstall +PlugUpdate2 +PlugClean! +qall

# clone the repo https://github.com/Mofiqul/vscode.nvim
# and run the command `:VscodeInstall` in nvim to install the vscode.nvim plugin

git clone https://github.com/Mofiqul/vscode.nvim.git "${HOME}/.config/nvim/pack/plugins/start/vscode.nvim"

