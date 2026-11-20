#!/bin/bash
# ============================================
# Fix: Allow Tailscale traffic when ProtonVPN is connected
# Run with sudo AFTER connecting ProtonVPN:
#   sudo ./protonvpn-tailscale-fix.sh
#
# Problem: ProtonVPN routes ALL traffic through its tunnel
# + kill-switch blocks non-VPN traffic, killing Tailscale.
# Fix: Insert iptables ACCEPT rules for Tailscale ABOVE
# the kill-switch DROP/REJECT rules.
# ============================================
set -e

echo "=== ProtonVPN + Tailscale coexistence fix ==="

# 1. Allow all traffic on Tailscale interface (both directions)
iptables -I OUTPUT -o tailscale0 -j ACCEPT
iptables -I INPUT -i tailscale0 -j ACCEPT
iptables -I FORWARD -o tailscale0 -j ACCEPT
iptables -I FORWARD -i tailscale0 -j ACCEPT
echo "[1/4] Tailscale interface traffic allowed"

# 2. Allow Tailscale WireGuard UDP port (direct peer connections)
iptables -I OUTPUT -p udp --dport 41641 -j ACCEPT
iptables -I INPUT -p udp --sport 41641 -j ACCEPT
echo "[2/4] Tailscale UDP port 41641 allowed"

# 3. Allow Tailscale DERP relays (TCP 443 to known DERP IPs is dynamic,
#    so we allow ESTABLISHED connections which covers return traffic)
iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
echo "[3/4] Established connections allowed"

# 4. Ensure route to Tailscale CGNAT range via tailscale0
ip route add 100.64.0.0/10 dev tailscale0 2>/dev/null || \
ip route replace 100.64.0.0/10 dev tailscale0
echo "[4/4] Route 100.64.0.0/10 via tailscale0 ensured"

echo ""
echo "=== Verifying ==="
tailscale status 2>&1 | head -5
echo ""
ping -c 2 -W 3 100.110.171.119 && echo "PC2 REACHABLE via Tailscale" || echo "PC2 still unreachable"
