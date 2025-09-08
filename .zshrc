# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export ENABLE_RUST_TOOLS=1
export ORIGIN_LS=`which ls`
export ORIGIN_CAT=`which cat`

f-ls() {
  [[ $ENABLE_RUST_TOOLS -gt 0 ]] && exa --icons "$@" || $ORIGIN_LS "$@";
}

f-cat() {
  [[ $ENABLE_RUST_TOOLS -gt 0 ]] && bat --style=auto "$@" || $ORIGIN_CAT "$@";
}

alias ls='f-ls'
alias cat='f-cat'

