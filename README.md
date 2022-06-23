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

# TODO

[ ] Add POST handlers for each form to the graph controller

[ ] Add bootstrap-datepicker to the "Add" graph UI

[ ] Update the DB to support shared graphs

[ ] Confirm behavior in panel for: "View"

[ ] Confirm behavior in panel for: "Add"

[ ] Confirm behavior in panel for: "Share"

[ ] Confirm behavior in panel for: "Data"

[ ] Confirm behavior in panel for: "Import"

[ ] Confirm behavior in panel for: "Export"

[ ] Confirm behavior in panel for: "Settings"

[ ] Setting page to accept choice of graphing method (Line Graph, Ben's Graph)

[ ] Settings page to accept default timezone for input

[ ] Add Ben's Graphing code

[ ] Confirm Old WeightGrapher exports can be imported into this

[ ] Add a home page, contact, etc.


