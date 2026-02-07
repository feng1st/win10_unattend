# Windows 10 IoT Enterprise LTSC 2021 Unattended ISO Builder

This project provides automation scripts to build a custom Windows 10 IoT Enterprise LTSC 2021 ISO for minimal virtual machine deployment. The resulting ISO performs an unattended installation, loads VirtIO drivers, installs Guest Tools (VirtIO/SPICE), optimizes system settings, cleans up temporary files, and shuts down automatically. The final disk image is clean and ready for snapshotting or use as a template.

## 1. Prerequisites

### 1.1 Software Requirements

Ensure you have the following tools installed on your Linux host:
- `mkisofs` (part of the `cdrtools` package)

Example installation on Fedora/RHEL:
```bash
sudo dnf install cdrtools
```
Example on Debian/Ubuntu:
```bash
sudo apt install cdrtools
```

### 1.2 Required Files

Download the following files and place them in the project root directory. Ensure filenames match exactly, or update the variables in `build_iso.sh`.

| Filename | Description | Download Link |
|----------|-------------|---------------|
| `en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso` | Official Windows 10 IoT Enterprise LTSC 2021 ISO. | https://archive.org/details/en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f_202301 |
| `virtio-win-0.1.271.iso` | VirtIO drivers ISO for Windows. | https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/ |
| `spice-guest-tools-0.141.exe` | SPICE guest tools installer. | https://fedorapeople.org/groups/virt/unattended/drivers/postinst/spice-guest-tools/0.141/ |
| `qxl-0.141.cer` | QXL driver certificate. | https://fedorapeople.org/groups/virt/unattended/drivers/postinst/spice-guest-tools/0.141/ |

## 2. Build Instructions

1.  **Prepare the environment**:
    Ensure all required files listed above and the project scripts (`build_iso.sh`, `autounattend.xml`, `FirstLogon.cmd`, `SecondLogon.cmd`) are in the same directory.

2.  **Run the build script**:
    ```bash
    bash build_iso.sh
    ```
    *Note: The script uses `sudo mount` to read the contents of the source ISOs. It automatically cleans up mount points upon completion.*

3.  **Output**:
    The script will generate a new ISO file:
    -   `en-us_windows_10_iot_enterprise_ltsc_2021_x64_unattend.iso`

## 3. Usage Instructions (Virtual Machine Manager)

### 3.1 Create Virtual Disk

Create a QCOW2 disk image (e.g., 40GB). Preallocation is optional but may improve performance.
```bash
qemu-img create -f qcow2 ~/.local/lib/libvirt/images/win10.qcow2 40G
```

### 3.2 Temporarily Disconnect Internet

It is recommended to disconnect the network during installation to prevent Windows Update from interfering, although the scripts handle most configurations automatically.

### 3.3 VM Configuration

Create a new Virtual Machine in `virt-manager` or use `virt-install` with the following settings:

-   **CDROM**: Mount the generated `en-us_windows_10_iot_enterprise_ltsc_2021_x64_unattend.iso`.
-   **OS Version**: Windows 10
-   **Disk Device**:
    -   Select the `win10.qcow2` disk image created earlier.
    -   **Bus**: `VirtIO` (Crucial: The `autounattend.xml` injects VirtIO storage drivers during setup).
-   **Network Device**:
    -   **Device model**: `virtio`
-   **Other Settings**: Use default values for all other options.

### 3.4 Automated Installation Process

1.  **Boot the VM**.
2.  **Hands-off Installation**:
    -   The installer loads VirtIO storage drivers automatically.
    -   Partitions and formats the disk.
    -   Installs Windows 10 IoT Enterprise LTSC.
    -   Creates a local administrator account (`User`) with password `123456` and logs in automatically.
3.  **First System Boot (FirstLogon.cmd)**:
    -   Installs the VirtIO Guest Tools and SPICE Guest Tools.
    -   Disables hibernation, system restore, and pagefile (to save space).
    -   Reboots automatically.
4.  **Second System Boot (SecondLogon.cmd)**:
    -   Performs disk cleanup (removing temporary files and caches).
    -   **Shuts down** the VM automatically.

### 3.5 Post-Snapshot

Once the VM shuts down automatically:
1.  Remove the CDROM (ISO) from the VM hardware.
2.  The `win10.qcow2` file is now a clean, optimized base image.
3.  You can take a snapshot or clone this image to deploy new VMs.

## 4. Snapshot Description

```
# 01_fresh_install

- Installation environment
  - Network disconnected
- Virtual Disk Image
  - qemu-img create -f qcow2 ~/.local/lib/libvirt/images/win10.qcow2 40G
- ISO
  - en-us_windows_10_iot_enterprise_ltsc_2021_x64_unattend.iso
- Virtual Hardware (Customize configuration before install)
  - Disk bus: VirtIO
  - Network device model: virtio
- Pre-Snapshot
  - Remove CDROM media
```
