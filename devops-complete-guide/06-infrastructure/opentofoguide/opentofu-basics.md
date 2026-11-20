# OpenTofu Basics

## What is OpenTofu?

OpenTofu is a **robot that builds computers for you**.

Instead of clicking buttons and typing commands to create containers, you write a **plan** (a text file) that says "make 2 containers with these settings" and the robot does it.

**Why use it?**
- Faster: 3 minutes instead of 30 minutes
- Safer: You check the plan before the robot builds
- Repeatable: Run the same plan 10 times, get the same result
- Undoable: Tell the robot "destroy everything" and it does

## Where Did It Come From?

In 2023, a company called HashiCorp changed the license of their tool "Terraform" from free to restricted. The community got angry and created OpenTofu — a free copy that stays open forever. It is maintained by the Linux Foundation.

**OpenTofu reads the same files as Terraform.** If you learn OpenTofu, you also know Terraform.

## Installation

### Install on Ubuntu

```bash
# Step 1: Update package list
sudo apt update

# Step 2: Install required tools
sudo apt install -y gnupg software-properties-common

# Step 3: Add HashiCorp GPG key (security key to verify downloads)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Step 4: Add HashiCorp repository (where to download from)
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Step 5: Update again (now includes HashiCorp repo)
sudo apt update

# Step 6: Install OpenTofu
sudo apt install tofu
```

### Verify Installation

```bash
tofu version
```

**Expected output:**
```
OpenTofu v1.8.x
on linux_amd64
```

## The 4 Basic Commands

### Command 1: `tofu init` — "Wake up and get ready"

```bash
tofu init
```

**What it does:** Downloads the tools (providers) OpenTofu needs to work.

**When to run it:** Only once, when you first start or when you add new providers.

**Analogy:** It is like a chef getting their ingredients before cooking. You do this once, not every time you cook.

### Command 2: `tofu plan` — "Show me what you will do"

```bash
tofu plan
```

**What it does:** Shows you what OpenTofu WILL do before it actually does it.

**When to run it:** Every time before `tofu apply`. Always check the plan first.

**The important line:** `Plan: 2 to add, 0 to change, 0 to destroy.`

| Number | Meaning |
|--------|---------|
| `2 to add` | Will create 2 new things |
| `0 to change` | Will not change anything existing |
| `0 to destroy` | Will not delete anything |

**Analogy:** It is like a contractor showing you the blueprints before building. You check "yes, that is what I want" before they start.

### Command 3: `tofu apply` — "Do it now"

```bash
tofu apply
```

**What it does:** Actually creates the containers.

**When to run it:** After you checked the plan and it looks correct.

**To skip the confirmation prompt:**
```bash
tofu apply -auto-approve
```

**Analogy:** It is like the contractor actually building the house after you approved the blueprints.

### Command 4: `tofu destroy` — "Tear it down"

```bash
tofu destroy
```

**What it does:** Deletes everything that was created.

**When to run it:** When you want to start over or clean up.

**To skip the confirmation prompt:**
```bash
tofu destroy -auto-approve
```

**Analogy:** It is like demolishing the house. Everything goes back to empty land.
