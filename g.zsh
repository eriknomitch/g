# ================================================
# G ==============================================
# ================================================

# TODO: g cmp should check to see if the last commit had the same message as the
# one you're trying to create and it should prompt.

# ------------------------------------------------
# CONSTANTS --------------------------------------
# ------------------------------------------------
_VERBOSE=false

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
export PATH=$PATH:$(dirname $0)/bin

# Change working directory Zsh rule
chpwd()
{
  if [[ `uname` == "Darwin" ]] ; then
    ls -lh -G
  else
    ls -lh --color
  fi

  if ( `pwd-is-git-repo --root` ) ; then
    git-status-display
  fi
  
  if ( `pwd-is-git-repo --root` ) ; then
    echo -e "\033[30;1mpwd:\033[0m \033[33;2m"`pwd-tilde`
  fi
}

# ------------------------------------------------
# UTILITY->SHELL ---------------------------------
# ------------------------------------------------
function _echo_verbose()
{
  if ( $_VERBOSE ) ; then
    echo $*
  fi
}

function _read_prompt_response()
{
  read _response

  if [[ $_response == "y" ]] ; then
    return 0
  fi
  return 1
}

function _prompt_success()
{
  echo -en "\033[32;1m$1 (y/n)? \033[0m"
  _read_prompt_response
}

function _prompt_warning()
{
  echo -en "\033[31;1m$1 (y/n)? \033[0m"
  _read_prompt_response
}

function _prompt_danger()
{
  echo -en "\033[31;1m$1 (y/n)? \033[0m"
  _read_prompt_response
}

# ------------------------------------------------
# UTILITY->GIT -----------------------------------
# ------------------------------------------------
function _git_prompt_if_untracked_files()
{
  # Any untracked files?
  g_lso=`git ls-files --other --exclude-standard`

  if [[ -n $g_lso ]] ; then
    echo $g_lso
    echo -en "\033[31;1mUntracked files exist. Commit anyways? (y/n) \033[0m "
    read commit_anyways

    if [[ $commit_anyways == "y" ]] ; then
      return 0
    fi
  else
    return 0
  fi

  return 1
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

  # FIX: This is breaking unless it's <= instead of <... Why?
  for (( index = 0 ; index <= $_commands_length ; index++)) ; do
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

# FIX: Use git-is-clean-work-tree
function _git_is_clean_work_tree() {
  git rev-parse --verify HEAD >/dev/null || return 1
  git update-index -q --ignore-submodules --refresh

  if ! git diff-files --quiet --ignore-submodules ; then
    return 1
  fi

  if ! git diff-index --cached --quiet --ignore-submodules HEAD -- ; then
    return 1
  fi

  # Are there untracked files?
  if [[ `git-count-untracked` -gt 0 ]] ; then
    return 1
  fi

  return 0
}

#function _git_status_display()
#{
  ## FIX: this says that the dir is clean when we deleted some files and when we git-mv files. probably more
  #git_count_untracked=`git-count-untracked`
  #git_count_branches=`git branch | wc -l | awk '{print $1}'`
  #git_branch_current=`git-branch-current`

  #echo -en "\033[30;1mgit:\033[0m "

  ## Show branches
  #echo -e "branch:    \033[37;1m"$git_branch_current"\033[0m("$git_count_branches")"

  ## Show status
  #echo -en "     \033[37;mstatus:\033[0m    "

  ## Check status
  #_git_is_clean_work_tree

  #if [[ $? == 0 ]] ; then
    #echo -e "\033[32;1mclean\033[0m "
  #else
    #echo -e "\033[31;1munclean\033[0m "
  #fi

  ## Show diff
  #echo -e "     \033[37;mdiff:\033[0m     \033[37;1m"`git diff --shortstat`"\033[0m"
  #git diff --numstat | sed "s/^/                /"

  ## Show untracked
  #echo -e "     \033[37;muntracked:\033[0m \033[37;1m"$git_count_untracked"\033[0m"

  #g lso | sed "s/^/                /"
#}

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

function _git_remove_untracked_prompt()
{
  g_lso=`git ls-files --other --exclude-standard`

  if [[ -n $g_lso ]] ; then
    echo $g_lso
    echo -en "\033[31;1mPermanently remove these files (y/n)?\033[0m "
    read add_files

    if [[ $add_files == "y" ]] ; then
      # FIX: Does this handle directories? I think so...
      echo $g_lso | xargs rm
    fi
  fi
}

function _git_fallback()
{
  _echo_verbose "g: Falling back to git with 'git $*'"
  eval "git $*"
}

# ------------------------------------------------
# DEFINE->COMMANDS->ALIASES ----------------------
# ------------------------------------------------
_define_command g   "git grep"
_define_command l   "git log"
_define_command ls  "git ls-files"
_define_command b   "git branch"
_define_command d   "git diff"
_define_command s   "git status"
_define_command ss  "git status --short"
_define_command ps  "git push"
_define_command pl  "git pull"
_define_command co  "git checkout"
_define_command psa "git push --all"
_define_command t   "git tag"
_define_command lso "git ls-files --other --exclude-standard"
_define_command lsd "git ls-files --deleted"
_define_command am  "git commit --all --amend --message"
_define_command a   "git auto"
_define_command ff  "git flow feature"
_define_command u   "git up"
_define_command rnm "git branch --remote --no-merged"

# ------------------------------------------------
# DEFINE->COMMANDS->SPECIAL ----------------------
# ------------------------------------------------
_define_command au   "_git_all_tracked_or_prompt"
_define_command ru   "_git_remove_untracked_prompt"
_define_command cm   "_git_commit_with_message"
_define_command cmp  "_git_commit_with_message -p"
_define_command cmsp "_git_commit_with_message -p -s"
_define_command cms  "_git_commit_with_message -s"
_define_command c    "_git_command"
_define_command cl   "_git_commit_line_diff" 

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

# c: Git Commit with Message
# ------------------------------------------------
# Commit all with a message and possibly push.
function _git_commit_with_message()
{
  # Parse arguments
  # FIX: Really? What's a better way to get opts as booleans?
  zparseopts -- p=push s=status_as_message

  _push=false
  _status_as_message=false

  if [[ $push == "-p" ]] ; then
    _push=true
    shift
  fi
  
  if [[ $status_as_message == "-s" ]] ; then
    _status_as_message=true
    shift
  fi

  # Set commit message
  if ( $_status_as_message ) ; then
    _commit_message=`git status -s`
  else
    _commit_message=$1
  fi

  # Check for commit message
  if [[ -z $_commit_message ]] ; then
    echo "fatal: No commit message available."
    return 1
  fi

  # Any untracked files?
  _git_prompt_if_untracked_files

  # Perform the commit
  if [[ $? == 0 ]] ; then
    git commit --all --message "$_commit_message"

    # Perform the push?
    if ( $_push ) ; then
      git push --all
    fi

    # Status display
    g
  fi
}

# cl: Git commit line diff
# ------------------------------------------------
# Commit all with a message of only the lines changed.
function _git_commit_line_diff()
{
  # Check if we have anything to commit.
  if ( _git_is_clean_work_tree) ; then
    echo "Nothing to commit."
    return 1
  fi

  # Diff the repository to create the message:
  #
  # First, match the lines that begin with + or -... Then, omit the filename
  # descriptor lines (i.e., +++ or ---).
  _commit_message=`git diff | grep -E "^\+|^\-" | grep -vE "^\+{3}|^\-{3}"`

  if [[ $_commit_message == "" ]] ; then
    echo "Cannot commit empty message from empty diff."
    return 1
  fi

  echo $_commit_message

  if ( prompt "Commit with this diff as message?" ) ; then
    git commit --all --message "$_commit_message"
  fi
}

# ------------------------------------------------
# USAGE/HELP -------------------------------------
# ------------------------------------------------
function _usage()
{
  echo "usage: g [<aliased g command>|<git command>]"
  echo 
  echo "The g git aliases are:"

  for (( index = 1; index <= $_commands_length ; index++ )) ; do
    echo "   "$_matches[index]"\t"$_bodies[index]
  done

}

# ------------------------------------------------
# GIT-COMMAND (GC) -------------------------------
# ------------------------------------------------
# Run a command and commit with the message of the command.
# FIX: Also add gcp which pushes after.
#
# This should be "g x" for git execute
function gc()
{
  initial_arguments=$*

  # Execute all the arguments
  $*

  if [[ $? == 0 ]] ; then

    g_lso=`git ls-files --other --exclude-standard`

    if [[ -n $g_lso ]] ; then
        echo $g_lso
        echo -en "\033[32;1mAdd these files to be tracked (y/n)?\033[0m "
        read add_files

        if [[ $add_files == "y" ]] ; then
            git add .
        fi
    fi

    git commit --all -m $initial_arguments
  else
    echo "fatal: Command failed. Not commiting."
    return 1
  fi
}

# ------------------------------------------------
# MAIN/G -----------------------------------------
# ------------------------------------------------
function g()
{
  _g_command=$1
  _original_arguments=$@

  # With no arguments, print g's status
  if [[ -z $_g_command ]] ; then
    git-status-display
    return 0
  fi

  # Check for --help
  if [[ $_g_command == "--help" ]] ; then
    _usage
    return 0
  fi

  # Shift to get the arguments sans "g"
  shift

  # With arguments, attempt to find the command based on the match
  _found_body=`_find_command $_g_command`

  # Command was found
  if [[ $? == 0 ]] ; then
    _echo_verbose "g: $_found_body $*"

    # Concatenate the found body and the quoted arguments passed to the proper
    # 'g' function.
    eval "$_found_body ${(q)@}"

    # Return whatever the eval returned
    return $?
  fi

  # Command was not found, fallback to git
  # FIX: Multiple args are broken
  _git_fallback $_original_arguments
}

#_g() { case "$words[2]" in ff) words=(git flow feature); service=git; (( CURRENT+=2 )); _git;; esac }
#compdef _g g

