g
=
g is a set of ZSH functions and scripts to automate and/or shorten common git tasks.

Requirements
------------
* Zsh
* Git

Installation
------------
Clone the repository to `~/.g` and add `source $HOME/.g/g.zsh` to your `~/.zshrc`.

Commands
--------

###Aliases###

**g l**

`git log`

**g b**

`git branch`

**g d**

`git diff`

**g ls**

`git ls-files`

**g lsd**

`git ls-files --deleted`

**g lso**

`git ls-files --other --exclude-standard`

###Prompts###

**g au**

Is a prompt to add all untracked files in the current repository.

**g ru**

Is a propmpt to remove all untracked files in the current directory.

###Quick Commands###

**g cm <commit-message>**

*Commit All with Message*

Is a quick command for `git commit --all --message <commit-message>`

**g cmp <commit-message>**

*Commit All with Message and Push*

Is a quick command for `git commit --all --message <commit-message>` followed by `git push`

Credits
-------
Erik Nomitch: erik@nomitch.com
