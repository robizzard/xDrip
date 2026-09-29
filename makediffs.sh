#!/bin/bash

git diff --find-renames origin/master -- > xDripX.diff
git status --short > xDripX-status.txt
git rev-parse origin/master > xDripX-baseline.txt
git rev-parse HEAD > xDripX-head.txt
