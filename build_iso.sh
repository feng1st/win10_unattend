#!/bin/bash

# Exit script immediately on error
set -e

# --- Configuration ---

# Source Files
SOURCE_ISO="en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso"
VIRTIO_ISO="virtio-win-0.1.271.iso"
QXL_CER="qxl-0.141.cer"
SPICE_EXE="spice-guest-tools-0.141.exe"
FIRST_LOGON_CMD="FirstLogon.cmd"
SECOND_LOGON_CMD="SecondLogon.cmd"
UNATTEND_XML_SRC="autounattend.xml"

# Directories
WORKSPACE_DIR="iso_build_workspace"
SOURCE_MOUNT_DIR="$WORKSPACE_DIR/source_iso_mount"
VIRTIO_MOUNT_DIR="$WORKSPACE_DIR/virtio_iso_mount"
OUTPUT_DIR="$WORKSPACE_DIR/output_iso"

# Output Settings
OUTPUT_VOL="WIN10_IOT_LTSC_UNATTEND"
OUTPUT_ISO="en-us_windows_10_iot_enterprise_ltsc_2021_x64_unattend.iso"

# Requirements
REQUIRED_CMDS=("mkisofs" "iconv")
REQUIRED_FILES=("$SOURCE_ISO" "$VIRTIO_ISO" "$QXL_CER" "$SPICE_EXE" "$FIRST_LOGON_CMD" "$SECOND_LOGON_CMD" "$UNATTEND_XML_SRC")

# --- Functions ---

# Cleanup function to be called on exit
cleanup() {
    echo "[INFO] Cleaning up..."
    # Try to unmount, ignore errors if not mounted
    if mountpoint -q "$VIRTIO_MOUNT_DIR"; then sudo umount "$VIRTIO_MOUNT_DIR"; fi
    if mountpoint -q "$SOURCE_MOUNT_DIR"; then sudo umount "$SOURCE_MOUNT_DIR"; fi

    if [ -d "$WORKSPACE_DIR" ]; then
        rm -rf "$WORKSPACE_DIR"
    fi
}

# Trap exit to ensure cleanup
trap cleanup EXIT

# Check for required commands and files
check_requirements() {
    echo "[INFO] Checking requirements..."
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "[ERROR] Required command not found: $cmd"
            exit 1
        fi
    done

    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            echo "[ERROR] Required file not found: $file"
            exit 1
        fi
    done
}

# Prompt user for credentials
get_user_credentials() {
    # 1. Get Username
    ADMIN_USER=""
    while [ -z "$ADMIN_USER" ]; do
        read -p "Please enter username for Windows admin: " ADMIN_USER
    done

    # 2. Get Password
    ADMIN_PASS=""
    while [ -z "$ADMIN_PASS" ]; do
        read -s -p "Please enter password for Windows admin: " ADMIN_PASS
        echo
    done

    # 3. Process Password for autounattend.xml
    # Appends "Password", converts to UTF-16LE, and Base64 encodes
    ADMIN_PASS_B64=$(echo -n "${ADMIN_PASS}Password" | iconv -f UTF-8 -t UTF-16LE | base64)
}

# Prepare workspace directories and mount ISOs
prepare_and_mount() {
    echo "[INFO] Preparing workspace and mounting ISOs..."
    rm -f "$OUTPUT_ISO"
    mkdir -p "$SOURCE_MOUNT_DIR" "$VIRTIO_MOUNT_DIR" "$OUTPUT_DIR"

    sudo mount -o loop,ro "$SOURCE_ISO" "$SOURCE_MOUNT_DIR"
    sudo mount -o loop,ro "$VIRTIO_ISO" "$VIRTIO_MOUNT_DIR"
}

# Copy files to output directory
copy_files() {
    echo "[INFO] Copying files..."

    # Copy Windows files
    cp -a "$SOURCE_MOUNT_DIR/." "$OUTPUT_DIR/"
    chmod +w "$OUTPUT_DIR/"

    # Create directories
    mkdir -p "$OUTPUT_DIR/drivers"
    mkdir -p "$OUTPUT_DIR/scripts"

    # Copy Drivers
    cp -a "$VIRTIO_MOUNT_DIR/viostor/w10/amd64" "$OUTPUT_DIR/drivers/"

    # Copy Tools & Scripts
    cp -a "$VIRTIO_MOUNT_DIR/virtio-win-guest-tools.exe" "$OUTPUT_DIR/scripts/"
    cp -a "$QXL_CER" "$OUTPUT_DIR/scripts/"
    cp -a "$SPICE_EXE" "$OUTPUT_DIR/scripts/"
    cp -a "$FIRST_LOGON_CMD" "$OUTPUT_DIR/scripts/"
    cp -a "$SECOND_LOGON_CMD" "$OUTPUT_DIR/scripts/"

    # Copy Unattend XML
    cp -a "$UNATTEND_XML_SRC" "$OUTPUT_DIR/autounattend.xml"

    # Ensure write permissions for modifications
    chmod -R +w "$OUTPUT_DIR/"
}

# Apply configuration to autounattend.xml
configure_unattend() {
    echo "[INFO] Configuring autounattend.xml..."
    local target_xml="$OUTPUT_DIR/autounattend.xml"

    # Replace placeholders with user inputs
    sed -i "s|USERNAME_PLACEHOLDER|$ADMIN_USER|g" "$target_xml"
    sed -i "s|PASSWORD_PLACEHOLDER|$ADMIN_PASS_B64|g" "$target_xml"
}

# Build the final ISO
build_iso() {
    echo "[INFO] Building ISO..."
    mkisofs \
      -b boot/etfsboot.com \
      -boot-load-size 8 \
      -c boot/boot.catalog \
      -no-emul-boot \
      -eltorito-alt-boot \
      -b efi/microsoft/boot/efisys.bin \
      -no-emul-boot \
      -iso-level 4 \
      -J \
      -joliet-long \
      -relaxed-filenames \
      -udf \
      -V "$OUTPUT_VOL" \
      -o "$OUTPUT_ISO" \
      "$OUTPUT_DIR/"

    echo "[SUCCESS] ISO created at: $OUTPUT_ISO"
}

# --- Main Execution Flow ---

check_requirements
get_user_credentials
prepare_and_mount
copy_files
configure_unattend
build_iso
