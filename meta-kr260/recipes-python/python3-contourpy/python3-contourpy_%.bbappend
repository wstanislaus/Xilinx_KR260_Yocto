# Temporarily disable python3-contourpy due to cross-compilation issues
# The meson build system is detecting host Python headers and adding them to include path
# This causes cross-compilation failures. Disabled until a proper fix can be implemented.
#
# NOTE: This will cause python3-matplotlib to fail if it requires contourpy at runtime.
# If that happens, you may need to remove python3-matplotlib from the image as well.

# Prevent the recipe from being built - make it a no-op
do_compile() {
    bbwarn "python3-contourpy is temporarily disabled due to cross-compilation issues"
    bbwarn "Skipping build - this package will not be included in the image"
    # Create a dummy marker to satisfy build system
    mkdir -p ${B}
    touch ${B}/.contourpy_disabled
}

# Create an empty package to satisfy dependencies
# We need to install something so the package can be created and satisfy dependencies
do_install() {
    bbwarn "python3-contourpy is temporarily disabled - creating minimal stub package"
    # Use the same variable that python_mesonpy uses
    PYTHON_SITE_DIR="${PYTHON_SITEPACKAGE_DIR}"
    if [ -z "${PYTHON_SITE_DIR}" ]; then
        PYTHON_SITE_DIR="${libdir}/python${PYTHON_BASEVERSION}/site-packages"
    fi
    install -d ${D}${PYTHON_SITE_DIR}/contourpy
    # Create a minimal __init__.py that does nothing but allows imports
    cat > ${D}${PYTHON_SITE_DIR}/contourpy/__init__.py << 'EOF'
# python3-contourpy is temporarily disabled due to cross-compilation issues
# This is a stub package that allows imports but provides no functionality
__version__ = "0.0.0-disabled"
EOF
}

# Ensure the installed files are packaged - use both possible variable names
FILES:${PN} += "\
    ${PYTHON_SITEPACKAGE_DIR}/contourpy \
    ${PYTHON_SITEPACKAGE_DIR}/contourpy/__init__.py \
    ${libdir}/python${PYTHON_BASEVERSION}/site-packages/contourpy \
    ${libdir}/python${PYTHON_BASEVERSION}/site-packages/contourpy/__init__.py \
"
