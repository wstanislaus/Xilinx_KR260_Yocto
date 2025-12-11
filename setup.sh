#!/bin/bash
# Setup script for Xilinx Kria KR260 Development Kit Yocto Project
# This script helps set up the build environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "=========================================="
echo "Xilinx Kria KR260 Development Kit Setup"
echo "=========================================="
echo ""

# Check for required tools
echo "Checking prerequisites..."
command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed. Aborting." >&2; exit 1; }
command -v make >/dev/null 2>&1 || { echo "Error: make is required but not installed. Aborting." >&2; exit 1; }

# Check for repo tool
if ! command -v repo >/dev/null 2>&1; then
    echo "Warning: 'repo' tool is not installed."
    echo ""
    echo "The repo tool is required for Xilinx Yocto projects (2025.2+)."
    echo "Install it using one of these methods:"
    echo ""
    echo "Method 1 (Recommended - system package):"
    echo "  sudo apt-get install -y repo"
    echo ""
    echo "Method 2 (Manual installation):"
    echo "  mkdir -p ~/bin"
    echo "  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo"
    echo "  chmod a+x ~/bin/repo"
    echo "  export PATH=~/bin:\$PATH"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Detect Ubuntu version and provide package installation instructions
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d. -f1,2)
        echo "Detected Ubuntu $UBUNTU_VERSION"
        # Check if version is 24.04 or newer
        MAJOR=$(echo "$UBUNTU_VERSION" | cut -d. -f1)
        MINOR=$(echo "$UBUNTU_VERSION" | cut -d. -f2)
        if [ "$MAJOR" -gt 24 ] || ([ "$MAJOR" -eq 24 ] && [ "$MINOR" -ge 4 ]); then
            echo ""
            echo "For Ubuntu 24.04 LTS or newer, install required packages with:"
            echo "  sudo apt-get update"
            echo "  sudo apt-get install -y gawk wget git repo diffstat unzip texinfo gcc-multilib \\"
            echo "       build-essential chrpath socat cpio python3 python3-pip python3-pexpect \\"
            echo "       xz-utils debianutils iputils-ping python3-git python3-jinja2 \\"
            echo "       libsdl1.2-dev pylint xterm python3-subunit mesa-common-dev zstd liblz4-tool \\"
            echo "       libegl1-mesa-dev device-tree-compiler u-boot-tools"
        else
            echo ""
            echo "For Ubuntu $UBUNTU_VERSION, install required packages with:"
            echo "  sudo apt-get update"
            echo "  sudo apt-get install -y gawk wget git-core repo diffstat unzip texinfo gcc-multilib \\"
            echo "       build-essential chrpath socat cpio python3 python3-pip python3-pexpect \\"
            echo "       xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa \\"
            echo "       libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool device-tree-compiler u-boot-tools"
        fi
        echo ""
    fi
fi

# Check disk space (at least 50GB free recommended)
AVAILABLE_SPACE=$(df -BG "${SCRIPT_DIR}" | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "${AVAILABLE_SPACE}" -lt 50 ]; then
    echo "Warning: Less than 50GB free space available. Build may fail."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Step 1: Setting up Yocto source repositories..."
echo "This may take a while depending on your internet connection..."
make setup-sources

echo ""
echo "Step 2: Setting up build environment..."
make setup-env

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review and customize configuration:"
echo "     - Edit build/conf/local.conf for build settings"
echo "     - Adjust meta-kr260/recipes-core/images/kria-image-kr260.bb for package changes"
echo ""
echo "  2. Start building:"
echo "     make build-kernel    # Build kernel for TFTP"
echo "     make build-rootfs    # Build rootfs for NFS"
echo "     make build-sdk       # Build SDK toolchain"
echo "     make build-all       # Build everything"
echo ""
echo "  3. Or build manually:"
echo "     make bitbake-shell"
echo "       - Run bitbake commands directly"
echo "       - Example: bitbake u-boot-xlnx"
echo ""
echo "  4. Install artifacts:"
echo "     make install-kernel  # Install kernel to TFTP server"
echo "     make install-rootfs  # Install rootfs to NFS server"
echo ""
echo "For detailed build and configuration options, see Makefile."
echo ""
