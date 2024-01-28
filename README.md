# setup

Scripts that perform initial setup of my machines.

## install

`python3` is required for ansible.

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

## post run

* [add ssh keys to github accounts](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
