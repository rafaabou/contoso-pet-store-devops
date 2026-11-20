# OpenTofu Guide — Zero to Hero

> From beginner to advanced: complete OpenTofu documentation for the Contoso Pet Store K3s Cluster Project.

## Guide Structure

| Document | Topic | Level |
|----------|-------|-------|
| [opentofu-basics.md](opentofu-basics.md) | What is OpenTofu, installation, why use it | Beginner |
| [opentofu-files.md](opentofu-files.md) | File types: providers.tf, variables.tf, main.tf, outputs.tf, tfvars | Beginner |
| [opentofu-hcl.md](opentofu-hcl.md) | HCL language syntax, interpolation, heredoc | Beginner |
| [opentofu-commands.md](opentofu-commands.md) | Commands in detail: init, plan, apply, destroy | Beginner |
| [opentofu-workflow.md](opentofu-workflow.md) | Standard workflow, common tasks, best practices | Intermediate |
| [opentofu-troubleshooting.md](opentofu-troubleshooting.md) | Common errors and fixes | Intermediate |
| [opentofu-project.md](opentofu-project.md) | Our project reference: files, variables, containers | Advanced |

## Quick Start

```bash
# Install
sudo apt install tofu

# Run
cd ansible-opentofu/terraform/pc1
tofu init
tofu plan
tofu apply -auto-approve
```

## For Our Project

This guide is tailored for the Contoso Pet Store K3s Cluster:
- **3 containers** on 2 PCs via Incus
- **OpenTofu** creates the containers
- **Ansible** configures K3s inside them

See [opentofu-project.md](opentofu-project.md) for project-specific details.
