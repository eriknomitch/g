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


###Status###

**g**

Will display a custom, colored, and formatted git status including:
* Repository status (clean or unclean)
* Current branch and number of branches
* List of untracked files
* Short diff

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

Prompts to add all untracked files in the current repository

**g ru**

Prompts to remove all untracked files in the current directory

###Quick Commands###

**g cm \<commit-message\>**

*Commit All with Message*

**g cmp \<commit-message\>**

*Commit All with Message and Push*

Credits
-------
Erik Nomitch: erik@nomitch.com
