setopt PROMPT_SUBST
autoload -U colors && colors

NEWLINE=$'\n'
RPROMPT='%F{190}[$(hostname)]%f'
PROMPT='%F{190}[%D{%I:%M}][%~] $(git_prompt_info)'"${NEWLINE}"'> %f'
