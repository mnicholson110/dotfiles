setopt PROMPT_SUBST
autoload -U colors && colors

NEWLINE=$'\n'
PROMPT='%F{190}[$(cat /etc/hostname)][%~] $(git_prompt_info)'"${NEWLINE}"'> %f'
