SUMMARY = "Metadata models and tooling for PYNQ designs"
DESCRIPTION = "Provides the metadata models and validators that the PYNQ \
tooling expects when parsing and operating on overlay descriptions."
HOMEPAGE = "https://github.com/Xilinx/pynq-metadata"

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=4d2124d4ae21e284f8fab7ae4d5dd882"

SRC_URI = "git://github.com/Xilinx/pynq-metadata.git;protocol=https;branch=main"
SRCREV = "8a7249c796297afad78a95cb9d83ac513b07af0e"

S = "${WORKDIR}/git"

inherit setuptools3

RDEPENDS:${PN} += " \
    python3-jsonschema \
    python3-pydantic \
    python3-ipython \
"
