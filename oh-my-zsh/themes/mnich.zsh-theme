# Comment
setopt PROMPT_SUBST
NEWLINE=$'\n'
RPROMPT='%{$fg[yellow]%}[$(hostnamectl hostname)]%{$reset_color%}'
PROMPT='%{$fg[yellow]%}[%D{%I:%M}][%~] $(git_prompt_info) ${NEWLINE}> %{$reset_color%}'
