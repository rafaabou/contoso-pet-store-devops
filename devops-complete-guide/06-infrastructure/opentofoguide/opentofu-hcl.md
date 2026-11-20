# HCL Language Basics

## What is HCL?

HCL stands for **HashiCorp Configuration Language**. It is a special language made for configuration files.

## Basic Syntax

```hcl
# This is a comment

resource "incus_instance" "master" {
  name = "k3s-master"

  config = {
    "limits.cpu" = 4
  }
}
```

**Rules:**
- `#` starts a comment (ignored by OpenTofu)
- `=` means "equals" (not `==`)
- `{` and `}` group things together
- Strings use `"` quotes
- Numbers do not need quotes
- Indentation does not matter (but use 2 spaces for readability)

## String Interpolation

You can put variables inside strings:

```hcl
name = "${var.prefix}-master"
```

**What happens:**
1. `var.prefix` = `"k3s"`
2. `${var.prefix}` = `"k3s"`
3. Result: `"k3s-master"`

**The `${}` syntax** means "replace this with its value."

## Heredoc (Multi-line strings)

```hcl
content = <<-EOT
  Line 1
  Line 2
  Line 3
EOT
```

**What it does:** Creates a multi-line string.

**The `<<-EOT` syntax:**
- `<<` means "start a heredoc"
- `-` means "strip leading whitespace"
- `EOT` is the delimiter (any word works)

**When to use it:** When you have long text that spans multiple lines (like cloud-init configs).

## Expressions

### Arithmetic

```hcl
result = var.cpu * 2          # Multiplication
result = var.memory / 1024    # Division
result = var.count + 1        # Addition
result = var.total - 1        # Subtraction
```

### Comparison

```hcl
result = var.cpu == 4         # Equal to (true/false)
result = var.cpu != 2         # Not equal to
result = var.cpu > 2          # Greater than
result = var.cpu < 8          # Less than
result = var.cpu >= 4         # Greater than or equal
result = var.cpu <= 4         # Less than or equal
```

### Logical

```hcl
result = var.env == "prod" && var.cpu >= 4   # AND
result = var.env == "prod" || var.env == "staging"  # OR
result = !var.debug          # NOT
```

### Conditional (Ternary)

```hcl
result = var.env == "prod" ? "large" : "small"
# If env is prod, result is "large", otherwise "small"
```

## Built-in Functions

### String Functions

```hcl
upper("hello")           # "HELLO"
lower("HELLO")           # "hello"
length("hello")          # 5
substr("hello", 1, 3)    # "ell"
replace("hello", "l", "L")  # "heLLo"
format("Hello %s", "World")  # "Hello World"
```

### Numeric Functions

```hcl
min(1, 2, 3)            # 1
max(1, 2, 3)            # 3
ceil(4.1)               # 5
floor(4.9)              # 4
```

### Collection Functions

```hcl
length(["a", "b", "c"])  # 3
contains(["a", "b"], "a")  # true
concat(["a"], ["b", "c"])  # ["a", "b", "c"]
merge({a=1}, {b=2})      # {a=1, b=2}
```

### File Functions

```hcl
file("path/to/file.txt")           # Read file contents
fileexists("path/to/file.txt")     # Check if file exists
```

## Blocks

### Resource Block

```hcl
resource "incus_instance" "master" {
  name = "k3s-master"
}
```

### Data Source Block

```hcl
data "incus_instance" "existing" {
  name = "my-existing-container"
}
```

### Variable Block

```hcl
variable "prefix" {
  type    = string
  default = "k3s"
}
```

### Output Block

```hcl
output "master_ip" {
  value = incus_instance.master.ipv4_address
}
```

### Locals Block

```hcl
locals {
  full_name = "${var.prefix}-master"
  cpu_count = var.cpu * 2
}
```

**Use locals** to avoid repeating the same expression multiple times.

## Meta-Arguments

### count

```hcl
resource "incus_instance" "worker" {
  count = 3
  name  = "worker-${count.index}"
}
```

Creates 3 containers: worker-0, worker-1, worker-2.

### for_each

```hcl
resource "incus_instance" "worker" {
  for_each = toset(["worker-1", "worker-2", "worker-3"])
  name     = each.value
}
```

Creates 3 containers using a set.

### depends_on

```hcl
resource "incus_instance" "worker" {
  name = "worker-1"

  depends_on = [incus_instance.master]
}
```

Ensures master is created before worker.

### lifecycle

```hcl
resource "incus_instance" "master" {
  name = "k3s-master"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [config["last_updated"]]
  }
}
```

| Argument | What it does |
|----------|-------------|
| `create_before_destroy` | Create new before destroying old |
| `prevent_destroy` | Prevent accidental deletion |
| `ignore_changes` | Don't care if these change |
