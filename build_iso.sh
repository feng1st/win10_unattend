#!/bin/bash

SOURCE_ISO="en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso"
VIRTIO_ISO="virtio-win-0.1.271.iso"
QXL_CER="qxl-0.141.cer"
SPICE_EXE="spice-guest-tools-0.141.exe"
FIRST_LOGON_CMD="FirstLogon.cmd"
SECOND_LOGON_CMD="SecondLogon.cmd"
UNATTEND_XML="autounattend.xml"

WORKSPACE_DIR="iso_build_workspace"
SOURCE_MOUNT_DIR="$WORKSPACE_DIR/source_iso_mount"
VIRTIO_MOUNT_DIR="$WORKSPACE_DIR/virtio_iso_mount"
OUTPUT_DIR="$WORKSPACE_DIR/output_iso"

OUTPUT_VOL="WIN10_IOT_LTSC_UNATTEND"
OUTPUT_ISO="en-us_windows_10_iot_enterprise_ltsc_2021_x64_unattend.iso"

REQUIRED_CMDS=("mkisofs")
REQUIRED_FILES=("$SOURCE_ISO" "$VIRTIO_ISO" "$QXL_CER" "$SPICE_EXE" "$FIRST_LOGON_CMD" "$SECOND_LOGON_CMD" "$UNATTEND_XML")

cleanup() {
    sudo umount "$VIRTIO_MOUNT_DIR" || true
    sudo umount "$SOURCE_MOUNT_DIR" || true
    if [ -d "$WORKSPACE_DIR" ]; then
        rm -rf "$WORKSPACE_DIR"
    fi
}

trap cleanup EXIT

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

rm -f "$OUTPUT_ISO"

mkdir -p "$SOURCE_MOUNT_DIR" "$VIRTIO_MOUNT_DIR" "$OUTPUT_DIR"

sudo mount -o loop,ro "$SOURCE_ISO" "$SOURCE_MOUNT_DIR"
sudo mount -o loop,ro "$VIRTIO_ISO" "$VIRTIO_MOUNT_DIR"

cp -a "$SOURCE_MOUNT_DIR/." "$OUTPUT_DIR/"
chmod +w "$OUTPUT_DIR/"

mkdir -p "$OUTPUT_DIR/drivers"
mkdir -p "$OUTPUT_DIR/scripts"

cp -a "$VIRTIO_MOUNT_DIR/viostor/w10/amd64" "$OUTPUT_DIR/drivers/"
cp -a "$VIRTIO_MOUNT_DIR/virtio-win-guest-tools.exe" "$OUTPUT_DIR/scripts/"
cp -a "$QXL_CER" "$OUTPUT_DIR/scripts/"
cp -a "$SPICE_EXE" "$OUTPUT_DIR/scripts/"
cp -a "$FIRST_LOGON_CMD" "$OUTPUT_DIR/scripts/"
cp -a "$SECOND_LOGON_CMD" "$OUTPUT_DIR/scripts/"
cp -a "$UNATTEND_XML" "$OUTPUT_DIR/"
chmod -R +w "$OUTPUT_DIR/"

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
