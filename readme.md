# Gitcm

gitcm is a git client for IBM i, running in 5250, all written in RPG. Not only a git client, but also a very basic IFS browser in which you can edit files with (taking option 2 opens the streamfile in SEU 😫)

It's an older code-base and things could have easily be done better. For example, to grab git output we pipe it to a file and then read the file contents. Perhaps it could be changed to just read the standard out using the pase APIs.

![gitcm diff](https://i.imgur.com/s7oGYSW.png)

## Installation

1. Requires `git` to be installed via yum.
2. Clone this repo and `cd gitcm`
3. Run `gmake` (also installed from yum)
5. On 5250: use `cd` (`chgcurdir`) to change your working directory to a git repo
4. On 5250: `addlible gitcm` and then `gitcm`
