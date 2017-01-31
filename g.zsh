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

# Find the Git completion file path
_git_completion_path=`echo -n ${^fpath}/_git(N)`

# ------------------------------------------------
# CONFIG->ZSH ------------------------------------
# ------------------------------------------------

# Ensure compinit
autoload -U compinit
compinit

# We source the existing Git rules here so we have access to various
# autocompletion rules.
if [[ -f $_git_completion_path ]] ; then
  source $_git_completion_path
fi

# Append g auxiliary scripts to $PATH
export PATH=$PATH:$(dirname $0)/bin

_g_ls()
{
  if [[ `uname` == "Darwin" ]] ; then
    ls -lh -G
  else
    ls -lh --color
  fi
}

# Change working directory Zsh rule
_g_chpwd()
{
  # Check for shell level (SHLVL) beacuse we don't want this happening in scripts.
  #
  # Check for $0 to be 'zsh' because we don't want this happening in functions.
  # FIX: Doesn't work. ^^^
  #if [[ $SHLVL -lt 1 || $SKIP_CHPWD == true ]] ; then
  if [ -n "${SKIP_CHPWD+x}" ]; then
    if ( $SKIP_CHPWD ) ; then
      return 0
    fi
  fi

  # FIX: IMPORTANT: This is specific to you...
  if [[ $SHLVL == 1 || -n $TMUX ]] ; then
    _g_ls
  fi

  if ( `pwd-is-git-repo --root` ) ; then
    git-status-display
  fi
  
  if ( `pwd-is-git-repo --root` ) ; then
    echo -e "\033[30;1mpwd:\033[0m \033[33;2m`pwd-tilde`\033[0m"
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
  echo -en "\033[32;1m$1 (y/n) \033[0m"
  _read_prompt_response
}

function _prompt_warning()
{
  echo -en "\033[33;1m$1 (y/n) \033[0m"
  _read_prompt_response
}

function _prompt_danger()
{
  echo -en "\033[31;1m$1 (y/n) \033[0m"
  _read_prompt_response
}

# ------------------------------------------------
# UTILITY->GIT -----------------------------------
# ------------------------------------------------
function _git_prompt_if_untracked_files()
{
  # Any untracked files?
  if [[ -n `git ls-files --other --exclude-standard` ]] ; then

    # Show them
    echo $g_lso

    _prompt_warning "Untracked files exist. Commit anyways?"

    return $?
  fi

  # There were no untracked files
  return 0
}

function _prompt_and_force_push()
{
  if ( _prompt_danger "Force push this branch '`git-branch-current`' to your default remote? WARNING: This is potentially destructive." ) ; then
    git push --force
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
  local g_lso

  g_lso=`git ls-files --other --exclude-standard`

  if [[ -n $g_lso ]] ; then
    echo $g_lso

    if ( _prompt_success "Add these files to be tracked?" ) ; then
      git add .
    fi
  fi
}

function _git_remove_untracked_prompt()
{
  local g_lso

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
# Define the commands and also define special
# special _git-* functions for aliases. See /usr/share/zsh/functions/Completion/Unix/_git for documentation on this.
_define_command g   "git grep"
function _git-g () {
  _git-grep
}

_define_command l   "git log"
function _git-l () {
  _git-log
}

_define_command ls  "git ls-files"
function _git-ls () {
  _git-ls-files
}

_define_command b   "git branch"
function _git-b () {
  _git-branch
}

_define_command d   "git diff"
function _git-d () {
  _git-diff
}

_define_command s   "git status"
function _git-s () {
  _git-status
}

_define_command ps  "git push"
function _git-ps () {
  _git-push
}

_define_command pl  "git pull"
function _git-pl () {
  _git-pull
}

_define_command co  "git checkout"
function _git-co () {
  _git-checkout
}

_define_command t   "git tag"
function _git-t () {
  _git-tag
}

_define_command ss   "git status --short"
_define_command psa  "git push --all"
_define_command lso  "git ls-files --other --exclude-standard"
_define_command lsd  "git ls-files --deleted"
_define_command a    "git auto"
_define_command ff   "git flow feature"
_define_command u    "git up"
_define_command rnm  "git branch --remote --no-merged"
_define_command rdf  "git-rebase-develop-into-feature-branches"
_define_command rfm  "git-rebase-from master"
_define_command rfmy "git-rebase-from master --yes"
_define_command asd  "git-auto-smart-diff"
_define_command eg   "git-edit-grep"

# IDEA: Add g cfp which makes a message with the files changed appended to the
# message.

# ------------------------------------------------
# DEFINE->COMMANDS->SPECIAL ----------------------
# ------------------------------------------------

# Untracked file handling
_define_command au "_git_all_tracked_or_prompt"
_define_command ru "_git_remove_untracked_prompt"

# Commit with message
_define_command cm  "_git_commit_with_message"
_define_command cmp "_git_commit_with_message -p"

# Commit with short stat diff
_define_command cs  "_git_commit_with_message -s"
_define_command csp "_git_commit_with_message -p -s"

# Commit with auto smart diff
_define_command ca  "_git_commit_with_message -a" 
_define_command cap "_git_commit_with_message -p -a" 

# Commit with line diff
_define_command cl   "_git_commit_line_diff" 
_define_command clp  "_git_commit_line_diff -p" 

# Shell commands
# FIX: Make this _git_execute and "x"
_define_command c    "_git_command"

# Chained grep
_define_command cg  "_git_chained_grep"

# Ammend message
_define_command am   "_git_ammend_message"

# cg: Chained Grep
# ------------------------------------------------
# Run a command and commit with the message of the command.
function _git_chained_grep()
{
  query_string=""
  multi_grep="(`echo $* | tr " " "|"`)"

  for query in $*
  do
    query_string+=$query" | grep "
  done

  query_string+="--color -E '$multi_grep'"

  eval "git grep $query_string"
}

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
  zparseopts -- p=push s=status_as_message a=auto_as_message

  _push=false
  _status_as_message=false
  _auto_as_message=false

  if [[ $push == "-p" ]] ; then
    _push=true
    shift
  fi
  
  if [[ $status_as_message == "-s" ]] ; then
    _status_as_message=true
    shift
  fi
  
  if [[ $auto_as_message == "-a" ]] ; then
    _auto_as_message=true
    shift
  fi

  # Set commit message to something special?
  local _commit_message
  
  # Short stat:
  if ( $_status_as_message ) ; then

    # Replace line breaks with ; and chomp the trailing ;
    _commit_message=`echo \`git status -s | tr "\n" ";"\` | sed "s/;$//g"`

  # Auto smart diff:
  elif ( $_auto_as_message ) ; then

    local _prefix
    local _auto_smart_diff

    _prefix=""
    _auto_smart_diff=`git-auto-smart-diff --short`

    if [[ -z $_auto_smart_diff ]] ; then
      echo "fatal: Cannot commit an auto smart diff if the auto smart diff is empty."
      return 1
    fi

    # If we have more arguments prefix them to the commit message.
    if [[ -n $* ]] ; then
      _prefix="$*: "
    fi

    _commit_message="$_prefix$_auto_smart_diff"

  # Otherwise, just the argument
  else
    _commit_message=$*
  fi
  
  # Check for commit message
  if [[ -z $_commit_message ]] ; then
    echo "fatal: Cannot commit with an empty message."
    return 1
  fi

  # Confirm short stat commit message
  if ( $_status_as_message ) ; then
    echo $_commit_message
    if ( ! _prompt_success "Commit with this short stat as message?" ) ; then
      return 1
    fi
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
  zparseopts -- p=push s=status_as_message

  _push=false
  if [[ $push == "-p" ]] ; then
    _push=true
  fi

  # Check if we have anything to commit.
  if ( _git_is_clean_work_tree) ; then
    echo "Nothing to commit."
    return 1
  fi

  # Diff the repository to create the message:
  #
  # First, match the lines that begin with + or -... Then, omit the filename
  # descriptor lines (i.e., +++ or ---).
  local _commit_message
  _commit_message=`git diff | grep -E "^\+|^\-" | grep -vE "^\+{3}|^\-{3}"`

  if [[ $_commit_message == "" ]] ; then
    echo "fatal: Cannot commit with an empty message (i.e., there is no line diff)."
    return 1
  fi

  # FIX: This will echo in color if shell code contains color characters.
  echo $_commit_message

  if ( _prompt_success "Commit with this line diff as message?" ) ; then
    git commit --all --message "$_commit_message"

    if ( $_push ) ; then
      git push --all
    fi
  fi
}

# am: Ammend message
# ------------------------------------------------
# Ammend the last commit message and prompt to force push.
function _git_ammend_message()
{
  local _commit_message

  if [[ -n $1 ]] ; then
    _commit_message=$1
  else
    echo "Your latest commit is:"
    echo

    git log -n 1

    echo
    echo -n "Enter your ammended commit message: "
    read _commit_message
  fi

  if ( git commit --all --amend --message "$_commit_message" ) ; then

    echo
    echo "Ammended."
    echo

    _prompt_and_force_push

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

      if ( _prompt_success "Add these files to be tracked?" ) ; then
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
  local _g_command
  local _original_arguments
  local _found_body

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

# ------------------------------------------------
# COMPLETION -------------------------------------
# ------------------------------------------------

# Actually set the compdef to git
compdef g=git

#compctl -k "(ls lso lsd d cm cmp cpdm d s p cg)" g # FIX: compdef overrides these

#function _g () {
  #local _ret=1
  #local cur cword prev

  #cur=${words[CURRENT]}
  #prev=${words[CURRENT-1]}
  #cmd=${words[2]}

  #let cword=CURRENT-1

  #emulate zsh -c _git

  ##case "$cmd" in
    ##ls)
      ##emulate zsh -c _git-ls-files
      ##;;
    ##g)
      ##emulate zsh -c _git-grep
      ##;;
    ##*)
      ##emulate zsh -c _git
      ##;;
  ##esac

  #let _ret && _default && _ret=0
  #return _ret
#}
