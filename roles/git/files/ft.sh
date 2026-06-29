#!/usr/bin/env bash

default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||")
if [ -z "$default" ]; then
    git remote set-head origin -a >/dev/null 2>&1
    default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||")
fi
if [ -z "$default" ]; then
    echo "git ft: could not determine default branch for origin" >&2
    exit 1
fi

git config --local --unset-all remote.origin.fetch 2>/dev/null
git config --local --add remote.origin.fetch "+refs/heads/${default}:refs/remotes/origin/${default}"
git config --local --add remote.origin.fetch "+refs/heads/twentylemon/*:refs/remotes/origin/twentylemon/*"
git fetch --prune --prune-tags
