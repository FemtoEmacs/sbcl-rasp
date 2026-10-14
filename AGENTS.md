# Instructions for the generative AI assisting the user

The human in the loop does not type git commands. All of git goes through
one script, run from the sbcl-rasp folder:

```sh
git/gitpush.sh
```

## Your duties

1. **Keep `git/gitpush.sh` up to date.** Whenever the human asks for
   something git or GitHub must do (a new branch, a tag, a release, pulling
   changes, undoing a commit, a new remote, ...), change `git/gitpush.sh`, or
   add a script beside it in `git/`, so that the human still runs a single
   command. Tell the human which command to run and what it will do.
2. **Write the commit message.** Before the human pushes, put the message in
   `git/next-commit.txt`: a short title line, a blank line, then what changed
   and why. The script uses it and empties it after the commit. The file is
   not uploaded to GitHub.
3. **Do not push for the human** unless asked. Do not ask the human to type
   git commands, and do not send them to the GitHub web pages for something a
   script can do.

## Rules for the scripts

- POSIX `sh` only, with `set -e`; they must work on macOS and Linux.
- Start with a comment saying what the script does and how to run it.
- Print plain messages saying what is happening and what to look at next.
- Never discard the human's work: no `git reset --hard`, `git clean`, or
  `push --force` unless the human asks for exactly that.
- Keep one `main` branch for every operating system; platform differences go
  in the Makefiles, `#ifdef`s and `windows/` folders.

## Rules for the project

- The only tools a user may need are SBCL, a C compiler and make. No Python,
  conda, Haskell, Quicklisp, Roswell, ASDF, C++, Flatpak or Snap.
- In Lisp, do not muffle warnings; use `declaim` declarations.
- `make check` must pass before every push.
