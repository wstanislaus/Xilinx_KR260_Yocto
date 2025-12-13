# Custom image recipe for the KR260 Development Kit with PYNQ runtime support
# Based on kria-image-full-cmdline with additional packages tailored for KR260

require recipes-core/images/kria-image-full-cmdline.bb

SUMMARY = "KR260 image with PYNQ runtime, XRT, ZOCL, and gRPC"
DESCRIPTION = "A full-featured image for the KR260 platform based on Kria, \
including the PYNQ runtime, XRT (Xilinx Runtime), ZOCL (Zynq OpenCL), \
gRPC/Protobuf, and libmetal/OpenAMP. Development tools are available in the SDK only."

# Enable systemd as init manager
DISTRO_FEATURES += "systemd"
DISTRO_FEATURES:remove = "sysvinit"

# Only build tar.gz for rootfs (skip cpio, wic, ext4)
# IMAGE_FSTYPES = "tar.gz"

IMAGE_FEATURES += " \
    package-management \
    ssh-server-openssh \
    tools-debug \
    tools-sdk \
"

# PYNQ runtime packages (limited to what current layers provide)
IMAGE_INSTALL += " \
    pynq \
    python3-ipython \
    python3-numpy \
    python3-pillow \
    python3-matplotlib \
    python3-pandas \
    python3-requests \
    python3-pyyaml \
    python3-cffi \
    python3-cryptography \
    python3-tornado \
    python3-traitlets \
    python3-pygments \
    python3-prompt-toolkit \
    python3-pexpect \
    python3-jedi \
    python3-decorator \
    python3-six \
    python3-setuptools \
    python3-pip \
    python3-wheel \
    python3-packaging \
    python3-jsonschema \
    python3-argon2-cffi \
    python3-argon2-cffi-bindings \
"

# Additional tools (includes Python dev for editable installs)
# Note: pkgconfig is excluded - it's provided by target-sdk-provides-dummy in SDK
# and may conflict if included in IMAGE_INSTALL
IMAGE_INSTALL += " \
    python3-dev \
    python3-pkgconfig \
    vim \
    nano \
    curl \
    wget \
    sudo \
    openssh-sftp-server \
    openssh-ssh \
    openssh-scp \
    openssh-sftp \
    openssh-sshd \
    openssh-misc \
    openssh-keygen \
"

# Network tools
IMAGE_INSTALL += " \
    net-tools \
    iputils-ping \
    iputils-tracepath \
    tcpdump \
    iptables \
"

# System utilities
IMAGE_INSTALL += " \
    htop \
    procps \
    util-linux \
    util-linux-blkid \
    util-linux-fdisk \
    util-linux-lsblk \
    util-linux-mount \
    util-linux-umount \
    util-linux-swapon \
    util-linux-swapoff \
    util-linux-fsck \
    e2fsprogs \
    e2fsprogs-e2fsck \
    e2fsprogs-mke2fs \
    e2fsprogs-tune2fs \
    e2fsprogs-resize2fs \
    devmem2 \
"

# XRT (Xilinx Runtime) for FPGA acceleration
IMAGE_INSTALL += " \
    xrt \
"

# Libmetal for shared memory/RPMsg plumbing (OpenAMP app installs it when available)
IMAGE_INSTALL += " libmetal "

# ZOCL (Zynq OpenCL) for FPGA acceleration
IMAGE_INSTALL += " \
    zocl \
"

# UIO kernel modules for device access
IMAGE_INSTALL += " \
    kernel-module-uio-pdrv-genirq \
    kernel-module-uio-dmem-genirq \
"

# gRPC and Protocol Buffers
IMAGE_INSTALL += " \
    grpc \
    protobuf \
    python3-protobuf \
"

# Set hostname to Xilinx-KR260
set_hostname() {
    echo "Xilinx-KR260" > ${IMAGE_ROOTFS}${sysconfdir}/hostname
}

# Auto-load the zocl kernel module so XRT gets a /dev/dri render node
enable_zocl_module() {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/modules-load.d
    echo "zocl" > ${IMAGE_ROOTFS}${sysconfdir}/modules-load.d/zocl.conf
}

# Rename ethernet interface end0 to eth0 using systemd.link file and service
rename_ethernet_interface() {
    # Create a systemd service as a reliable fallback to rename the interface
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system
    cat > ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/rename-end0-to-eth0.service << 'EOF'
[Unit]
Description=Rename network interface end0 to eth0
After=systemd-udevd.service
Before=network-pre.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
# Wait for end0 to appear, then rename it to eth0
ExecStart=/bin/sh -c 'for i in $(seq 1 10); do if [ -d /sys/class/net/end0 ] && [ ! -d /sys/class/net/eth0 ]; then /usr/sbin/ip link set end0 name eth0 && /usr/sbin/ip link set end1 name eth1 && exit 0; fi; sleep 0.5; done; exit 0'

[Install]
WantedBy=network-pre.target
EOF
    chmod 644 ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/rename-end0-to-eth0.service

    # Enable the service
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/network-pre.target.wants
    ln -sf ../rename-end0-to-eth0.service ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/network-pre.target.wants/rename-end0-to-eth0.service
}

# Create xilinx user with password and sudo privileges
create_xilinx_user() {
    # Create user home directory
    install -d ${IMAGE_ROOTFS}/home/xilinx
    chmod 755 ${IMAGE_ROOTFS}/home/xilinx

    # Password hash for "xilinx" generated using: openssl passwd -1 -salt xilinx xilinx
    # Hash: $1$xilinx$a9KcUB279cot0TWU7KGCA0
    PASSWORD_HASH='$1$xilinx$a9KcUB279cot0TWU7KGCA0'

    # Add user to /etc/passwd (UID 1000, GID 1000)
    echo "xilinx:x:1000:1000:xilinx User:/home/xilinx:/bin/bash" >> ${IMAGE_ROOTFS}/etc/passwd

    # Add user to /etc/group (create xilinx group)
    echo "xilinx:x:1000:" >> ${IMAGE_ROOTFS}/etc/group

    # Add password to /etc/shadow
    echo "xilinx:${PASSWORD_HASH}:19000:0:99999:7:::" >> ${IMAGE_ROOTFS}/etc/shadow

    # Add user to sudo group
    if [ -f ${IMAGE_ROOTFS}/etc/group ]; then
        # Check if sudo group exists, if not create it
        if ! grep -q "^sudo:" ${IMAGE_ROOTFS}/etc/group; then
            echo "sudo:x:27:" >> ${IMAGE_ROOTFS}/etc/group
        fi
        # Add xilinx to sudo group
        sed -i '/^sudo:/s/$/,xilinx/' ${IMAGE_ROOTFS}/etc/group
    fi

    # Configure sudoers to require password authentication for xilinx
    install -d ${IMAGE_ROOTFS}/etc/sudoers.d
    echo "xilinx ALL=(ALL) ALL" > ${IMAGE_ROOTFS}/etc/sudoers.d/xilinx
    chmod 440 ${IMAGE_ROOTFS}/etc/sudoers.d/xilinx

    # Set ownership of home directory
    chown -R 1000:1000 ${IMAGE_ROOTFS}/home/xilinx 2>/dev/null || true
}

# Create Notebook directory for xilinx user
create_notebook_directory() {
    # Create Notebook directory in xilinx's home
    install -d ${IMAGE_ROOTFS}/home/xilinx/Notebook
    chmod 755 ${IMAGE_ROOTFS}/home/xilinx/Notebook
    # Set ownership to xilinx user (UID 1000, GID 1000)
    chown -R 1000:1000 ${IMAGE_ROOTFS}/home/xilinx/Notebook 2>/dev/null || true
}

# Setup Jupyter notebook systemd service
setup_jupyter_service() {
    # Create systemd service directory
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system

    # Create Jupyter config directory for xilinx admin use
    install -d ${IMAGE_ROOTFS}/home/root/.jupyter
    chmod 755 ${IMAGE_ROOTFS}/home/root/.jupyter

    # Create Jupyter notebook config file with password
    cat > ${IMAGE_ROOTFS}/home/root/.jupyter/jupyter_server_config.py << 'JUPYTEREOF'
# Jupyter Notebook Configuration
c = get_config()

# Server configuration
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = 9090
c.ServerApp.open_browser = False
c.ServerApp.root_dir = "/home/xilinx/Notebook"

# Password authentication
# Password for 'xilinx' using from jupyter_server.auth import passwd; print(passwd("xilinx"))
c.ServerApp.password = "argon2:$argon2id$v=19$m=10240,t=10,p=8$cswfRcsXy39o0nil5uL3Bw$6bycSTV//BtUH1KzTSaDQHVQG793+p6O7dWFGTbETxs"
c.ServerApp.token = ""
c.ServerApp.password_required = True
c.ServerApp.allow_root = True
JUPYTEREOF
    chmod 644 ${IMAGE_ROOTFS}/home/root/.jupyter/jupyter_server_config.py

    # Create Jupyter notebook service file
    cat > ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/jupyter-notebook.service << 'EOF'
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
User=root
Group=root
Environment=XILINX_XRT=/usr
Environment="LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib/xrt/module/"
Environment="PATH=/usr/bin:/usr/sbin:/bin:/sbin"
ExecStart=/usr/bin/jupyter notebook --config=/home/root/.jupyter/jupyter_server_config.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/jupyter-notebook.service

    # Enable the service to start at boot
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ../jupyter-notebook.service ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/multi-user.target.wants/jupyter-notebook.service
}

# Remove SysV init scripts to eliminate systemd-sysv-generator warnings
# These scripts are not needed when using systemd as they're handled natively
remove_sysv_init_scripts() {
    # List of SysV init scripts to remove (systemd handles these natively)
    SYSV_SCRIPTS="halt sendsigs umountnfs.sh single save-rtc.sh reboot umountfs"

    for script in ${SYSV_SCRIPTS}; do
        if [ -f ${IMAGE_ROOTFS}/etc/init.d/${script} ]; then
            rm -f ${IMAGE_ROOTFS}/etc/init.d/${script}
            bbnote "Removed SysV init script: /etc/init.d/${script}"
        fi
    done
}

# Add global environment variables for XRT and network configuration
setup_global_env() {
    # Add to /etc/profile.d for interactive shells (bash, sh, etc.)
    install -d ${IMAGE_ROOTFS}${sysconfdir}/profile.d
    cat > ${IMAGE_ROOTFS}${sysconfdir}/profile.d/xilinx-env.sh << 'EOF'
#!/bin/sh
# Xilinx XRT and network environment variables
export XILINX_XRT=/usr
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib/xrt/module/
EOF
    chmod 644 ${IMAGE_ROOTFS}${sysconfdir}/profile.d/xilinx-env.sh

    # Add to /etc/environment for systemd services and PAM sessions
    # Note: /etc/environment doesn't support variable expansion, so we add static values
    if [ -f ${IMAGE_ROOTFS}${sysconfdir}/environment ]; then
        # Append if file exists
        echo "XILINX_XRT=/usr" >> ${IMAGE_ROOTFS}${sysconfdir}/environment
    else
        # Create new file
        cat > ${IMAGE_ROOTFS}${sysconfdir}/environment << 'ENVEOF'
XILINX_XRT=/usr
ENVEOF
    fi
    # Note: LD_LIBRARY_PATH with expansion is handled in profile.d script only


}

# Disable direct root logins by locking the root account
disable_root_login() {
    if [ -f ${IMAGE_ROOTFS}/etc/shadow ]; then
        sed -i 's#^root:[^:]*:#root:!:#' ${IMAGE_ROOTFS}/etc/shadow
    fi
}

# Copy image.ub kernel FIT image to /boot directory in rootfs
install_kernel_image() {
    # Create /boot directory
    install -d ${IMAGE_ROOTFS}/boot

    # Check if image.ub exists in deploy directory
    if [ -f ${DEPLOY_DIR_IMAGE}/image.ub ]; then
        bbnote "Copying image.ub to /boot in rootfs"
        cp ${DEPLOY_DIR_IMAGE}/image.ub ${IMAGE_ROOTFS}/boot/image.ub
        chmod 644 ${IMAGE_ROOTFS}/boot/image.ub
    else
        bbwarn "image.ub not found in ${DEPLOY_DIR_IMAGE}, skipping copy to /boot"
        bbwarn "Build kernel first with 'make build-kernel' or 'bitbake virtual/kernel'"
    fi
}

# Run post-processing hooks
ROOTFS_POSTPROCESS_COMMAND += "set_hostname; enable_zocl_module; create_xilinx_user; create_notebook_directory; remove_sysv_init_scripts; setup_global_env; rename_ethernet_interface; setup_jupyter_service; disable_root_login; install_kernel_image; "

# Increase image size to accommodate PYNQ runtime, XRT, and additional packages
IMAGE_ROOTFS_SIZE ?= "1048576"
IMAGE_ROOTFS_EXTRA_SPACE = "524288"

# SDK configuration - include development packages in SDK
# Note: pkgconfig and pkgconfig-dev are provided by target-sdk-provides-dummy
TOOLCHAIN_TARGET_TASK += " \
    zocl-dev \
    opencl-headers \
    grpc-dev \
    grpc-compiler \
    protobuf-dev \
    protobuf-compiler \
    python3-protobuf \
    cmake \
    cmake-dev \
    xrt-dev \
"

# Include Python development packages in SDK
TOOLCHAIN_TARGET_TASK += " \
    python3-dev \
    python3-setuptools \
    python3-pip \
    python3-wheel \
"

# Include C/C++ development tools in SDK
# Note: pkgconfig and pkgconfig-dev are provided by target-sdk-provides-dummy...
TOOLCHAIN_TARGET_TASK += " \
    gcc \
    g++ \
    binutils \
    make \
    autoconf \
    automake \
    libtool \
"

# Include libmetal development packages in SDK
TOOLCHAIN_TARGET_TASK += " \
    libmetal-dev \
"

# Include kernel source in SDK for kernel module development
# The kernel source will be available at $SDKTARGETSYSROOT/usr/src/kernel in the SDK
# This allows cross-compilation of kernel modules using the SDK toolchain
TOOLCHAIN_TARGET_TASK += " \
    kernel-devsrc \
"
