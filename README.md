# setup

Scripts that perform initial setup of my machines. Supports both macOS (Homebrew) and Debian/Ubuntu (apt). Shell config is written to both `~/.zshrc` and `~/.bashrc` so either shell works.

## install

`python3` and `ansible` are required.

### macOS

```sh
brew install ansible

ansible-galaxy install -r requirements.yml

# vault is used to encrypt work info, emails
echo $VAULT_PASSWORD > pass
```

### Debian/Ubuntu

```sh
sudo apt install python3-dev python3-pip python3-setuptools

python3 -m pip install ansible
ansible-galaxy install -r requirements.yml

# vault is used to encrypt work info, emails
echo $VAULT_PASSWORD > pass
```

## run

### everywhere setup

```sh
ansible-playbook playbook.yml --ask-become
```

Run individual roles or sub-tasks by tag:

```sh
ansible-playbook playbook.yml --ask-become --tags bash
ansible-playbook playbook.yml --ask-become --tags git
ansible-playbook playbook.yml --ask-become --tags javascript
ansible-playbook playbook.yml --ask-become --tags python
ansible-playbook playbook.yml --ask-become --tags java
ansible-playbook playbook.yml --ask-become --tags sdkman
ansible-playbook playbook.yml --tags claude
```

### claude

The `claude` role installs personal Claude Code files into `~/.claude/`:

* `CLAUDE.md` — global memory / preferences
* `statusline-command.sh` — custom status line
* `hooks/git-twentylemon-gate.sh` — blocks `git commit`/`push` outside `twentylemon/*` branches
* `hooks/gh-api-write-gate.sh` — blocks write-shaped `gh api` calls (POST/PATCH/PUT/DELETE, GraphQL mutations)

The role does **not** manage `~/.claude/settings.json` because that file usually mixes personal and org-managed entries, and Claude merges top-level keys shallowly (so a full-file overwrite would clobber org env, plugins, marketplace, etc.). The portable subset is shipped as `roles/claude/files/settings.snippet.json` — copy the entries you want into your live `settings.json` on a fresh machine.

### work setup

```sh
ansible-playbook playbook.yml --ask-become --tags "all,never"
```

Vault secrets may require updating. Create new secrets by running:

```sh
ansible-vault encrypt_string 'secret-string' --name variable_name >> roles/vault/vars/main.yml

# clean up the old variable afterwards; this is a manual step
nano roles/vault/vars/main.yml
```

## post run

* [add ssh keys to github accounts](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
