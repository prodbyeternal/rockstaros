#!/bin/bash
set -e

echo "=== RockstarOS Setup by @prodbyeternal ==="
echo "***              Version1              ***"



# --- Detect kernel & locate vmlinuz ---
echo "[*] Detecting current kernel..."
KERNEL_VER="$(uname -r)"
MODULES_DIR="/lib/modules/${KERNEL_VER}"

echo "[*] Looking for vmlinuz in $MODULES_DIR..."
if cd "$MODULES_DIR"; then
    VMLINUZ_FILE=$(ls -A | grep '^vmlinuz$' || true)
    if [[ -z "$VMLINUZ_FILE" ]]; then
        echo "[!] No vmlinuz found in $MODULES_DIR — aborting."
        exit 1
    fi
    VMLINUZ_PATH="$MODULES_DIR/$VMLINUZ_FILE"
    echo "[+] Found vmlinuz: $VMLINUZ_PATH"
else
    echo "[!] Could not cd into $MODULES_DIR — aborting."
    exit 1
fi

# --- Copy vmlinuz to /boot ---
echo "[*] Copying vmlinuz to /boot..."
cp "$VMLINUZ_PATH" /boot/vmlinuz

# --- Strip VGA param if present ---
echo "[*] Stripping all vga= parameters from grub configs..."

for grubfile in /etc/grub.conf /boot/grub/grub.conf; do
    if [ -f "$grubfile" ]; then
        if grep -q 'vga=' "$grubfile"; then
            sed -i 's/ vga=[^ ]*//g' "$grubfile"
            echo "[+] VGA parameters removed from $grubfile."
        else
            echo "[!] No VGA parameters found in $grubfile."
        fi
    else
        echo "[!] $grubfile not found — skipping."
    fi
done

# --- Locate matching initrd ---
echo "[*] Searching for initrd..."
if cd /boot; then
    INITRD_FILE=$(ls -A | grep -E '^initrd.*\.img$' | grep "$KERNEL_VER" || true)
    if [[ -z "$INITRD_FILE" ]]; then
        echo "[!] No initrd for $KERNEL_VER found in /boot — aborting."
        exit 1
    fi
    INITRD_PATH="/boot/$INITRD_FILE"
    echo "[+] Found initrd: $INITRD_PATH"
else
    echo "[!] Could not cd into /boot — aborting."
    exit 1
fi

# Strip all VGA parameters from both grub files
echo "[*] Stripping all vga= parameters from grub configs..."
for grubfile in "$SRC" "$DEST"; do
    if [ -f "$grubfile" ]; then
        sed -i 's/ vga=[^ ]*//g' "$grubfile"
        echo "[+] VGA parameters removed from $grubfile."
    fi
done

# --- Create GRUB entry ---
echo "[*] Creating new RockstarOS grub entry..."
grubby --copy-default --add-kernel=/boot/vmlinuz --initrd="$INITRD_PATH" --title="RockstarOS"

echo "[*] Copying RockstarOS grub entry to /boot/grub/grub.conf..."

SRC="/etc/grub.conf"
DEST="/boot/grub/grub.conf"

if grep -q '^title RockstarOS' "$SRC"; then
    # Extract from 'title RockstarOS' until the next 'title ' or EOF
    ENTRY=$(awk '/^title RockstarOS/{p=1} /^title / && NR>1 && p && !/^title RockstarOS/{exit} p' "$SRC")

    if [ -n "$ENTRY" ]; then
        echo -e "\n$ENTRY" >> "$DEST"
        echo "[+] RockstarOS entry appended to $DEST."
    else
        echo "[!] RockstarOS entry not found in $SRC."
    fi
else
    echo "[!] RockstarOS entry not found in $SRC — skipping copy."
fi

# --- Verify nix ---
echo "[*] Checking if nix can run..."
if ! command -v nix &>/dev/null; then
    echo "[!] nix command not found — aborting."
    exit 1
fi
if ! nix --version &>/dev/null; then
    echo "[!] nix is installed but not functioning — aborting."
    exit 1
fi
echo "[+] nix is functional."

# --- Install base packages with nix ---
echo "[*] Installing core packages via nix..."
nix profile install nixpkgs#coreutils
nix profile install nixpkgs#binutils
nix profile install nixpkgs#busybox
nix profile install nixpkgs#bash
nix profile install nixpkgs#wget
nix profile install nixpkgs#curl

# --- Download Bedrock hijack ---
echo "[*] Downloading Bedrock Linux hijack script..."
BEDROCK_SCRIPT="bedrock-linux-0.7.30-x86_64.sh"
curl -L -o "$BEDROCK_SCRIPT" \
"https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.30/$BEDROCK_SCRIPT"

chmod +x "$BEDROCK_SCRIPT"

# --- Run Bedrock hijack ---
echo "[*] Running Bedrock hijack..."
bash "$BEDROCK_SCRIPT" --hijack redstar

# --- Customize Bedrock release branding ---
echo "[*] Customizing release branding..."
if [[ -d /bedrock/etc ]]; then
    rm -f /bedrock/etc/bedrock-release
    echo "Rockstar OS 1.0" > /bedrock/etc/bedrock-release
    echo "[+] Release branding updated to 'Rockstar OS 1.0'."
else
    echo "[!] /bedrock/etc directory not found - skipping branding update."
fi

# --- Post-install sanity checks ---
echo "[*] Performing sanity checks..."

if [[ ! -f /boot/vmlinuz ]]; then
    echo "[!] vmlinuz missing from /boot after hijack!"
else
    echo "[+] vmlinuz still present in /boot."
fi

if grep -q 'title RockstarOS' /etc/grub.conf; then
    echo "[+] RockstarOS grub entry present."
else
    echo "[!] RockstarOS grub entry missing!"
fi

echo
echo "[!] NOTE: You must manually fetch rootfs tarballs for strata."
echo "    Rootfs tar.gz files are very easy to get, search up your distro's tarball and use brl import <distro> /path/to/distro.tar.gz."
echo "    Red Star OS's outdated certificates prevent 'brl fetch' from working."
echo "    Use the 'RockstarOS' boot entry from now on, the other ones won't work."
echo "[*] Done."
