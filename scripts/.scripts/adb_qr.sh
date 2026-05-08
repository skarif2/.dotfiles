#!/usr/bin/env bash

# macOS Android 11+ Wireless ADB — QR Pair & Connect Module
# Dependencies: adb, qrencode (+ dns-sd, jot are built into macOS)
# Designed to be sourced in .zshrc

# --- Dependency check (auto-install via brew) ---
__adb_qr_check_deps() {
    local missing=()
    command -v adb      &>/dev/null || missing+=("android-platform-tools")
    command -v qrencode &>/dev/null || missing+=("qrencode")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing: ${missing[*]}"
        echo "Installing via brew..."
        brew install "${missing[@]}"
    fi
}

# --- Cleanup trap ---
__adb_qr_cleanup() {
    for pid in "${PIDS[@]:-}"; do
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    done
    for f in "${TMPFILES[@]:-}"; do
        rm -f "$f" 2>/dev/null || true
    done
    printf '\033[?1049l'
}

# --- dns-sd helpers ---

# __adb_qr_discover <service_type>
__adb_qr_discover() {
    local service_type="$1"
    local tmpfile
    tmpfile=$(mktemp)
    TMPFILES+=("$tmpfile")

    dns-sd -B "$service_type" > "$tmpfile" 2>/dev/null &
    local pid=$!
    PIDS+=("$pid")

    $DEBUG && echo "[DEBUG] Browsing for ${service_type} (pid=$pid)..." || true

    local elapsed=0
    while (( elapsed < TIMEOUT )); do
        if grep -q "Add" "$tmpfile" 2>/dev/null; then
            local instance
            instance=$(grep "Add" "$tmpfile" | head -1 | awk '{for(i=7;i<=NF;i++) printf "%s%s",$i,(i<NF?" ":"")}')
            kill "$pid" 2>/dev/null || true
            $DEBUG && echo "[DEBUG] Discovered instance: ${instance}" || true
            echo "$instance"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    kill "$pid" 2>/dev/null || true
    echo ""
    return 1
}

# __adb_qr_resolve <instance_name> <service_type>
__adb_qr_resolve() {
    local instance="$1"
    local service_type="$2"
    local tmpfile
    tmpfile=$(mktemp)
    TMPFILES+=("$tmpfile")

    dns-sd -L "$instance" "$service_type" local > "$tmpfile" 2>/dev/null &
    local pid=$!
    PIDS+=("$pid")

    $DEBUG && echo "[DEBUG] Resolving ${instance} (pid=$pid)..." || true

    local elapsed=0
    while (( elapsed < TIMEOUT )); do
        if grep -q "can be reached at" "$tmpfile" 2>/dev/null; then
            local line hostname port host_port
            line=$(grep "can be reached at" "$tmpfile" | head -1)
            host_port=$(echo "$line" | sed -n 's/.*can be reached at \([^[:space:]]*\).*/\1/p')
            hostname="${host_port%:*}"
            port="${host_port##*:}"
            kill "$pid" 2>/dev/null || true
            $DEBUG && echo "[DEBUG] Resolved: hostname=${hostname} port=${port}" || true
            echo "$hostname $port"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    kill "$pid" 2>/dev/null || true
    echo ""
    return 1
}

# __adb_qr_host <hostname>
__adb_qr_host() {
    local hostname="$1"
    local tmpfile
    tmpfile=$(mktemp)
    TMPFILES+=("$tmpfile")

    dns-sd -G v4 "$hostname" > "$tmpfile" 2>/dev/null &
    local pid=$!
    PIDS+=("$pid")

    $DEBUG && echo "[DEBUG] Resolving hostname ${hostname} (pid=$pid)..." || true

    local elapsed=0
    while (( elapsed < TIMEOUT )); do
        if grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$tmpfile" 2>/dev/null; then
            local ip
            ip=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$tmpfile" | head -1)
            kill "$pid" 2>/dev/null || true
            $DEBUG && echo "[DEBUG] Resolved IP: ${ip}" || true
            echo "$ip"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    kill "$pid" 2>/dev/null || true
    echo ""
    return 1
}

# ============================================================================
# Core Logic
# ============================================================================
__adb_qr_core() {
    # --- Configuration ---
    local NAME="debug"
    local PASS
    PASS=$(jot -r 1 100000 999999)
    local SUCCESS_MSG="Successfully paired"

    # Export these so helper functions can see them inside the subshell
    export SERVICE_PAIR="_adb-tls-pairing._tcp"
    export SERVICE_CONNECT="_adb-tls-connect._tcp"
    export TIMEOUT=60
    export DEBUG=false
    
    # Global arrays for cleanup (scoped to the subshell execution)
    PIDS=()
    TMPFILES=()

    [[ "${1:-}" == "-d" || "${1:-}" == "--debug" ]] && export DEBUG=true

    trap '__adb_qr_cleanup; exit 130' INT TERM
    trap __adb_qr_cleanup EXIT

    __adb_qr_check_deps

    # Alt-screen buffer + QR code
    printf '\033[?1049h'
    printf '\033[H\033[2J'
    qrencode -t UTF8 "WIFI:T:ADB;S:${NAME};P:${PASS};;"
    echo ""
    echo "Scan: [Developer options] → [Wireless debugging] → [Pair device with QR code]"
    echo ""

    # Phase 1: Discover the connect service
    echo "⏳ Waiting for device..."
    local connect_instance connect_host connect_port connect_ip

    connect_instance=$(__adb_qr_discover "$SERVICE_CONNECT") || {
        echo "❌ Timed out waiting for device. Is Wireless Debugging enabled?"
        exit 1
    }

    if [[ -z "$connect_instance" ]]; then
        echo "❌ Timed out waiting for device. Is Wireless Debugging enabled?"
        exit 1
    fi

    local connect_info
    connect_info=$(__adb_qr_resolve "$connect_instance" "$SERVICE_CONNECT") || {
        echo "❌ Failed to resolve connect service."
        exit 1
    }
    read -r connect_host connect_port <<< "$connect_info"

    connect_ip=$(__adb_qr_host "$connect_host") || {
        echo "❌ Failed to resolve hostname to IP."
        exit 1
    }

    if [[ -z "$connect_ip" || -z "$connect_port" ]]; then
        echo "❌ Failed to resolve device address."
        exit 1
    fi

    $DEBUG && echo "[DEBUG] Connect endpoint: ${connect_ip}:${connect_port}" || true
    echo "✅ Device found: ${connect_ip}:${connect_port}"

    # Phase 2: Wait for the pairing service
    echo ""
    echo "⏳ Waiting for pairing service..."
    local pair_instance pair_port

    pair_instance=$(__adb_qr_discover "$SERVICE_PAIR") || {
        echo "❌ Timed out waiting for pairing service. Did you open the QR scanner?"
        exit 1
    }

    if [[ -z "$pair_instance" ]]; then
        echo "❌ Timed out waiting for pairing service. Did you open the QR scanner?"
        exit 1
    fi

    local pair_info
    pair_info=$(__adb_qr_resolve "$pair_instance" "$SERVICE_PAIR") || {
        echo "❌ Failed to resolve pairing service."
        exit 1
    }
    read -r _ pair_port <<< "$pair_info"

    $DEBUG && echo "[DEBUG] Pair endpoint: ${connect_ip}:${pair_port}" || true

    # Phase 3: Pair
    echo ""
    echo "🔗 Pairing..."
    local result
    result=$(adb pair "${connect_ip}:${pair_port}" "${PASS}" 2>&1)
    $DEBUG && echo "[DEBUG] adb pair output: $result" || true

    if [[ "$result" != "${SUCCESS_MSG}"* ]]; then
        echo "❌ Pairing failed: $result"
        exit 1
    fi
    echo "✅ $SUCCESS_MSG"

    # Phase 4: Connect
    echo ""
    echo "🔗 Connecting..."
    result=$(adb connect "${connect_ip}:${connect_port}" 2>&1)
    $DEBUG && echo "[DEBUG] adb connect output: $result" || true

    if [[ "$result" == *"connected"* ]]; then
        echo "✅ Connected to ${connect_ip}:${connect_port}"
    else
        echo "❌ Connect failed: $result"
        exit 1
    fi
}

# ============================================================================
# User-Facing Commands
# ============================================================================
function adb-qr() {
    # Run in a subshell to isolate set -e, trap, and exit commands
    (
        set -euo pipefail
        __adb_qr_core "$@"
    )
}

# ============================================================================
# Zsh Tab Completion
# ============================================================================
function _adb_qr_comp() {
    local -a opts=("-d" "--debug")
    compadd -a opts
}

if type compdef >/dev/null 2>&1; then
    compdef _adb_qr_comp adb-qr
fi