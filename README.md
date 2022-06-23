# WeightGrapher



# Handbook

## Installation

The `devops/` directory provides a role and playbook for installing and maintaining WeightGrapher.

You will need `ansible-playbook` installed, and this repository checked out to begin installation.  The machine you use ansible-playbook from does not need to be the machine you are installing WeightGrapher on.

WeightGrapher expects to be installed on a Debian 11 server where you have root access over ssh.

Copy `devops/inventory.yml.example` to `devops/inventory.yml` and edit it to replace **my.weight.grapher.server** with the fully qualified hostname for your WeightGrapher server.  You will also want to update the remaining variables.

Ensure that DNS has been updated so that your server can be accessed through the hostname.

Run the following command from within the `devops/` directory:

```bash
ansible-playbook -i inventory.yml site.yml
```

This may take a couple of hours to complete, once it has finished visit http://your-fqdn to create an account.

## Maintenance

## Development

## Backup & Restore WeightGrapher

