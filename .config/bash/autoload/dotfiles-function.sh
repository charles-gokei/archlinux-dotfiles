function dotfiles {
  git_dir=$DOTFILES_GIT_DIR

  if [ -d ${git_dir} ]; then
    git --git-dir=${git_dir} --work-tree=$HOME $@
  else
    return 1
  fi
}

export -f dotfiles

