# ================================================
# G ==============================================
# ================================================

# ------------------------------------------------
# GLOBALS ----------------------------------------
# ------------------------------------------------
_matches=()
_bodies=()
_commands_length=0

# ------------------------------------------------
# CONFIG->ZSH ------------------------------------
# ------------------------------------------------

# Ensure compinit
autoload -U compinit
compinit

# Completion rules
compdef g=git
compctl -k "(ls lso lsd d cm cmp cpdm d s p)" g # FIX: compdef overrides these

# Append g auxiliary scripts to $PATH
export PATH=$PATH:$HOME/.g/bin

# Change working directory Zsh rule
chpwd()
{
  if [[ `uname` == "Darwin" ]] ; then
    ls -lh -G
  else
    ls -lh --color
  fi

  if ( `pwd-is-git-repo --root` ) ; then
    _git_status_display
  fi
  
  if ( `pwd-is-git-repo --root` ) ; then
    echo -e "\033[30;1mpwd:\033[0m \033[33;2m"`pwd-tilde`
  fi
}

# ------------------------------------------------
# COMMANDS ---------------------------------------
# ------------------------------------------------
function _define_command()
{
  # Push the match and body for that match
  _matches+=($1)
  shift
  _bodies+=($*)

  let "_commands_length += 1"
}

function _find_command()
{
  _find_match=$1

  for (( index = 0 ; index < $_commands_length ; index++)) ; do
    if [[ $_find_match == $_matches[$index] ]] ; then
      echo $_bodies[$index]
      return 0
    fi
  done

  return 1
}

# ------------------------------------------------
# DEFINE->HELPERS --------------------------------
# ------------------------------------------------
function _git_status_display()
{
  # FIX: this says that the dir is clean when we deleted some files and when we git-mv files. probably more
  git_count_untracked=`git-count-untracked`
  git_count_diff=`git diff | wc -l | awk '{print $1}'`
  git_count_branches=`git branch | wc -l | awk '{print $1}'`
  git_branch_current=`git-branch-current`

  # git:
  echo -en "\033[30;1mgit:\033[0m "

  # branch
  echo -e "branch:    \033[37;1m"$git_branch_current"\033[0m("$git_count_branches")"

  # status
  echo -en "     \033[37;mstatus:\033[0m    "
  if [[ $git_count_untracked == 0 && $git_count_diff == 0 ]] ; then
    echo -e "\033[32;1mclean\033[0m "
  else
    echo -e "\033[31;1munclean\033[0m "
  fi

  # diff
  echo -e "     \033[37;mdiff:\033[0m     \033[37;1m"`git diff --shortstat`"\033[0m"
  git diff --numstat | sed "s/^/                /"

  # untracked
  echo -e "     \033[37;muntracked:\033[0m \033[37;1m"$git_count_untracked"\033[0m"
  g lso | sed "s/^/                /"
}

function _git_all_tracked_or_prompt()
{
  g_lso=`git ls-files --other --exclude-standard`

  if [[ -n $g_lso ]] ; then
    echo $g_lso
    echo -en "\033[32;1mAdd these files to be tracked (y/n)?\033[0m "
    read add_files

    if [[ $add_files == "y" ]] ; then
      git add .
    fi
  fi
}

# ------------------------------------------------
# DEFINE->COMMANDS->ALIASES ----------------------
# ------------------------------------------------
_define_command g   "git grep \$*"
_define_command l   "git log \$*"
_define_command ls  "git ls-files \$*"

# ------------------------------------------------
# DEFINE->COMMANDS->SPECIAL ----------------------
# ------------------------------------------------

# c: Git Command
# ------------------------------------------------
# Run a command and commit with the message of the command.
function _git_command()
{
  initial_arguments=$*

  # Execute all the arguments
  $*

  # Command was successful; Continue
  if [[ $? == 0 ]] ; then

    _git_all_tracked_or_prompt

    git commit --all -m $initial_arguments

  # Command failed
  else
    echo "fatal: Command failed. Not commiting."
    return 1
  fi
}

# ------------------------------------------------
# HELP -------------------------------------------
# ------------------------------------------------
function _usage()
{
  echo "usage: g [<aliased g command>|<git command>]"
  echo 
  echo "The g git aliases are:"
  echo "   ls     list tracked files"
}

# ------------------------------------------------
# MAIN/G -----------------------------------------
# ------------------------------------------------
function g()
{
  _g_command=$1
  shift

  _found=`_find_command $_g_command`

  echo $_found

  # Command was found
  if [[ $? == 0 ]] ; then
  fi

  return
  # -----

  case $_g_command in
    l)
    _git_log
    ;;
    ls)
    _git_ls_files
    ;;
    # add untracked
    au)
    _git_all_tracked_or_prompt $*
    ;;
    # remove untracked
    ru)
    g_lso=`git ls-files --other --exclude-standard`

    if [[ -n $g_lso ]] ; then
        echo $g_lso
        echo -en "\033[31;1mPermanently remove these files (y/n)?\033[0m "
        read add_files

        if [[ $add_files == "y" ]] ; then
            echo $g_lso | xargs rm
        fi
    fi
    ;;
    # branch
    b)
    git branch
    ;;
    # list untracked
    lso)
    git ls-files --other --exclude-standard
    ;;
    # list deleted
    lsd)
    git ls-files --deleted
    ;;
    # diff
    d)
    git diff
    ;;
    # commit with message
    cm)
    git commit -a -m "$2"
    ;;
    # commit with message and push
    cmp)
    if [[ -z $2 ]] ; then
      echo "fatal: No commit message argument"
      return 1
    fi

    g_lso=`git ls-files --other --exclude-standard`

    do_commit=false

    if [[ -n $g_lso ]] ; then
      echo $g_lso
      echo
      echo -n "warning: Untracked files exist. Commit anyways (y/n)? "
      read commit_anyways

      if [[ $commit_anyways == "y" ]] ; then
          do_commit=true
      fi
    else
      do_commit=true
    fi

    if ( $do_commit ) ; then
      git commit -a -m "$2" && git push --all
      g
    fi

    ;;
    # tell git to set the standard default push
    cpdm)
    git config push.default matching
    ;;
    # status
    s)
    git status
    ;;
    # push
    ps)
    git push
    ;;
    # grep
    g)
    _git_grep $*
    ;;
    # push all
    psa)
    git push --all
    ;;
    # pull
    pl)
    git pull
    ;;
    # default
    "")
    if ( `pwd-is-git-repo` ) ; then
      _git_status_display
    fi
    ;;
    "--help")
    _usage
    ;;

    # Fallback:
    # Pass the arguments to git instead
    *)
    git $*
    if [[ $? == 1 ]] ; then
      _usage
    fi
    ;;
  esac
}

