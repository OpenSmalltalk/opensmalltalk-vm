#!/bin/bash

# This puts a fresh-built vm into /Applications without removing what was already there,
# by overwriting only the parts you've just built.

# Copy to /Applications, excluding any .svn subdirs.

tar cf - --exclude .svn --exclude 'Squeak*icns' ./Teleplace.app | (cd /Applications; tar xf -)

# All the sub-content frameworks and the exe need to be executable;
# we just do everything so we don't miss anything.

cd /Applications/Teleplace.app
chmod -R a+x ./*

