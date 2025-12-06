SUMMARY = "Utilities shared by the PYNQ stack"
DESCRIPTION = "Helper utilities used by the PYNQ runtime, including runtime \
metadata helpers, setup logic, and overlay installation helpers."
HOMEPAGE = "https://github.com/Xilinx/pynq-utils"

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=4d2124d4ae21e284f8fab7ae4d5dd882"

SRC_URI = "git://github.com/Xilinx/pynq-utils.git;protocol=https;branch=main"
SRCREV = "abb0b4dd3052dae68c878603a44fb7ff7e1f9b80"

S = "${WORKDIR}/git"

inherit setuptools3

RDEPENDS:${PN} += " \
    python3-setuptools \
    python3-pynqmetadata \
    python3-cffi \
    python3-numpy \
    python3-tqdm \
    python3-magic \
"
