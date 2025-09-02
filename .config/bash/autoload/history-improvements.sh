export HISTCONTROL=ignoreboth:ignoredups

shopt -s histappend

PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

