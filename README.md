# Xilinx Kria KR260 Development Kit Yocto Project

This repo contains the Yocto build infrastructure for the **Xilinx_KR260** platform. It targets the KR260 Development Kit with the commercial K26 SOM (with on-module eMMC) and produces the QSPI image, kernel FIT image, and root filesystem.

**Validated with Xilinx tools 2025.2 and Yocto Scarthgap (5.1).**

## Features

- **KR260 Machine Support** – Uses the upstream `k26-smk-kr-sdt` machine from `meta-kria`.
- **eMMC Overlay** – Provides `DTS/kr260-emmc-overlay.dts` that enables the eMMC controller at `mmc@ff160000` for the commercial SOM.
- **Meta Layer** – Custom `meta-kr260` layer (PYNQ, XRT, ZOCL, gRPC, libmetal, etc.).
- **Network Boot** – Pre-configured for TFTP kernel boot and NFS rootfs (board IP configurable via `BOARD_IP` variable, default `172.20.1.2/24`).
- **Default Account** – User `xilinx` (UID/GID 1000) with password `xilinx`, sudo rights, hostname `Xilinx-KR260`.
- **PYNQ + Jupyter** – Installs PYNQ v3.1.2 and a password-protected Jupyter Notebook server on port `9090`. Enables rapid experimentation and validation of PL bitstreams through interactive Python development before production deployment.
- **SDK Toolchain** – `make build-sdk` delivers a self-contained cross-toolchain with all required headers, libraries, and kernel source for building kernel modules.
- **Remoteproc Support** – Enables loading RPU (Real-Time Processing Unit) firmware from APU (Application Processing Unit) and starting the RPU cores via the Linux remoteproc framework. The device tree overlay (`kr260_overlay.dtso`) configures the R5F cluster for split/lockstep modes and provides memory regions for firmware loading.

## Prerequisites

### Build Host

- Ubuntu 20.04 LTS or newer (Ubuntu 24.04 LTS recommended)
- ≥100 GB free disk space
- ≥8 GB RAM (16 GB recommended)
- `git`, `repo`, and standard Yocto build dependencies

**Ubuntu 24.04 LTS packages**
```bash
sudo apt-get update
sudo apt-get install -y gawk wget git repo diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping python3-git python3-jinja2 \
     libsdl1.2-dev pylint xterm python3-subunit mesa-common-dev zstd liblz4-tool \
     libegl1-mesa-dev
```

**Ubuntu 20.04/22.04 LTS packages**
```bash
sudo apt-get update
sudo apt-get install -y gawk wget git-core repo diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa \
     libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool
```

## Repository Layout

```
Xilinx_KR260/
├── Makefile                 # Top-level build orchestration
├── README.md
├── QUICKSTART.md
├── DTS/
│   └── kr260-emmc-overlay.dts
├── conf/
│   ├── bblayers.conf.template
│   └── local.conf.template
├── meta-kr260/              # Custom Yocto layer (recipes, configs, patches)
├── tools/
│   └── image.its
├── setup.sh
└── (generated) build/, downloads/, sources/, sstate-cache/
```

## Quick Start

### 1. Fetch Sources
```bash
make setup-sources
```

### 2. Create Build Config
```bash
make setup-env
```

### 3. Build Targets

| Target | Description | Output |
|--------|-------------|--------|
| `make build-kernel` | FIT image (kernel + DT + optional initramfs) | `build/tmp-glibc/deploy/images/k26-smk-kr-sdt/image.ub` |
| `make build-rootfs` | Rootfs archive for NFS/SD | `build/tmp-glibc/deploy/images/k26-smk-kr-sdt/kria-image-kr260-k26-smk-kr-sdt.rootfs.tar.gz` |
| `make build-sdk` | Cross-toolchain installer | `build/tmp-glibc/deploy/sdk/kria-toolchain-kr260-sdk.sh` |
| `make build-all` | Runs all of the above | — |

### Installing Artifacts

```bash
# Kernel to TFTP
make install-kernel       # copies image.ub to /tftpboot/

# Rootfs to NFS
make install-rootfs       # extracts rootfs into /nfsroot
```

Manual copies:
```bash
sudo cp build/tmp-glibc/deploy/images/k26-smk-kr-sdt/image.ub /tftpboot/
sudo mkdir -p /nfsroot
sudo tar -xzf build/tmp-glibc/deploy/images/k26-smk-kr-sdt/kria-image-kr260-k26-smk-kr-sdt.rootfs.tar.gz -C /nfsroot
```

Network defaults (configurable in `conf/local.conf.template`):
- TFTP/NFS server: `NFS_SERVER` (default: `172.20.1.1`)
- Board IP: `BOARD_IP` (default: `172.20.1.2`)
- Gateway: `BOARD_GATEWAY` (default: `172.20.1.1`)
- Netmask: `BOARD_NETMASK` (default: `255.255.255.0`)
- NFS root: `NFS_ROOT` (default: `/nfsroot`)

Adjust via `conf/local.conf` or environment variables (see **Configuration** section).

## Software Stack

- **PYNQ 3.1.2** with Python scientific stack
- **XRT** and **ZOCL** for FPGA acceleration
- **gRPC / Protobuf** for distributed control
- **Libmetal / OpenAMP** for shared-memory messaging
- **Full dev tooling** (gcc/g++, cmake, python3-dev, pip, wheel, etc.)
- **User Experience**
  - Default login: `xilinx / xilinx`
  - Hostname: `Xilinx-KR260`
  - Notebook storage: `/home/xilinx/Notebook`
  - Jupyter Server: `http://<BOARD_IP>:9090` (password `xilinx`, default: `http://172.20.1.2:9090`)

### PYNQ for PL Bitstream Development

PYNQ provides an ideal environment for experimenting with and validating PL (Programmable Logic) bitstreams before final deployment:

- **Rapid Prototyping**: Load and test bitstreams dynamically without rebooting the system, enabling quick iteration cycles during development.
- **Interactive Validation**: Use Jupyter Notebooks to interactively test FPGA accelerators, verify functionality, and debug issues in real-time with immediate visual feedback.
- **Python Integration**: Leverage Python's rich ecosystem for data analysis, visualization, and algorithm validation while interfacing with hardware accelerators through PYNQ's overlay API.
- **Safe Experimentation**: Test multiple bitstream configurations and designs in a controlled environment, reducing risk before committing to production deployments.
- **Performance Profiling**: Measure and analyze accelerator performance, memory usage, and power consumption to optimize designs before final implementation.
- **Collaborative Development**: Share Jupyter notebooks with team members to document test procedures, results, and design decisions, facilitating knowledge transfer and reproducibility.

This workflow significantly accelerates FPGA development by enabling developers to validate PL designs quickly and confidently before deploying to production systems.

## Device Tree Overlay

The device tree overlay system provides hardware configuration for the KR260 platform:

- **`DTS/kr260_overlay.dtso`** – Comprehensive overlay that configures:
  - **RPU Support**: R5F subsystem configuration for remoteproc, enabling APU to load firmware and start RPU cores dynamically. Configured in split mode with split TCM, providing a 32MB reserved memory region for firmware loading.
  - **PL Mapping**: Programmable Logic overlay support with shared memory regions (APU-RPU and PL-RPU), IPI channels for inter-processor communication, and AXI interrupt controller for PL-generated interrupts.
  - **Communication Infrastructure**: Shared memory regions, IPI channels, and message passing interfaces for low-latency communication between APU, RPU, and PL.

If you need further hardware tweaks, place additional overlays in `DTS/` and add them to the same recipe.

## Booting with Prebuilt QSPI Image

This repository does not build the QSPI boot image (BOOT.BIN) by default. You can use the prebuilt QSPI image available in the `qspi_image/` directory.

**Instructions to update QSPI:**
1. Copy `BOOT.BIN` to the FAT partition of your SD card.
2. Boot the KR260 and stop at the U-Boot prompt.
3. Update the QSPI flash using the image update tools provided by Xilinx/Kria utilities (e.g., `xmutil` in Linux or U-Boot commands if supported).

**Configuring TFTP Boot:**

The prebuilt U-Boot image does not have TFTP boot configured by default. To enable TFTP boot for network booting, you need to configure the boot command in U-Boot:

1. Boot the KR260 and break into the U-Boot prompt (press any key during the boot countdown).
2. Configure the TFTP boot command (adjust IP addresses based on your network configuration, defaults shown):
   ```bash
   setenv bootcmd_tftp "setenv serverip 172.20.1.1;setenv ipaddr 172.20.1.2;tftpboot 0x10000000 image.ub;bootm 0x10000000"
   setenv bootcmd "run bootcmd_tftp"
   saveenv
   ```

   **Note:** Replace `172.20.1.1` with your TFTP/NFS server IP (configured via `NFS_SERVER` in `conf/local.conf`) and `172.20.1.2` with your board IP (configured via `BOARD_IP` in `conf/local.conf`).

3. The configuration is now saved and will be used for subsequent boots.

## Booting from eMMC

Once kernel and rootfs tuning is complete, you can burn a WIC image to eMMC for standalone booting without network dependencies.

### Prerequisites

1. **Update Kernel Bootarg**: Uncomment the line with `root=/dev/mmcblk0p2` and comment the other line with `root=/dev/nfs`  in `dts/kr260_overlay.dtso`:
   ```bash
   /* bootargs = "earlycon console=ttyPS1,115200 clk_ignore_unused root=/dev/nfs rw nfsroot=" XSTRINGIFY(NFS_SERVER) ":" XSTRINGIFY(NFS_ROOT) ",tcp,vers=3,timeo=14 xilinx_tsn_ep.st_pcp=4 cma=900M ip=" XSTRINGIFY(BOARD_IP) "::" XSTRINGIFY(BOARD_GATEWAY) ":" XSTRINGIFY(BOARD_NETMASK) ":Xilinx-KR260:eth0:off uio_pdrv_genirq.of_id=generic-uio"; */
   bootargs = "earlycon console=ttyPS1,115200 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait xilinx_tsn_ep.st_pcp=4 cma=900M uio_pdrv_genirq.of_id=generic-uio";
    
   ```

2. **Build the WIC image**: After enabling WIC support, rebuild the rootfs:
   ```bash
   make build-rootfs
   ```
   The WIC image will be generated at:
   `build/tmp-glibc/deploy/images/k26-smk-kr-sdt/kria-image-kr260-k26-smk-kr-sdt.wic`

### Burning WIC Image to eMMC

**Step 1: Boot using network**

Boot the KR260 board using network boot (TFTP/NFS) as described in the previous sections.

**Step 2: Transfer the WIC image to the board**

Copy the WIC image to the board. You can use SCP, NFS, or any other method:
```bash
# From your build host
scp build/tmp-glibc/deploy/images/k26-smk-kr-sdt/kria-image-kr260-k26-smk-kr-sdt.wic xilinx@172.20.1.2:/home/xilinx/
```

**Step 3: Identify the eMMC device**

On the board, check the block devices:
```bash
xilinx@Xilinx-KR260:~$ lsblk

NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda            8:0    1    0B  0 disk
mmcblk0      179:0    0 14.8G  0 disk
|-mmcblk0p1  179:1    0  512M  0 part /run/media/boot-mmcblk0p1
`-mmcblk0p2  179:2    0  2.3G  0 part /run/media/root-mmcblk0p2
mmcblk0boot0 179:8    0 31.5M  1 disk
mmcblk0boot1 179:16   0 31.5M  1 disk
```

In this example, the eMMC device is `/dev/mmcblk0`.

**Step 4: Unmount any mounted partitions**

If the eMMC partitions are automatically mounted, unmount them:
```bash
umount /run/media/boot-mmcblk0p1 /run/media/root-mmcblk0p2
```

**Step 5: Burn the WIC image**

**⚠️ WARNING: This will erase all data on the eMMC device. Double-check the device path before proceeding.**

```bash
sudo dd if=/path/to/kria-image-kr260-k26-smk-kr-sdt.wic of=/dev/mmcblk0 bs=4M status=progress
```

Replace `/path/to/` with the actual path to your WIC image file. The `status=progress` option shows the write progress.

**Step 6: Configure U-Boot for eMMC boot**

After burning completes, reboot the board and break into the U-Boot prompt (press any key during boot countdown):

1. **Set the eMMC boot command**:
   ```bash
   setenv bootcmd_emmc "mmc dev 0; fatload mmc 0:1 0x10000000 image.ub; bootm 0x10000000"
   ```

2. **Update bootcmd to use eMMC boot**:
   ```bash
   setenv bootcmd "run bootcmd_emmc"
   ```

3. **Save the environment**:
   ```bash
   saveenv
   ```

4. **Reboot**:
   ```bash
   reset
   ```

The board should now boot from eMMC. The initramfs will automatically resize the root partition to use the full eMMC capacity (from 2.3G to ~14.8G) on the first boot.

**Note**: The WIC image includes:
- Partition 1 (FAT32): Contains `image.ub` kernel FIT image in `/boot`
- Partition 2 (ext4): Root filesystem that will be automatically expanded to maximum size on first boot

## Manual bitbake Usage

```bash
cd build
source ../sources/poky/oe-init-build-env .

MACHINE=k26-smk-kr-sdt bitbake virtual/kernel
MACHINE=k26-smk-kr-sdt bitbake kria-image-kr260
MACHINE=k26-smk-kr-sdt bitbake kria-image-kr260 -c populate_sdk
```

## SDK Toolchain Usage

### Installing the SDK

After building the SDK with `make build-sdk`, install it:

```bash
# Install the SDK (adjust path as needed)
# for exmaple
./build/tmp-glibc/deploy/sdk/kria-toolchain-kr260-sdk.sh -y -d /opt/kr260-toolchain/
# Follow the prompts to install (default: /opt/kr260-toolchain)
```

### Using the SDK for Kernel Module Development

The SDK includes the kernel source tree needed for building out-of-tree kernel modules:

```bash
# Source the SDK environment
source /opt/kr260-toolchain/environment-setup-cortexa72-cortexa53-oe-linux

# 1. Navigate to the kernel source directory in the SDK
cd /tools/kr260_yocto_toolchain/sysroots/cortexa72-cortexa53-oe-linux/usr/lib/modules/6.12.40-xilinx/build

# 2. Prepare the kernel source for module building
make ARCH=arm64 modules_prepare

# Kernel source is located at:
# $SDKTARGETSYSROOT/usr/src/kernel/

# Build kernel modules by pointing KDIR to the kernel source:
cd /path/to/your/kernel/module
make KDIR=$SDKTARGETSYSROOT/usr/src/kernel
```

**Note**: The kernel source path in the SDK is typically:
- `$SDKTARGETSYSROOT/usr/src/kernel` (after sourcing the environment)
- Or: `<sdk-install-dir>/sysroots/cortexa72-cortexa53-oe-linux/usr/src/kernel`

## Configuration

- **Yocto Release / Xilinx Tag** – Set `YOCTO_VERSION`, `XILINX_RELEASE_TAG`, and `YOCTO_MANIFEST_FILE` at the top of `Makefile`.
- **Directories** – Override `BUILD_DIR`, `DL_DIR`, `SSTATE_DIR`, `SOURCES_DIR`.
- **Network Settings** – Update `conf/local.conf.template` (BOARD_IP, BOARD_GATEWAY, BOARD_NETMASK, NFS_SERVER, NFS_ROOT, hostname) before running `make setup-env` or edit `build/conf/local.conf` afterwards. These variables are used throughout the build system (device tree, U-Boot config, etc.).
- **Image Customization** – Modify `meta-kr260/recipes-core/images/kria-image-kr260.bb` to add/remove packages or change system behaviour.
- **User Credentials** – Provided via the same image recipe (function `create_xilinx_user`). Update UID/GID/password there if necessary.

## Troubleshooting

1. **Repo issues** – Ensure `repo` tool is installed and available in `PATH`.
2. **Disk space** – Builds require significant space; clean with `make clean-build` / `clean-all` when needed.
3. **TFTP/NFS failures** – Validate services on the server IP (configured via `NFS_SERVER`, default `172.20.1.1`), firewall settings, and export permissions.
4. **Kernel FIT creation errors** – Confirm `tools/image.its` is copied by the Makefile and that DTB/overlay files exist in `build/tmp-glibc/deploy/images/...`.
5. **Login problems** – Default user/password is `xilinx/xilinx`. Root account is locked intentionally.
