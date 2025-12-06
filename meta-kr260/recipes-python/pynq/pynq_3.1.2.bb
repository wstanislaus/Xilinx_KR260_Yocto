# Recipe for PYNQ v3.1.2
# PYNQ - Python productivity for Zynq
# https://github.com/Xilinx/PYNQ
# Installs PYNQ from GitHub release

SUMMARY = "PYNQ - Python productivity for Zynq"
DESCRIPTION = "PYNQ is an open-source project from Xilinx that makes it easy to design \
embedded systems with Xilinx Zynq Systems on Chips (SoCs). Using the Python language and \
libraries, designers can exploit the benefits of programmable logic and microprocessors \
in Zynq to build more capable and exciting embedded systems."

HOMEPAGE = "https://github.com/Xilinx/PYNQ"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/pynq:"

SRC_URI = "git://github.com/Xilinx/PYNQ.git;protocol=https;branch=image_v3.1.2;name=pynq \
           git://github.com/Xilinx/embeddedsw.git;protocol=https;branch=xlnx_rel_v2025.1;name=embeddedsw;destsuffix=git/pynq/lib/_pynq/embeddedsw \
           file://0001-Enable-ON_TARGET-when-running-on-aarch64.patch \
           file://0002-xhdmi-include-libxlnk_cma.patch \
"

SRCREV_pynq = "62f817503ce079a1f20e13ec6adb999f1506b78a"
SRCREV_embeddedsw = "9a17886209aaf5c0a5f50f58b6cf4fe298911159"
SRCREV_FORMAT = "pynq_embeddedsw"

S = "${WORKDIR}/git"

inherit setuptools3

# PYNQ Python dependencies
RDEPENDS:${PN} += " \
    python3-core \
    python3-numpy \
    python3-pillow \
    python3-requests \
    python3-pyyaml \
    python3-setuptools \
    python3-pip \
    python3-wheel \
    python3-packaging \
    python3-jsonschema \
    python3-ipython \
    python3-tornado \
    python3-traitlets \
    python3-pygments \
    python3-prompt-toolkit \
    python3-pexpect \
    python3-jedi \
    python3-decorator \
    python3-six \
    python3-cffi \
    python3-cryptography \
    python3-pycryptodomex \
    python3-pydantic \
    python3-pynqmetadata \
    python3-pynqutils \
"

# Build dependencies
DEPENDS += " \
    python3-setuptools-scm-native \
    python3-wheel-native \
    python3-pip-native \
    boost \
    libdrm \
"

# Set version for setuptools-scm (needed during build)
do_compile:prepend() {
    export SETUPTOOLS_SCM_PRETEND_VERSION="3.1.2"
}

do_compile:append() {
    export PYNQ_BUILD_ARCH="${TARGET_ARCH}"
    export PYNQ_BUILD_ROOT="${RECIPE_SYSROOT}"

    oe_runmake -C ${S}/pynq/lib/_pynq/_audio
    oe_runmake -C ${S}/pynq/lib/_pynq/_xiic

    if [ "${TARGET_ARCH}" = "aarch64" ]; then
        oe_runmake -C ${S}/pynq/lib/_pynq/_displayport
        oe_runmake -C ${S}/pynq/lib/_pynq/_xhdmi
        oe_runmake -C ${S}/pynq/lib/_pynq/_pcam5c
    fi
}

# Install PYNQ
do_install:append() {
    # Install PYNQ package files
    if [ -d "${S}/pynq" ]; then
        install -d ${D}${PYTHON_SITEPACKAGES_DIR}/pynq
        cp -r ${S}/pynq/* ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/ || true

        # Copy libiic.so to pynq/lib/ for correct location
        if [ -f "${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/_pynq/_xiic/libiic.so" ]; then
            install -d ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib
            install -m 0644 ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/_pynq/_xiic/libiic.so ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/libiic.so || true
        fi

        # Drop git metadata and static archives that should not ship in runtime package
        rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/_pynq/embeddedsw/.git || true
        find ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/_pynq/embeddedsw -name "*.a" -delete || true
        find ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/_pynq/embeddedsw/lib/sw_apps -name "copy_bsp.sh" -delete || true
        find ${D}${PYTHON_SITEPACKAGES_DIR}/pynq/lib/_pynq/embeddedsw/ThirdParty -name "run_cmake" -delete || true
    fi

    # Install PYNQ notebooks if available
    if [ -d "${S}/notebooks" ]; then
        install -d ${D}${datadir}/pynq/notebooks
        cp -r ${S}/notebooks/* ${D}${datadir}/pynq/notebooks/ || true
    fi

    # Install PYNQ scripts
    if [ -d "${S}/bin" ]; then
        install -d ${D}${bindir}
        install -m 0755 ${S}/bin/* ${D}${bindir}/ || true
    fi
}

FILES:${PN} += " \
    ${PYTHON_SITEPACKAGES_DIR}/pynq* \
    ${datadir}/pynq \
    ${bindir}/*pynq* \
"

BBCLASSEXTEND = "native nativesdk"
