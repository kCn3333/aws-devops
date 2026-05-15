# Ansible Roles

## Overview

Built `common` and `nginx` roles, configured dynamic AWS inventory, and deployed
a working nginx web server with a Jinja2-templated status page.

## Result

```
http://<public_ip_address> — live nginx server
Page displays: hostname, private IP, OS, kernel — populated from Ansible facts
```

## Directory Structure

```
ansible/
├── ansible.cfg
├── inventory/
│   └── aws_ec2.yaml          # dynamic AWS inventory
├── playbooks/
│   ├── group_vars/
│   │   └── all.yaml          # shared variables (project_name, deploy_env)
│   └── site.yaml             # main entry point
└── roles/
    ├── common/               # system updates + base packages
    │   ├── tasks/main.yaml
    │   └── defaults/main.yaml
    └── nginx/                # nginx install + config + index page
        ├── tasks/main.yaml
        ├── handlers/main.yaml
        ├── templates/nginx.conf.j2
        ├── templates/index.html.j2
        └── defaults/main.yaml
```

## Key Concepts

### Roles vs Playbooks
- **Playbook** = orchestration ("run these roles in this order") → `site.yaml`
- **Role** = implementation ("how to install nginx") → `roles/nginx/`

### Dynamic Inventory
```yaml
plugin: amazon.aws.aws_ec2
filters:
  instance-state-name: running
  tag:ManagedBy: terraform       # only our instances
keyed_groups:
  - key: tags.Environment
    prefix: env                  # creates group: env_dev
hostnames:
  - tag:Name                     # display as: aws-devops-dev-server
compose:
  ansible_host: public_ip_address  # connect via public IP
```

No hardcoded IPs — inventory updates automatically after every `terraform apply`.

### Handlers
Run only when notified AND only if the notifying task changed something.
Run once at the end of the play regardless of how many tasks notify them.

```yaml
# tasks
- name: Deploy nginx config
  template: ...
  notify: Reload nginx    # fires only if file changed

# handlers
- name: Reload nginx      # graceful reload (no downtime) vs restart
  service:
    name: nginx
    state: reloaded       # vs restarted — no connection drop
```

### Template validation before deploy
```yaml
- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: nginx -t -c %s   # validates temp file BEFORE writing to dest
```

### Ansible Facts in Jinja2
```jinja2
{{ ansible_hostname }}                  # ip-10-0-1-147
{{ ansible_default_ipv4.address }}      # 10.0.1.147
{{ ansible_distribution }}              # Ubuntu
{{ ansible_kernel }}                    # 6.17.0-1013-aws
```

## Bugs Fixed

### `group_vars` not found
```
Ansible looks for group_vars/ relative to the playbook directory, not CWD.
Fix: move to ansible/playbooks/group_vars/all.yaml
```

### `environment` variable shows `[]`
```
'environment' is reserved by Ansible for OS environment variables on tasks.
Fix: rename to deploy_env (or any non-reserved name)
```

## Idempotency in Practice
Second run with no changes:
```
ok=9    changed=0    unreachable=0    failed=0
```
Every task checks current state before acting — runs safely any number of times.

## Commands Reference

```bash
ansible-inventory --graph              # show inventory structure
ansible-inventory --list               # full inventory as JSON
ansible all -m ping                    # connectivity check
ansible all -m setup                   # dump all facts
ansible-playbook site.yaml --check     # dry run
ansible-playbook site.yaml --diff      # show file diffs
ansible-playbook site.yaml             # apply
```

## Variable Precedence (low → high)
```
role defaults  →  group_vars  →  host_vars  →  playbook vars  →  extra vars (-e)
```

## Common Mistakes

- `group_vars/` in wrong location — put next to playbook or inventory
- Using reserved variable names (`environment`, `path`, `lookup`)
- `state: restarted` instead of `reloaded` — causes downtime on config changes
- Missing `become: true` on tasks requiring root — silent failures
- No `validate:` on config templates — broken config gets deployed

---
