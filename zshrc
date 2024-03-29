export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="funky"


source $ZSH/oh-my-zsh.sh

plugins=(command-not-found)

job_info() {
  JOB_COUNT="$(jobs | wc -l | tr -d '[:blank:]')"
  if [ "$JOB_COUNT" = "0" ]
  then
    printf ''
  else
    printf ' (%s)' "$JOB_COUNT"
  fi
}


git_user() {
  user=$(git -C "$1" config user.name)
  author=$(git -C "$1" config duet.env.git-author-initials)
  committer=$(git -C "$1" config duet.env.git-committer-initials)

  if [ -n "${committer}" ]; then
    echo "${author} & ${committer}%{$fg[blue]%}@%{$reset_color%}"
  elif [ -n "${author}" ]; then
    echo "${author}%{$fg[blue]%}@%{$reset_color%}"
  elif [ -z $user ]; then
    echo "%{$fg_bold[red]%}no user%{$fg[blue]%}@%{$reset_color%}"
  else
    echo "$user%{$fg[blue]%}@%{$reset_color%}"
  fi
}

git_root() {
  local folder='.'
  for i in $(seq 0 $(pwd|tr -cd '/'|wc -c)); do
    [ -d "$folder/.git" ] && echo "$folder" && return
    folder="../$folder"
  done
}

git_branch() {
  local git_root="$1"
  local line="$2"
  local branch="???"
  local ahead=''
  local behind=''

  case "$line" in
    \#\#\ HEAD*)
      branch="$(git -C "$git_root" tag --points-at HEAD)"
      [ -z "$branch" ] && branch="$(git -C "$git_root" rev-parse --short HEAD)"
      branch="%{$fg[yellow]%}${branch}%{$reset_color%}"
      ;;
    *)
      branch="${line#\#\# }"
      branch="%{$fg[green]%}${branch%%...*}%{$reset_color%}"
      ahead="$(echo $line | sed -En -e 's|^.*(\[ahead ([[:digit:]]+)).*\]$|\2|p')"
      behind="$(echo $line | sed -En -e 's|^.*(\[.*behind ([[:digit:]]+)).*\]$|\2|p')"
      [ -n "$ahead" ] && ahead="%{$fg_bold[white]%}↑%{$reset_color%}$ahead"
      [ -n "$behind" ] && behind="%{$fg_bold[white]%}↓%{$reset_color%}$behind"
      ;;
  esac

  print "${branch}${ahead}${behind}"
}

git_status() {
  local untracked=0
  local modified=0
  local deleted=0
  local staged=0
  local branch=''
  local output=''

  for line in "${(@f)$(git -C "$1" status --porcelain -b 2>/dev/null)}"
  do
    case "$line" in
      \#\#*) branch="$(git_branch "$1" "$line")" ;;
      \?\?*) ((untracked++)) ;;
      U?*|?U*|DD*|AA*|\ M*|\ D*) ((modified++)) ;;
      ?M*|?D*) ((modified++)); ((staged++)) ;;
      ??*) ((staged++)) ;;
    esac
  done

  output="$branch"

  [ $staged -gt 0 ] && output="${output} %{$fg_bold[green]%}Staged%{$fg_no_bold[white]%}=%{$reset_color$fg[green]%}$staged%{$reset_color%}"
  [ $modified -gt 0 ] && output="${output} %{$fg_bold[yellow]%}Modified%{$fg_no_bold[white]%}=%{$reset_color$fg[yellow]%}$modified%{$reset_color%}"
  [ $deleted -gt 0 ] && output="${output} %{$fg_bold[yellow]%}Deleted%{$fg_no_bold[white]%}=%{$reset_color$fg[yellow]%}$deleted%{$reset_color%}"
  [ $untracked -gt 0 ] && output="${output} %{$fg_bold[yellow]%}Untracked%{$fg_no_bold[white]%}=%{$reset_color$fg[yellow]%}$untracked%{$reset_color%}"

  echo "$output"
}

git_prompt_info() {
  local GIT_ROOT="$(git_root)"
  [ -z "$GIT_ROOT" ] && return

  print " $(git_user "$GIT_ROOT")$(git_status "$GIT_ROOT") "
}

simple_git_prompt_info() {
  ref=$($(which git) symbolic-ref HEAD 2> /dev/null) || return
  user=$($(which git) config user.name 2> /dev/null)
  echo " (${user}@${ref#refs/heads/})"
}

autoload -U colors && colors

# export PROMPT='$fg_bold[green]%}%n@%{$fg_bold[green]%}%m:%{$fg_bold[blue]%}%~%{$fg_bold[green]%}$(git_prompt_info)%{$reset_color%}%#%{$fg_bold[gray]%}$(job_info)%{$reset_color%} '

source ~/.ralias

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/admin/.local/bin

test -e $HOME/.nvm/nvm.sh && . $HOME/.nvm/nvm.sh

export PATH="/usr/local/share/npm/bin:$PATH"
export PATH="/usr/local/ruby/bin:$PATH"
export PATH="$PATH:/usr/local/pear/bin"
export PATH="$PATH:$HOME/bt/dotfiles/bin"
export PATH="$PATH:$HOME/bt/system-scripts/bin"
export PATH="$PATH:/opt/elixir/current/bin"
export PATH="$PATH:/usr/local/Cellar/python/2.7.2/bin"
export PATH="$PATH:$HOME/bazel/output"
export PATH="$PATH:$HOME/.local/bin"  # for pip install --user

alias redshift="bt-psql-redshift"
alias rs_csv="$HOME/bt/team-data/.venv/bin/python $HOME/bt/team-data/legacy/ops_data/python_scripts/rs_csv.py"
