# Example functions that can be used with zsh

function cd () { builtin cd $*; ~/bin/log_cwd.rb }

function f () {
  if [[ $# -eq 1 ]]; then
    cd "$(cwd_frequency.rb $1)"
  else
    cwd_frequency.rb
  fi
}

function r () {
  if [[ $# -eq 1 ]]; then
    cd "$(cwd_recently.rb $1)"
  else
    cwd_recently.rb
  fi
}