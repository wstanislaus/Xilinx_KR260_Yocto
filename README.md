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
- **SDK Toolchain** – `make build-sdk` delivers a self-contained cross-toolchain with all required headers and libraries.
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

## Manual bitbake Usage

```bash
cd build
source ../sources/poky/oe-init-build-env .

MACHINE=k26-smk-kr-sdt bitbake virtual/kernel
MACHINE=k26-smk-kr-sdt bitbake kria-image-kr260
MACHINE=k26-smk-kr-sdt bitbake kria-image-kr260 -c populate_sdk
```

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

For additional background and workflow details, see `QUICKSTART.md`.
