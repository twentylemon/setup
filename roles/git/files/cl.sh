#!/usr/bin/env bash

out=$(git clone "$@" 2>&1)
rc=$?
echo "$out"
[ $rc -ne 0 ] && exit $rc

dir=$(echo "$out" | sed -n "s/Cloning into '\(.*\)'.*/\1/p")
if [ -z "$dir" ] || [ ! -d "$dir" ]; then
    exit 0
fi

default=$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||")
if [ -z "$default" ]; then
    git -C "$dir" remote set-head origin -a >/dev/null 2>&1
    default=$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||")
fi
if [ -z "$default" ]; then
    echo "git cl: could not determine default branch for origin" >&2
    exit 1
fi

git -C "$dir" config --local --unset-all remote.origin.fetch 2>/dev/null
git -C "$dir" config --local --add remote.origin.fetch "+refs/heads/${default}:refs/remotes/origin/${default}"
git -C "$dir" config --local --add remote.origin.fetch "+refs/heads/twentylemon/*:refs/remotes/origin/twentylemon/*"
echo "Configured narrow fetch: ${default} + twentylemon/*"
