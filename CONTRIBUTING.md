# How to contribute

The development of the Cog virtual machine takes place on the *Cog*
branch. External contributors have to submit pull requests for review. Core
contributors will generally work on the Cog branch by pushing to it
directly. However, larger features should be developed on separate feature
branches and presented to the community for review through pull requests. Rule
of thumb: If you're working on any feature that will take more than a couple of
days to stabilize or anything that could potentially destabilize the VM for
other people, do it on a feature branch and open a pull request.

### TL;DR Workflow
* Create a topic branch from where you want to base your work.
  * This is usually the Cog branch.
  * Only target other branches if you are certain your fix must be on that
    branch.
  * To quickly create a topic branch based on *Cog*; `git checkout -b
    feature/Cog/my_contribution Cog && git push -u origin
    feature/Cog/my_contribution`.
* Prefer many small commits of logical units that still compile over one large
  commit. Use `git add --patch` to review and stage your work interactively or
  use `magit` in Emacs or go through the changed lines in the github desktop
  client. Try to make each commit the smallest possible coherent change that
  still compiles.
* Give meaningful but small commit messages. Avoid large "SVN-style" commits
  where you dump a large number of changes into one commit. You will be thankful
  later when you need to use `git bisect` to find where a bug comes from. This
  also means that you should avoid rebasing or squashing your work. Just keep
  the history.
  
### Regarding /src and alike directories

Versioning the generated source code is of critical importance for debugging the
VM, since it is not posssible to guarantee that source files will not differ 
from another set of source files generated in the same environment. For this
same reason, counting with a clean, versioned set of source files makes it 
easier to check the newly generated source for bugs in parts of the system such 
as the Slang translator.

C source files are manually generated and committed when necessary by core
contributors. Unless source files
* need to be updated to fix a bug or make available new functionality urgently 
needed
* have been carefully checked for bugs that may have been introduced by
modifications in parts of the system involved in the generation process
* are generated from versioned imput (i.e. none of the packages to be translated
or involved in the generation process are dirty)

it's preferrable that no changes to them are submitted.

# Integration of GIT with the source tree organization

There are two subtree modules in the Cog branch, `platforms/Cross/plugins` and
`platforms/win32/plugins`. These are tracked on separate branches in the
repository and shared with the `oldTrunk` branch of development. For
contributors this can mostly be ignored, as we can easily split any changes in
those directories and cross-merge them across branches. The split is mostly just
historical right now, since most development takes place on the Cog branch.

Also a historical artifact is that we use source tree
substitutions. Specifically, any sq*SCCSVersion.h files anywhere in the tree are
processed to replace `$Rev$`, `$Date$`, and `$URL$` with the current revision
(defined as the timestamp %Y%m%d%H%M of the latest commit), the human readable
date of that commit, and the URL of the origin repository these sources were
cloned from.

The first time you clone this repository, you *must* therefore run this command:

    ./scripts/updateSCCSVersions


This will install filters, post-commit, and post-merge hooks to update the
sq*SCCSVersion.h files anytime you commit or merge. If you know your way around
Git, you will know when to manually run this file again. If you do not know your
way around, please refrain from copy and pasting random snippets you found on
StackOverflow to "fix" an issue you have. Stick with the well known `add,
commit, push, pull, checkout, revert` tools in your workflow.

### Using GUI clients

You can use GUI clients (I hear the github desktop client is good), **but only
after you ran the updateSCCSVersions script**.

### A note to Windows and other users not on UNIX

You must use some Unix-y (Cygwin or MSYS or some such) layer that provides Perl
and a Bash shell and common Unix tools like sed, grep, find, ... . Our scripts
are written for that, and the source file replacement scripts probably won't
work without such an environment.

# Shortcuts for newcomers to Git

If you are new to Git, here are a few tips that will make it easier for you to
work within the contribution guidelines:

### Getting the code

If you're a core developer, clone the repository and set it up:

    git clone git@github.com:OpenSmalltalk/vm.git
    cd vm
	./scripts/updateSCCSVersions

If you're an external developer, go to github and fork the repository, then
clone your fork:

    git clone git@github.com:YOUR-GITHUB-USERNAME/vm.git
    cd vm
	./scripts/updateSCCSVersions

### Moving to a feature branch

    git checkout -b MY-FEATURE-BRANCH-NAME Cog
	git push -u origin MY-FEATURE-BRANCH-NAME:MY-FEATURE-BRANCH-NAME

### Making, reviewing, and committing changes
You can set up a Git alias that helps you keep commits small and related changes
together:

    git config --global --add alias.go "!git add --patch && git commit && git status"

Then whenever you want to commit your changes run:

    git go

This will go over all the changes in tracked files and you can quickly decide to
stage them or leave them out of this commit, then you commit them, and then
you'll get a status info. Repeat `git go` until all modifications you want to
keep are committed.

For new files, you'll have to add them with `git add`.

Once you've committed everything and want to get rid of all remaining changes,
just run this:

    git checkout -- .

### Commit Messages

Keep them short. Also, since we're testing each commit on CI, if your changes
are only documentation or some other change that does not affect compilation or
function of the VM, please prepend `[skip ci]` to your commit message to not
trigger unnecessary builds.

### Undoing commits

We do not allow force-pushes to our main development branches. If you want to
undo any change, you should use `git revert SHA`. This will create a new commit
with the reverse patch of `SHA`, thus keeping history intact.

### Publishing your work

Every so many commits it is a good idea to push your work. Please refrain from
rebasing, unless your history looks like this:

	commit 9053988200f86da55c7a599a3e93e6d5a6c4e3c7
	Author: Tim Felgentreff <timfelgentreff@gmail.com>
	Date:   Tue Apr 28 09:09:49 2015 +0200

	    maybe this works?

	commit fcede7be5a9347d56670af0d07ac303baba41d31
	Author: Tim Felgentreff <timfelgentreff@gmail.com>
	Date:   Tue Apr 28 07:17:17 2015 +0200

	    try once more

	commit 66c6b1b036c4bd90237c575221db0530b850ec17
	Author: Tim Felgentreff <timfelgentreff@gmail.com>
	Date:   Tue Apr 28 06:51:46 2015 +0200

	    try again

	commit b8e60620c1285f7e19dbb3ff23e1d201eecb8c24
	Author: Tim Felgentreff <timfelgentreff@gmail.com>
	Date:   Tue Apr 28 06:44:04 2015 +0200

	    try a different build script

(However, if you're unsure what rebasing is, just forget about it and push the
history as-is. Seriously, skipping bad commits a bisect is easier than fixing
someones git tree once they have lost commits to the depths of
reflog. Especially if their recovery attempts have already triggered a Git GC.)

If you were working on Cog and the change isn't too large, just do:

    git push origin Cog

If you were working on a feature branch, do this:

    git push origin MY-FEATURE-BRANCH-NAME

If your feature branch is ready or you are an external contributor with your own
fork, use the github web interface to open a pull request.
