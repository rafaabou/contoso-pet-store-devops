#!/bin/bash

# ==============================================
# COMPLETE KUBERNETES TOOLS INSTALLER - LATEST VERSIONS
# ==============================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
step() { echo -e "\n${PURPLE}▶${NC} ${CYAN}$1${NC}"; }
title() { echo -e "\n${YELLOW}▓▓▓ $1 ▓▓▓${NC}"; }

if [ -n "$SUDO_USER" ]; then CURRENT_USER="$SUDO_USER"; CURRENT_HOME="/home/$SUDO_USER"
else CURRENT_USER="$USER"; CURRENT_HOME="$HOME"; fi

check_tool() { command -v "$1" >/dev/null 2>&1; }

get_latest_github_release() {
    local repo="$1"
    local version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
    [ -z "$version" ] || [ "$version" = "null" ] && echo "latest" || echo "$version"
}

get_download_url() {
    local tool="$1" version="$2" repo="$3"
    case "$tool" in
        kubectl) echo "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl" ;;
        k9s) echo "https://github.com/${repo}/releases/download/${version}/k9s_Linux_amd64.tar.gz" ;;
        popeye) echo "https://github.com/${repo}/releases/download/${version}/popeye_linux_amd64.tar.gz" ;;
        stern) local c="${version#v}"; echo "https://github.com/${repo}/releases/download/${version}/stern_${c}_linux_amd64.tar.gz" ;;
        kube-linter) echo "https://github.com/${repo}/releases/download/${version}/kube-linter-linux.tar.gz" ;;
        checkov) local arch=$(uname -m); [ "$arch" = "x86_64" ] && arch="X86_64" || [ "$arch" = "aarch64" ] && arch="arm64"; echo "https://github.com/${repo}/releases/download/${version}/checkov_linux_${arch}.zip" ;;
        *) echo "" ;;
    esac
}

# ==============================================
title "KUBERNETES TOOLS INSTALLATION - LATEST VERSIONS"
echo -e "${GREEN}Installing for user: $CURRENT_USER${NC}"
echo -e "${GREEN}Home directory: $CURRENT_HOME${NC}"

step "Updating system packages"
apt-get update -qq

step "Installing prerequisites"
apt-get install -y -qq curl wget git jq bash-completion tar gzip tree unzip gnupg software-properties-common ca-certificates 2>&1 | tail -2

step "Ensuring PATH includes /usr/local/bin"
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    echo 'export PATH=$PATH:/usr/local/bin' >> "$CURRENT_HOME/.bashrc"
    export PATH=$PATH:/usr/local/bin
fi

# 1. kubectl
step "Installing kubectl (latest stable)"
if check_tool kubectl; then
    info "kubectl already installed, skipping"
else
    KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
    info "Downloading kubectl version: $KUBECTL_VERSION"
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; rm -f kubectl
    log "kubectl $KUBECTL_VERSION installed"
fi

# 2. Helm
step "Installing Helm (latest)"
if check_tool helm; then
    info "Helm already installed, skipping"
else
    curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 /tmp/get_helm.sh
    /tmp/get_helm.sh
    rm -f /tmp/get_helm.sh
    log "Helm installed"
fi

# 3. kubectx & kubens
step "Installing kubectx and kubens (latest)"
if check_tool kubectx && check_tool kubens; then
    info "kubectx & kubens already installed, skipping"
else
    if [ -d "/opt/kubectx" ]; then cd /opt/kubectx && git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
    else git clone https://github.com/ahmetb/kubectx /opt/kubectx; fi
    ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
    ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
    chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens
    log "kubectx & kubens installed"
fi

# 4. k9s
step "Installing k9s (latest)"
if check_tool k9s; then
    info "k9s already installed, skipping"
else
    K9S_REPO="derailed/k9s"
    K9S_VERSION=$(get_latest_github_release "$K9S_REPO")
    [ "$K9S_VERSION" = "latest" ] && K9S_VERSION="v0.50.18"
    K9S_URL=$(get_download_url "k9s" "$K9S_VERSION" "$K9S_REPO")
    info "Downloading k9s version: $K9S_VERSION"
    curl -L -o /tmp/k9s.tar.gz "$K9S_URL"
    tar -xzf /tmp/k9s.tar.gz -C /usr/local/bin k9s; chmod +x /usr/local/bin/k9s
    log "k9s $K9S_VERSION installed"
fi

# 5. popeye
step "Installing popeye (latest)"
if check_tool popeye; then
    info "popeye already installed, skipping"
else
    POPEYE_REPO="derailed/popeye"
    POPEYE_VERSION=$(get_latest_github_release "$POPEYE_REPO")
    [ "$POPEYE_VERSION" = "latest" ] && POPEYE_VERSION="v0.22.1"
    POPEYE_URL=$(get_download_url "popeye" "$POPEYE_VERSION" "$POPEYE_REPO")
    info "Downloading popeye version: $POPEYE_VERSION"
    curl -L -o /tmp/popeye.tar.gz "$POPEYE_URL"
    tar -xzf /tmp/popeye.tar.gz -C /usr/local/bin popeye; chmod +x /usr/local/bin/popeye
    log "popeye $POPEYE_VERSION installed"
fi

# 6. stern
step "Installing stern (latest)"
if check_tool stern; then
    info "stern already installed, skipping"
else
    STERN_REPO="stern/stern"
    STERN_VERSION=$(get_latest_github_release "$STERN_REPO")
    [ "$STERN_VERSION" = "latest" ] && STERN_VERSION="v1.34.0"
    STERN_URL=$(get_download_url "stern" "$STERN_VERSION" "$STERN_REPO")
    info "Downloading stern version: $STERN_VERSION"
    curl -L -o /tmp/stern.tar.gz "$STERN_URL"
    tar -xzf /tmp/stern.tar.gz -C /usr/local/bin stern; chmod +x /usr/local/bin/stern
    log "stern $STERN_VERSION installed"
fi

# 7. kube-linter
step "Installing kube-linter (latest)"
if check_tool kube-linter; then
    info "kube-linter already installed, skipping"
else
    KUBELINTER_REPO="stackrox/kube-linter"
    KUBELINTER_VERSION=$(get_latest_github_release "$KUBELINTER_REPO")
    [ "$KUBELINTER_VERSION" = "latest" ] && KUBELINTER_VERSION="0.8.3"
    KUBELINTER_URL=$(get_download_url "kube-linter" "$KUBELINTER_VERSION" "$KUBELINTER_REPO")
    info "Downloading kube-linter version: $KUBELINTER_VERSION"
    curl -L -o /tmp/kube-linter.tar.gz "$KUBELINTER_URL"
    tar -xzf /tmp/kube-linter.tar.gz -C /usr/local/bin kube-linter; chmod +x /usr/local/bin/kube-linter
    log "kube-linter $KUBELINTER_VERSION installed"
fi

# 8. Checkov
step "Installing Checkov (latest)"
if check_tool checkov; then
    info "Checkov already installed, skipping"
else
    CHECKOV_REPO="bridgecrewio/checkov"
    CHECKOV_VERSION=$(get_latest_github_release "$CHECKOV_REPO")
    if [ "$CHECKOV_VERSION" = "latest" ] || [ -z "$CHECKOV_VERSION" ]; then
        error "Could not fetch latest Checkov version"
        exit 1
    fi
    CHECKOV_URL=$(get_download_url "checkov" "$CHECKOV_VERSION" "$CHECKOV_REPO")
    info "Downloading Checkov version: $CHECKOV_VERSION"
    curl -L -o /tmp/checkov.zip "$CHECKOV_URL"
    rm -rf /tmp/checkov_extract
    mkdir -p /tmp/checkov_extract
    unzip -o /tmp/checkov.zip -d /tmp/checkov_extract
    BIN=$(find /tmp/checkov_extract -type f 2>/dev/null | head -1)
    if [ -n "$BIN" ]; then
        cp "$BIN" /usr/local/bin/checkov
        chmod +x /usr/local/bin/checkov
        log "Checkov $CHECKOV_VERSION installed"
    else
        error "Could not find checkov binary in archive"
        exit 1
    fi
    rm -rf /tmp/checkov_extract
fi

# ==============================================
# USER CONFIGURATION
# ==============================================
step "Setting up user configuration for $CURRENT_USER"

cat > "$CURRENT_HOME/.kube_aliases" << 'EOF'
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kdel='kubectl delete'
alias ka='kubectl apply -f'
alias kaf='kubectl apply -f'
alias kex='kubectl exec -it'
alias kl='kubectl logs'
alias klo='kubectl logs -f'
alias kp='kubectl get pods'
alias kdp='kubectl describe pod'
alias kn='kubectl get nodes'
alias kdn='kubectl describe node'
alias ks='kubectl get svc'
alias kds='kubectl describe svc'
alias kdi='kubectl describe ingress'
alias kni='kubectl get ingress'
alias kga='kubectl get all'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kge='kubectl get events'
alias kctx='kubectx'
alias kns='kubens'
alias kver='kubectl version --client --short 2>/dev/null | head -1'
alias hver='helm version --short'
alias k9ver='k9s version 2>/dev/null | grep -i version | head -1 | cut -d" " -f2'
alias pver='popeye version 2>/dev/null | head -1'
alias sver='stern --version 2>/dev/null'
alias klver='kube-linter version 2>/dev/null'
alias cver='checkov --version 2>/dev/null'
EOF
chown "$CURRENT_USER:$CURRENT_USER" "$CURRENT_HOME/.kube_aliases" 2>/dev/null || true

step "Setting up kube-ps1 prompt (latest)"
if [ -d "/opt/kube-ps1" ]; then cd /opt/kube-ps1 && git pull origin master 2>/dev/null || true
else git clone https://github.com/jonmosco/kube-ps1.git /opt/kube-ps1; fi

step "Updating $CURRENT_USER's .bashrc"
[ -f "$CURRENT_HOME/.bashrc" ] && cp "$CURRENT_HOME/.bashrc" "$CURRENT_HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
grep -v "KUBERNETES CONFIGURATION\|kube_aliases\|kube-ps1\|kubectl completion\|helm completion" "$CURRENT_HOME/.bashrc" > "$CURRENT_HOME/.bashrc.tmp" 2>/dev/null || true
mv "$CURRENT_HOME/.bashrc.tmp" "$CURRENT_HOME/.bashrc" 2>/dev/null || true

cat >> "$CURRENT_HOME/.bashrc" << 'EOF'

# ==============================================
# KUBERNETES CONFIGURATION (AUTO-GENERATED)
# ==============================================

if [ -f ~/.kube_aliases ]; then . ~/.kube_aliases; fi

if [ -f /opt/kube-ps1/kube-ps1.sh ]; then
    source /opt/kube-ps1/kube-ps1.sh
    export KUBE_PS1_SYMBOL_ENABLE=true
    export KUBE_PS1_SYMBOL_COLOR="yellow"
    export KUBE_PS1_CTX_COLOR="green"
    export KUBE_PS1_NS_COLOR="cyan"
    export KUBE_PS1_BG_COLOR=""
    export KUBE_PS1_SYMBOL="⎈"
    export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(kube_ps1)\[\033[00m\]\$ '
fi

if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k kg kd
fi

if command -v helm >/dev/null 2>&1; then source <(helm completion bash); fi

[ -f /opt/kubectx/completion/kubectx.bash ] && source /opt/kubectx/completion/kubectx.bash
[ -f /opt/kubectx/completion/kubens.bash ] && source /opt/kubectx/completion/kubens.bash
EOF
chown "$CURRENT_USER:$CURRENT_USER" "$CURRENT_HOME/.bashrc" 2>/dev/null || true

[ ! -d "$CURRENT_HOME/.kube" ] && mkdir -p "$CURRENT_HOME/.kube" && chown -R "$CURRENT_USER:$CURRENT_USER" "$CURRENT_HOME/.kube" 2>/dev/null || true

if [ ! -f "$CURRENT_HOME/.kube/config" ] || [ ! -s "$CURRENT_HOME/.kube/config" ]; then
    cat > "$CURRENT_HOME/.kube/config" << 'EOF2'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://kubernetes.default.svc
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: default-user
  name: default-context
current-context: default-context
users:
- name: default-user
  user: {}
EOF2
    chown "$CURRENT_USER:$CURRENT_USER" "$CURRENT_HOME/.kube/config" 2>/dev/null || true
    log "Minimal kubectl configuration created"
fi

# ==============================================
# APPLY & VERIFY
# ==============================================
step "Applying configuration"
[ -f "$CURRENT_HOME/.kube_aliases" ] && source "$CURRENT_HOME/.kube_aliases"
[ -f "/opt/kube-ps1/kube-ps1.sh" ] && source /opt/kube-ps1/kube-ps1.sh
check_tool kubectl && source <(kubectl completion bash) 2>/dev/null || true
check_tool helm && source <(helm completion bash) 2>/dev/null || true

title "VERIFICATION - LATEST VERSIONS"
echo -e "\n${CYAN}TOOLS & VERSIONS:${NC}"
echo "========================================="
declare -A tools=(
    ["kubectl"]="kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || kubectl version --client --short 2>/dev/null | head -1"
    ["helm"]="helm version --short 2>/dev/null"
    ["kubectx"]="echo 'git latest'"
    ["kubens"]="echo 'git latest'"
    ["k9s"]="k9s version 2>/dev/null | grep -i version | head -1 | cut -d' ' -f2"
    ["popeye"]="popeye version 2>/dev/null | head -1 | grep -oP 'v\d+\.\d+\.\d+' || echo 'installed'"
    ["stern"]="stern --version 2>/dev/null | head -1"
    ["kube-linter"]="kube-linter version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || echo 'installed'"
    ["checkov"]="checkov --version 2>/dev/null"
)
for name in "${!tools[@]}"; do
    cmd="${tools[$name]}"
    if check_tool "$name"; then
        version=$(eval "$cmd" 2>/dev/null || echo "installed")
        echo -e "  ${GREEN}✓${NC} $name: ${CYAN}$version${NC}"
    else echo -e "  ${RED}✗${NC} $name: ${RED}NOT INSTALLED${NC}"; fi
done

echo -e "\n${CYAN}CONFIGURATION STATUS:${NC}"
echo "========================================="
for file in "$CURRENT_HOME/.kube_aliases" "$CURRENT_HOME/.bashrc" "/opt/kube-ps1/kube-ps1.sh"; do
    if [ -f "$file" ]; then echo -e "  ${GREEN}✓${NC} $(basename "$file") ($(du -h "$file" 2>/dev/null | cut -f1))"
    else echo -e "  ${RED}✗${NC} $(basename "$file")"; fi
done

echo -e "\n${CYAN}KUBE-PS1 TEST:${NC}"
echo "========================================="
if type kube_ps1 2>/dev/null | grep -q "function"; then
    echo -e "  ${GREEN}✓${NC} kube_ps1 function loaded"
    echo -e "  ${CYAN}Prompt will show:${NC} $(kube_ps1 2>/dev/null || echo '(context:namespace)')"
else echo -e "  ${RED}✗${NC} kube_ps1 function not loaded"; fi

# ==============================================
title "INSTALLATION COMPLETE"
rm -f /tmp/*.tar.gz /tmp/*.zip /tmp/kubectl 2>/dev/null || true

echo -e "\n${YELLOW}NEXT STEPS:${NC}"
echo "1. ${CYAN}For full effect: exec bash${NC}"
echo "2. ${CYAN}Or open new terminal${NC}"
echo -e "\n${YELLOW}TEST COMMANDS:${NC}"
echo "  ${GREEN}kver${NC}          # kubectl version"
echo "  ${GREEN}hver${NC}          # helm version"
echo "  ${GREEN}k9ver${NC}         # k9s version"
echo "  ${GREEN}k get nodes${NC}   # Test kubectl"
echo "  ${GREEN}kctx${NC}          # Switch context"
echo "  ${GREEN}kns${NC}           # Switch namespace"
