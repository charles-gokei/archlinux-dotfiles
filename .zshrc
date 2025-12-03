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
  [[ $ENABLE_RUST_TOOLS -gt 0 ]] && exa --icons --group-directories-first "$@" || $ORIGIN_LS "$@";
}

f-cat() {
  [[ $ENABLE_RUST_TOOLS -gt 0 ]] && bat --style=auto "$@" || $ORIGIN_CAT "$@";
}

alias ls='f-ls'
alias cat='f-cat'

[[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]] || eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
alias {vi,vim}=nvim

export DOTFILES_GIT_DIR=$HOME/.dotfiles/

dotfiles() {
  git_dir=$DOTFILES_GIT_DIR

  [[ ! -d ${git_dir} ]] && return 1 || git --git-dir=${git_dir} --work-tree=$HOME "$@"
}

check-inco-prd-password() {
  echo Was set; [[ -z $SSHPASS_10_204_203_2 ]] && echo ❌ || echo ✅
}

set-inco-prd-password() {
  export SSHPASS_10_204_203_2=`gum input --password`
}

connect-inco-prd-ssh() {
  sshpass -eSSHPASS_10_204_203_2 ssh -o ConnectTimeout=10 -i ~/.ssh/gk_key_prd charles.sena@10.204.203.2 || echo ❌ Connection has failed
}

check-openfortivpn-password() {
  echo -n 'Was Set: '
  [ -n "$OPENFORTIVPN_PASSWORD" ] && \
    echo '✅' || echo '❌'
}

set-openfortivpn-password() {
  export OPENFORTIVPN_PASSWORD=`gum input --password`
}

connect-openfortivpn() {
  sudo nohup openfortivpn 177.185.15.35:11043 \
    -ugk.charles.sena \
    --trusted-cert 2184f0861006ab3bbf61bddb9cb2121c887c92e39d34f55fc1e81675e0bca9a1 \
    < <( echo $OPENFORTIVPN_PASSWORD ) \
    >> ~/.local/log/openfortivpn.log &

  TMP_DIR=~/.local/var/tmp/connect-openfortivpn/

  [ ! -d $TMP_DIR ] && mkdir $TMP_DIR

  echo $! > $TMP_DIR/pid
}

disconnect-openfortivpn() { 
  CONNECT_OPENFORTIVPN_TMP=~/.local/var/tmp/connect-openfortivpn/
  PID_PATH=$CONNECT_OPENFORTIVPN_TMP/pid

  [ -f $PID_PATH ] && kill -s term `cat $PID_PATH`
  [ $? -lt 1 ] && rm $PID_PATH || return 1

  echo ✅ Openforti Disconected
}


# TODO: Add docker isolation on test case description

###
# Test Case
# ---
# 
# ### 📐 Setup before Case
# 1. exec `source ~/.zshrc`
# 2. setup the password with `set-inco-prd-password`
# 3. exec `[ -z "`ls ~/.local/mnt/10-204-203-2`" ] && fusermount3 -u ~/.local/mnt/10-204-203-2`
# 4. exec `set-openfortivpn-password`
# 5. exec `connect-openfortivpn`
#
# ### 💣 Tear Down
# 1. exec `[ -n "`ls ~/.local/mnt/10-204-203-2`" ] && fusermount3 -u ~/.local/mnt/10-204-203-2`
#
# ### 💣 Tear Down after Case
# 1. exec `unset SSHPASS_10_204_203_2`
# 2. exec `[ -n "$(ls ~/.local/mnt/10-204-203-2)" ] && fusermount3 -u ~/.local/mnt/10-204-203-2`
# 3. exec `unset OPENFORTIVPN_PASSWORD`
# 4. exec `disconnect-openfortivpn`
#
# ### WIP - Test inco connection failure message
# #### Arrange:
#
# #### Act:
# 1. exec `connect-inco-prd-ssh`                                                                                                                                                                            08:43:01
#
# #### Assert:
# 1. Assert the first output was `❌ Connection has failed: Password is not set`
#
# ### 🧪 Test Can mount folder
#
# #### Arrange:
# 1. exec mount-inco-prd-www-folder
#
# #### Act:
# 1. exec `[ -z " `ls ~/.local/mnt/10-204-203-2`"  ] && echo ❌ Empty || echo ✅ Not empty`
#
# #### Assert:
# 1. assert the first output was : `✅ Inco www folder mounted at /home/charles/.local/mnt/10-204-203-2`
# 2. assert the second output is '✅ Not empty' and not '❌ Empty'
#
# ### 🧪 Test Can Umount folder
#
# #### Arrange:
# 1. exec mount-inco-prd-www-folder
# 2. exec umount-inco-prd-www-folder
#
# #### Act:
# 1. exec `[ -z "`ls ~/.local/mnt/10-204-203-2`" ] && echo ✅ Empty || echo ❌ Not empty`
#
# ### Assert:
# 1. assert the first output was `✅ Inco www folder mounted at /home/charles/.local/mnt/10-204-203-2`
# 2. assert the second output was `✅ /home/charles/.local/mnt/10-204-203-2 was succesfully umounted`
# 1. assert the last output is '✅ Empty' and not '❌ Not empty'
#
##

export INCO_PRD_MOUNT_POINT=~/.local/mnt/10-204-203-2

mount-inco-prd-www-folder() {
  MOUNT_POINT=$INCO_PRD_MOUNT_POINT
  
  timeout 4s \
    sshfs charles.sena@10.204.203.2:/var/www $INCO_PRD_MOUNT_POINT \
    -o allow_other \
    -o IdentityFile=$HOME/.ssh/gk_key_prd \
    -o password_stdin < <( echo $SSHPASS_10_204_203_2 ) && \
    echo ✅ Inco www folder mounted at $INCO_PRD_MOUNT_POINT || \
    echo ❌ mount was failed && return 1

}

umount-inco-prd-www-folder() {
  MOUNT_POINT=$INCO_PRD_MOUNT_POINT

  fusermount3 -u $INCO_PRD_MOUNT_POINT && \
    echo ✅ $INCO_PRD_MOUNT_POINT was succesfully umounted || \
    echo ❌ Umount process was failed && return 1
}

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

export MISE_SHELL=zsh
export __MISE_ORIG_PATH="$PATH"

mise() {
  local command
  command="${1:-}"
  if [ "$#" = 0 ]; then
    command mise
    return
  fi
  shift

  case "$command" in
  deactivate|shell|sh)
    # if argv doesn't contains -h,--help
    if [[ ! " $@ " =~ " --help " ]] && [[ ! " $@ " =~ " -h " ]]; then
      eval "$(command mise "$command" "$@")"
      return $?
    fi
    ;;
  esac
  command mise "$command" "$@"
}

_mise_hook() {
  eval "$(mise hook-env -s zsh)";
}
typeset -ag precmd_functions;
if [[ -z "${precmd_functions[(r)_mise_hook]+1}" ]]; then
  precmd_functions=( _mise_hook ${precmd_functions[@]} )
fi
typeset -ag chpwd_functions;
if [[ -z "${chpwd_functions[(r)_mise_hook]+1}" ]]; then
  chpwd_functions=( _mise_hook ${chpwd_functions[@]} )
fi

_mise_hook
if [ -z "${_mise_cmd_not_found:-}" ]; then
    _mise_cmd_not_found=1
    [ -n "$(declare -f command_not_found_handler)" ] && eval "${$(declare -f command_not_found_handler)/command_not_found_handler/_command_not_found_handler}"

    function command_not_found_handler() {
        if [[ "$1" != "mise" && "$1" != "mise-"* ]] && mise hook-not-found -s zsh -- "$1"; then
          _mise_hook
          "$@"
        elif [ -n "$(declare -f _command_not_found_handler)" ]; then
            _command_not_found_handler "$@"
        else
            echo "zsh: command not found: $1" >&2
            return 127
        fi
    }
fi

export PATH="/home/charles/.local/bin:$PATH"

if [[ -z "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent -s)"
fi

