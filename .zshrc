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

keepass-office() {
  keepass ~/Dropbox/Aplicativos/KeeWeb/gokei-password-db.kdbx -k ~/Documents/gokei-password-db.key "$@" < <(echo $KEEPASSCLI_PASSWORD)
}

keepass() {
  zparseopts -E -D -- \
    k:=O_KEYFILE \
    a+:=O_ATTRIBUTE

  VAULT_FILE=$1
  KEY_FILE=${O_KEYFILE[2]}
  COMMAND=$2
  ENTRY_TITLE=$3

  # INFO: `/usr/bin/cat` used absoulute path to avoid use of `bat`
  [ $# -lt 2 ] && print-keepass-usage > /dev/stderr

  shift $#

  PASSWORD=$(/usr/bin/cat /dev/stdin > /dev/stdout)

  if [ -z "$PASSWORD" ]; then
    prompt-password $VAULT_FILE | read PASSWORD
  fi

  check-keepass-password $VAULT_FILE $KEY $PASSWORD || return 1

  keepassxc-cli $COMMAND $VAULT_FILE -k $KEY_FILE ${O_ATTRIBUTE[@]} $ENTRY_TITLE < <(echo $PASSWORD) 2> /dev/null || return 1
}

print-keepass-usage() {
  /usr/bin/cat <<- 'EOL'
		Usage: keepass <database> <command> [<entry>] [options]
		KeePassXC custum wrapper
		
		Tested commands:
		  ls	List entries
		  show	Show an entry's information
		
		Arguments:
		  database	Database file path
		  command	Name of the command to execute

		Notes:
		  You can set the password by stdin

EOL
}

prompt-password() {
  echo "Enter password to unlock: $VAULT_FILE:" > /dev/stderr
  gum input --password | read PASSWORD

  echo $PASSWORD
}

check-keepass-password() {
  DATABASE=$1
  KEY=$2
  PASSWORD=$3

  test-keepass-password $DATABASE $KEY $PASSWORD || \
    error-message Wrong password
}

test-keepass-password() {
  DATABASE=$1
  KEY=$2
  PASSWORD=$3

  keepassxc-cli db-info $DATABASE -k $KEY > /dev/null 2>&1 < <( echo $PASSWORD ) || return 1
}

error-message() {
  echo "$@" > /dev/stderr
  return 1
}

check-openfortivpn-password() {
  echo -n 'Was Set: '
  [ -n "$OPENFORTIVPN_PASSWORD" ] && \
    echo '✅' || echo '❌'
}

set-openfortivpn-password() {
  export OPENFORTIVPN_PASSWORD=`gum input --password`
}

# TODO: Refactor it
# SSH Connection
# ===

connect-ssh() {
  zparseopts -E -D -- \
    -target:=O_TARGET

  TARGET=${O_TARGET[2]}

  case "${TARGET}" in
    'bmp-274-hml')
      exec-ssh-with-sshpass-fetching-keepass-target \
        --sshpass-environment SSHPASS_10_204_205_15 \
        --target bmp-274-hml \
        charles.sena@10.204.205.15 "$@"
      ;;

    'bmp-274-prd')
      exec-ssh-with-sshpass-fetching-keepass-target \
        --sshpass-environment SSHPASS_10_204_206_2 \
        --target bmp-274-prd \
        charles.sena@10.204.206.2 "$@"
      ;;

    'bmp-531-prd')
      exec-ssh-with-sshpass-fetching-keepass-target \
        --sshpass-environment SSHPASS_10_204_151_2 \
        --target bmp-531-prd \
        charles.sena@10.204.151.2 "$@"
      ;;

    'our-prd')
      exec-ssh-with-sshpass-fetching-keepass-target \
        --sshpass-environment SSHPASS_10_204_155_2 \
        --target our-prd \
        charles.sena@10.204.155.2 "$@"
      ;;

    *)
      echo 'Invalid target' > /dev/stderr
      return 1
      ;;
  esac
}

exec-ssh-with-sshpass-fetching-keepass-target() {
  zparseopts -E -D -- \
    -sshpass-environment:=OPTION_SSHPASS_ENVIRONMENT \
    -target:=OPTION_TARGET

  TARGET=${OPTION_TARGET[2]}
  ENVIRONMENT=${OPTION_SSHPASS_ENVIRONMENT[2]:-SSHPASS}
  SSH_DEST=$1; shift

  if [ -z "${(P)ENVIRONMENT}" ]; then
    echo "\"$ENVIRONMENT\" wasn't set, trying to export..." > /dev/stderr
    set-sshpass-environment --target $TARGET
  fi

  sshpass -e$ENVIRONMENT ssh $SSH_DEST "$@" 

}

mount-ssh() {
  zparseopts -E -D -- \
    -target:=TARGET

  
  case ${TARGET[2]} in
    bmp-274-hml)
      if [ -z "$SSHPASS_10_204_205_15" ];then
        "\"SSHPASS_10_204_204_15\" variable wasn't set, trying to export..."
        set-sshpass-environment --target bmp-274-hml
      fi

      REMOTE_PATH='charles.sena@10.204.205.15:/var/www'
      LOCAL_PATH="$HOME/.local/mnt/10.204.205.15/"

      sshfs $REMOTE_PATH $LOCAL_PATH -o allow_other -o password_stdin \
        < <(echo $SSHPASS_10_204_205_15) \
        && echo "🗀 \"$REMOTE_PATH\" was mount at \"$LOCAL_PATH\"" \
        || echo "✖️ Something goes wrong trying to mount \"$REMOTE_PATH\" at \"$LOCAL_PATH\""

      ;;

    bmp-274-prd)
      if [ -z "$SSHPASS_10_204_206_2" ];then
        "\"SSHPASS_10_204_206_2\" variable wasn't set, trying to export..."
        set-sshpass-environment --target ${TARGET[2]}
      fi

      REMOTE_PATH='charles.sena@10.204.206.2:/var/www'
      LOCAL_PATH="$HOME/.local/mnt/10.204.206.2/"

      sshfs $REMOTE_PATH $LOCAL_PATH -o allow_other -o password_stdin \
        < <(echo $SSHPASS_10_204_206_2) \
        && echo "🗀 \"$REMOTE_PATH\" was mount at \"$LOCAL_PATH\"" \
        || echo "✖️ Something goes wrong trying to mount \"$REMOTE_PATH\" at \"$LOCAL_PATH\""

      ;;
    
    bmp-531-prd)
      if [ -z "$SSHPASS_10_204_151_2" ];then
        "\"SSHPASS_10_204_151_2\" variable wasn't set, trying to export..."
        set-sshpass-environment --target bmp-531-prd
      fi

      REMOTE_PATH='charles.sena@10.204.151.2:/var/www'
      LOCAL_PATH="$HOME/.local/mnt/10.204.151.2/"

      sshfs $REMOTE_PATH $LOCAL_PATH -o allow_other -o password_stdin \
        < <(echo $SSHPASS_10_204_151_2) \
        && echo "🗀 \"$REMOTE_PATH\" was mount at \"$LOCAL_PATH\"" \
        || echo "✖️ Something goes wrong trying to mount \"$REMOTE_PATH\" at \"$LOCAL_PATH\""

      ;;

    *)
      echo "Unknown target"
      ;;
  esac

}

set-sshpass-environment() {
  zparseopts -E -D -- \
    -target:=TARGET

  case "${TARGET[2]}" in
    bmp-274-hml)
      set-sshpass-environment-bmp-274-hml
      ;;

    bmp-274-prd)
      set-sshpass-environment-bmp-274-prd
      ;;

    bmp-531-prd)
      set-sshpass-environment-bmp-531-prd
      ;;

    our-prd)
      set-sshpass-environment-our-prd
      ;;

    *)
      echo "set-sshpass-environment: Invalid target" > /dev/stderr
      return 1
      ;;
  esac
}

set-sshpass-environment-bmp-274-hml() {

  KEEPASS_ENTRY_NAME='Bmp SCM Cabine 01 (Hml)'
  SSHPASS_ENVIRONMENT_NAME=SSHPASS_10_204_205_15

  fetch-keepass-entry-password --entryname $KEEPASS_ENTRY_NAME | read $SSHPASS_ENVIRONMENT_NAME

  export $SSHPASS_ENVIRONMENT_NAME \
    && echo "✅ The \"$KEEPASS_ENTRY_NAME\" password was exported into \"$SSHPASS_ENVIRONMENT_NAME\""
}

set-sshpass-environment-bmp-274-prd() {

  KEEPASS_ENTRY_NAME='Cabine bmp ssh scm'
  SSHPASS_ENVIRONMENT_NAME=SSHPASS_10_204_206_2

  fetch-keepass-entry-password --entryname $KEEPASS_ENTRY_NAME | read $SSHPASS_ENVIRONMENT_NAME

  export $SSHPASS_ENVIRONMENT_NAME \
    && echo "✅ The \"$KEEPASS_ENTRY_NAME\" password was exported into \"$SSHPASS_ENVIRONMENT_NAME\""
}

set-sshpass-environment-bmp-531-prd() {

  KEEPASS_ENTRY_NAME='Cabine bmp ssh (531)'
  SSHPASS_ENVIRONMENT_NAME=SSHPASS_10_204_151_2

  fetch-keepass-entry-password --entryname $KEEPASS_ENTRY_NAME | read $SSHPASS_ENVIRONMENT_NAME

  export $SSHPASS_ENVIRONMENT_NAME \
    && echo "✅ The \"$KEEPASS_ENTRY_NAME\" password was exported into \"$SSHPASS_ENVIRONMENT_NAME\""
}

set-sshpass-environment-our-prd() {

  KEEPASS_ENTRY_NAME='Cabine Ourinvest usuário SSH'
  SSHPASS_ENVIRONMENT_NAME=SSHPASS_10_204_155_2

  fetch-keepass-entry-password --entryname $KEEPASS_ENTRY_NAME | read $SSHPASS_ENVIRONMENT_NAME

  export $SSHPASS_ENVIRONMENT_NAME \
    && echo "✅ The \"$KEEPASS_ENTRY_NAME\" password was exported into \"$SSHPASS_ENVIRONMENT_NAME\""
}

fetch-keepass-entry-password() {
  zparseopts -E -D -- \
    -entryname:=ENTRY_NAME

  keepassxc-cli \
    show ~/Dropbox/Aplicativos/KeeWeb/gokei-password-db.kdbx ${ENTRY_NAME[2]} \
    -a password \
    -k ~/Documents/gokei-password-db.key \
    < <(echo $KEEPASSCLI_PASSWORD) \
    | read PASSWORD \
    && echo "✅ Keepass entry \"${ENTRY_NAME[2]}\" was fetched successfully" > /dev/stderr \
    || echo "✖️ Something go wrong trying to fetch the Keepass \"${ENTRY_NAME[2]}\" entry" > /dev/stderr

  echo $PASSWORD > /dev/stdout
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
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add ~/.ssh/gk_key_prd > /dev/null 2>&1
  ssh-add ~/.ssh/gk_key_hml > /dev/null 2>&1
fi

