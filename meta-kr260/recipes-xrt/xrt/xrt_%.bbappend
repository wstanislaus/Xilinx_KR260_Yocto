FILESEXTRAPATHS:prepend := "${THISDIR}/xrt:"

inherit python3-dir

DEPENDS:append = " python3 python3-pybind11"

SRC_URI:append = " \
    file://0001-upstream-patch-to-fix-the-pyxrt-build.patch \
    file://cmake-disable-win32.cmake \
"

EXTRA_OECMAKE:append = " \
    -DXRT_NATIVE_BUILD=yes \
    -C ${WORKDIR}/cmake-disable-win32.cmake \
    -DXRT_INSTALL_PYTHON_DIR=${PYTHON_SITEPACKAGES_DIR} \
"

PACKAGES += "${PN}-pyxrt"

FILES:${PN}-pyxrt = "\
    ${PYTHON_SITEPACKAGES_DIR}/pyxrt*.so \
    ${PYTHON_SITEPACKAGES_DIR}/ert_binding.py \
    ${PYTHON_SITEPACKAGES_DIR}/xclbin_binding.py \
    ${PYTHON_SITEPACKAGES_DIR}/xrt_binding.py \
"

RDEPENDS:${PN}-pyxrt = "python3-core"
INSANE_SKIP:${PN}-pyxrt += "already-stripped"
INSANE_SKIP:${PN} += "already-stripped"
RDEPENDS:${PN} += "${PN}-pyxrt"

do_install:append() {
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}

    for srcdir in \
        "${D}${prefix}/python" \
        "${D}/usr/local/lib/python${PYTHON_BASEVERSION}/dist-packages"
    do
        if [ -d "${srcdir}" ]; then
            cp -a ${srcdir}/. ${D}${PYTHON_SITEPACKAGES_DIR}/
            rm -rf ${srcdir}
        fi
    done

    # Clean up empty /usr/local tree if it was created
    rmdir --ignore-fail-on-non-empty ${D}/usr/local/lib/python${PYTHON_BASEVERSION}/dist-packages 2>/dev/null || true
    rmdir --ignore-fail-on-non-empty ${D}/usr/local/lib/python${PYTHON_BASEVERSION} 2>/dev/null || true
    rmdir --ignore-fail-on-non-empty ${D}/usr/local/lib 2>/dev/null || true
    rmdir --ignore-fail-on-non-empty ${D}/usr/local 2>/dev/null || true

    # pybind11 names the module using the build host triple. Rename it to the
    # target's extension suffix so Python can import it on device.
    hostmods=$(ls ${D}${PYTHON_SITEPACKAGES_DIR}/pyxrt.cpython-*.so 2>/dev/null || true)
    if [ -n "$hostmods" ]; then
        refmod=$(ls ${STAGING_LIBDIR}/python${PYTHON_BASEVERSION}/lib-dynload/_ssl*.so 2>/dev/null | head -n 1)
        if [ -n "$refmod" ]; then
            suffix=".${refmod##*_ssl.}"
            for hostmod in $hostmods; do
                mv "$hostmod" "${D}${PYTHON_SITEPACKAGES_DIR}/pyxrt${suffix}"
                break
            done
        fi
    fi
}
