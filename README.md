# setup

Scripts that perform initial setup of my machines.

## install

```sh
sudo apt-get install ansible
ansible-galaxy install -r requirements.yml

# vault is used to encrypt work info, emails
echo $VAULT_PASSWORD > pass
```

## run

### everywhere setup

```sh
ansible-playbook playbook.yml --ask-become
```

### work setup

Perform the setup via:

```sh
ansible-playbook playbook.yml --ask-become --tags "all,never"
```

Vault secrets may require updating. Create new secrets by running:

```sh
ansible-vault encrypt_string 'secret-string' --name variable_name >> roles/vault/vars/main.yml

# clean up the old variable afterwards; this is a manual step
nano roles/vault/vars/main.yml
```

## todo
* git config
  * duckbot
* work git/personal git setups
* ssh
* shell
  * cow, fortune, cowsay
  * bash completion
* python
* scala
* nvm, node
* java
* docker
* vscode, intellij settings
