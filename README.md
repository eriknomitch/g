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

###Wrappers###

**g l**

Is a wrapper for `git log`

**g b**

Is a wrapper for `git branch`

**g ls**

Is a wrapper for `git ls-files`

**g lsd**

Is a wrapper for `git ls-files --deleted`

**g lso**

Is a wrapper for `git ls-files --other --exclude-standard`

**g au**

Is a prompt to add all untracked files in the current repository.

**g ru**

Is a propmpt to remove all untracked files in the current directory.

Credits
-------
Erik Nomitch: erik@nomitch.com
