# Makefile for Xilinx Kria KR260 Development Kit Yocto Project
# Targets the commercial Kria K26 SOM (with eMMC) on the KR260 carrier

# Yocto version - for K26 SDT flow with Xilinx tools 2025.2
# Scarthgap (5.1) is the current stable version

YOCTO_VERSION ?= scarthgap
MACHINE ?= k26-smk-kr-sdt
BUILD_DIR ?= $(CURDIR)/build
SOURCES_DIR ?= $(CURDIR)/sources
DL_DIR ?= $(CURDIR)/downloads
SSTATE_DIR ?= $(CURDIR)/sstate-cache
TMPDIR ?= $(BUILD_DIR)/tmp
DTS_FILE ?= $(CURDIR)/qspi_image/kr260.dts

# Network boot configuration
# These must be defined in build/conf/local.conf
# Skip validation for setup targets that create the config file
CURRENT_TARGET := $(firstword $(MAKECMDGOALS))
SKIP_IP_VALIDATION := $(filter setup-env setup-sources help,$(CURRENT_TARGET))

# Only validate and load IP variables if not running setup targets
ifeq ($(SKIP_IP_VALIDATION),)
    ifneq ($(wildcard $(BUILD_DIR)/conf/local.conf),)
        BOARD_IP := $(shell grep -E '^BOARD_IP\s*[?:]?=' $(BUILD_DIR)/conf/local.conf | head -1 | sed 's/.*= *"\(.*\)".*/\1/')
        BOARD_GATEWAY := $(shell grep -E '^BOARD_GATEWAY\s*[?:]?=' $(BUILD_DIR)/conf/local.conf | head -1 | sed 's/.*= *"\(.*\)".*/\1/')
        BOARD_NETMASK := $(shell grep -E '^BOARD_NETMASK\s*[?:]?=' $(BUILD_DIR)/conf/local.conf | head -1 | sed 's/.*= *"\(.*\)".*/\1/')
        NFS_SERVER := $(shell grep -E '^NFS_SERVER\s*[?:]?=' $(BUILD_DIR)/conf/local.conf | head -1 | sed 's/.*= *"\(.*\)".*/\1/')
        NFS_ROOT := $(shell grep -E '^NFS_ROOT\s*[?:]?=' $(BUILD_DIR)/conf/local.conf | head -1 | sed 's/.*= *"\(.*\)".*/\1/')
        
        # Validate all variables are defined (only if file exists and we're not in setup)
        ifeq ($(BOARD_IP),)
            $(error BOARD_IP is not defined in $(BUILD_DIR)/conf/local.conf. Please define it in conf/local.conf.template or build/conf/local.conf)
        endif
        ifeq ($(BOARD_GATEWAY),)
            $(error BOARD_GATEWAY is not defined in $(BUILD_DIR)/conf/local.conf. Please define it in conf/local.conf.template or build/conf/local.conf)
        endif
        ifeq ($(BOARD_NETMASK),)
            $(error BOARD_NETMASK is not defined in $(BUILD_DIR)/conf/local.conf. Please define it in conf/local.conf.template or build/conf/local.conf)
        endif
        ifeq ($(NFS_SERVER),)
            $(error NFS_SERVER is not defined in $(BUILD_DIR)/conf/local.conf. Please define it in conf/local.conf.template or build/conf/local.conf)
        endif
        ifeq ($(NFS_ROOT),)
            $(error NFS_ROOT is not defined in $(BUILD_DIR)/conf/local.conf. Please define it in conf/local.conf.template or build/conf/local.conf)
        endif
    else
        $(error $(BUILD_DIR)/conf/local.conf does not exist. Please run 'make setup-env' first to create it from conf/local.conf.template)
    endif
endif

# BitBake parallelism configuration
# Use 80% of available CPU cores for optimal parallelism
NUM_CORES := $(shell nproc)
BB_NUMBER_THREADS ?= $(shell cores=$$(nproc); echo $$(( cores * 80 / 100 )) | awk '{if (int($$1) < 1) print 1; else print int($$1)}')

# Xilinx Yocto Manifest configuration
# For Xilinx tools 2025.2, use repo tool with manifests (recommended approach)
# See: https://xilinx.github.io/kria-apps-docs/yocto/build/html/docs/yocto_kria_support.html
XILINX_RELEASE_TAG ?= rel-v2025.2
YOCTO_MANIFEST_URL = https://github.com/Xilinx/yocto-manifests.git

# Distribution selection for 2025.2:
# - default-edf.xml: EDF Distribution (for .wic images and general builds)
# Using EDF distribution
YOCTO_MANIFEST_FILE ?= default-edf.xml

# Configuration file paths
CONFIG_DIR = $(CURDIR)/meta-kr260/configs
KERNEL_CONFIG = $(CONFIG_DIR)/kernel.config

.PHONY: help setup-sources setup-env build-kernel compile-kernel create-image-ub build-rootfs build-sdk build-all clean-all clean-build clean-sstate
.PHONY: configure-kernel configure-rootfs save-config save-config-kernel restore-configs bitbake-shell install-kernel install-rootfs

help:
	@echo "Xilinx Kria KR260 Development Kit Yocto Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  setup-sources    - Download and setup Yocto source repositories"
	@echo "  setup-env        - Setup build environment (run after setup-sources)"
	@echo ""
	@echo "Configuration targets:"
	@echo "  configure-kernel - Configure kernel using menuconfig"
	@echo "  configure-rootfs - Configure rootfs (edit image recipe)"
	@echo "  save-config      - Save all configs from build to meta-kr260/configs"
	@echo "  save-config-kernel - Save kernel config from build to meta-kr260/configs"
	@echo "  restore-configs  - Restore saved configs from meta-kr260/configs to build"
	@echo ""
	@echo "Build targets:"
	@echo "  compile-kernel  - Build kernel via bitbake"
	@echo "  create-image-ub - Create FIT image (image.ub) from built kernel"
	@echo "  build-kernel    - Build kernel and create image.ub (compile-kernel + create-image-ub)"
	@echo "  build-rootfs    - Build rootfs tar.gz"
	@echo "  build-sdk       - Build SDK toolchain"
	@echo "  build-all       - Build kernel, rootfs, and SDK"
	@echo "  bitbake-shell   - Open interactive bitbake shell"
	@echo ""
	@echo "Clean targets:"
	@echo "  clean-sstate        - Clean sstate cache for U-Boot"
	@echo "  clean-build         - Clean entire build directory"
	@echo "  clean-all           - Clean build, downloads, and sstate"
	@echo ""
	@echo "Install targets:"
	@echo "  install-kernel  - Install image.ub to TFTP server"
	@echo "  install-rootfs  - Install rootfs to NFS server"
	@echo ""
	@echo "Configuration:"
	@echo "  MACHINE=$(MACHINE)"
	@echo "  YOCTO_VERSION=$(YOCTO_VERSION)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"
	@echo "  BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) (80% of $(NUM_CORES) cores)"


setup-sources:
	@echo "Setting up Yocto source repositories using repo tool..."
	@echo "Xilinx release: $(XILINX_RELEASE_TAG)"
	@echo "Manifest file: $(YOCTO_MANIFEST_FILE)"
	@echo ""
	@echo "Checking for repo tool..."
	@command -v repo >/dev/null 2>&1 || { \
		echo "Error: 'repo' tool is required but not installed."; \
		echo "Install it with:"; \
		echo "  mkdir -p ~/bin"; \
		echo "  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo"; \
		echo "  chmod a+x ~/bin/repo"; \
		echo "  export PATH=~/bin:$$PATH"; \
		echo ""; \
		echo "Or on Ubuntu:"; \
		echo "  sudo apt-get install -y repo"; \
		exit 1; \
	}
	@mkdir -p $(SOURCES_DIR)
	@cd $(SOURCES_DIR) && \
	if [ ! -d ".repo" ]; then \
		echo "Initializing repo with Xilinx manifest..."; \
		repo init -u $(YOCTO_MANIFEST_URL) -b $(XILINX_RELEASE_TAG) -m $(YOCTO_MANIFEST_FILE); \
	fi
	@cd $(SOURCES_DIR) && \
	echo "Syncing all repositories (this may take a while)..." && \
	repo sync -j$$(nproc) || repo sync
	@echo ""
	@echo "Source repositories setup complete!"
	@echo "Repositories are located in: $(SOURCES_DIR)"

setup-env: setup-sources
	@echo "Setting up build environment..."
	@mkdir -p $(BUILD_DIR)/conf
	@echo "Creating/updating local.conf..."
	@cp conf/local.conf.template $(BUILD_DIR)/conf/local.conf; \
	sed -i 's|@MACHINE@|$(MACHINE)|g' $(BUILD_DIR)/conf/local.conf; \
	sed -i 's|@DL_DIR@|$(DL_DIR)|g' $(BUILD_DIR)/conf/local.conf; \
	sed -i 's|@SSTATE_DIR@|$(SSTATE_DIR)|g' $(BUILD_DIR)/conf/local.conf; \
	sed -i 's|@TMPDIR@|$(TMPDIR)|g' $(BUILD_DIR)/conf/local.conf
	@echo "Creating/updating bblayers.conf..."
	@cp conf/bblayers.conf.template $(BUILD_DIR)/conf/bblayers.conf; \
	sed -i 's|@SOURCES_DIR@|$(SOURCES_DIR)|g' $(BUILD_DIR)/conf/bblayers.conf; \
	sed -i 's|@CURDIR@|$(CURDIR)|g' $(BUILD_DIR)/conf/bblayers.conf
	@echo "Machine configuration is provided by the meta-kria layer (k26-smk-kr-sdt)"
	@echo "Build environment setup complete!"
	@echo ""

# Restore saved configurations before building
# This function is called automatically by build targets
# Note: U-Boot config is automatically applied via u-boot-xlnx_%.bbappend during build
restore-configs: setup-env
	@echo "Checking saved configurations from meta-kr260/configs..."
	@mkdir -p $(CONFIG_DIR)
	@# Restore kernel config if it exists
	@if [ -f "$(KERNEL_CONFIG)" ]; then \
		echo "  Restoring kernel config..."; \
		cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) > /dev/null 2>&1 && \
		MACHINE=$(MACHINE) BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) bitbake virtual/kernel -c configure" && \
		TMP_DIR=$(BUILD_DIR)/tmp-glibc && \
		KERNEL_CONFIG_FILE=$$(find $$TMP_DIR/work -type f -path "*/linux-xlnx/*/linux-*/.config" 2>/dev/null | head -1) && \
		if [ -n "$$KERNEL_CONFIG_FILE" ] && [ -f "$(KERNEL_CONFIG)" ]; then \
			cp $(KERNEL_CONFIG) $$KERNEL_CONFIG_FILE && \
			echo "    ✓ Kernel config restored to $$KERNEL_CONFIG_FILE"; \
		fi; \
	else \
		echo "  ℹ No saved kernel config found, using default configuration"; \
	fi
	@echo "Configuration check complete!"


# Configure kernel using menuconfig
configure-kernel: setup-env
	@echo "Configuring kernel..."
	@echo "Ensuring kernel is configured first..."
	@cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) > /dev/null 2>&1 && \
		MACHINE=$(MACHINE) BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) bitbake virtual/kernel -c configure" || true
	@echo "Locating kernel .config in build tree..."
	@bash -c '\
		TMP_DIR=$(BUILD_DIR)/tmp-glibc; \
		KERNEL_CONFIG_PATH=$$(find $$TMP_DIR/work -type f -path "*/linux-xlnx/*/linux-*/.config" 2>/dev/null | head -1); \
		if [ -z "$$KERNEL_CONFIG_PATH" ]; then \
			echo "  ✗ Unable to locate kernel .config under $$TMP_DIR/work"; \
		else \
			echo "  ✓ Kernel .config located at $$KERNEL_CONFIG_PATH"; \
			if [ -f "$(KERNEL_CONFIG)" ]; then \
				cp "$(KERNEL_CONFIG)" "$$KERNEL_CONFIG_PATH"; \
				echo "    → Copied saved config from $(KERNEL_CONFIG)"; \
			else \
				echo "    ℹ No saved kernel config found at $(KERNEL_CONFIG); using existing build config"; \
			fi; \
		fi'
	@echo "Launching kernel menuconfig via BitBake..."
	@cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) && \
		MACHINE=$(MACHINE) BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) bitbake virtual/kernel -c menuconfig"
	@echo "Menuconfig completed."
	@echo "Saving kernel configuration..."
	@$(MAKE) save-config-kernel || echo "Note: Run 'make save-config-kernel' manually to save the configuration."
	@echo ""
	@echo "Kernel configuration complete!"
	@echo "Configuration saved to meta-kr260/configs/kernel.config"

# Configure rootfs (open image recipe for editing)
configure-rootfs: setup-env
	@echo "Configuring rootfs..."
	@echo "Rootfs configuration is done via the image recipe:"
	@echo "  $(CURDIR)/meta-kr260/recipes-core/images/kria-image-kr260.bb"
	@echo ""
	@echo "You can also configure via local.conf or machine config."
	@echo "After making changes, run 'make save-config' to save configuration."

# Save kernel configuration from build to meta-kr260/configs
save-config-kernel: setup-env
	@echo "Saving kernel configuration to meta-kr260/configs..."
	@mkdir -p $(CONFIG_DIR)
	@# Use tmp-glibc directory specifically (main build tmp directory)
	@TMP_DIR=$(BUILD_DIR)/tmp-glibc && \
	if [ ! -d "$$TMP_DIR" ]; then \
		echo "  ✗ Error: $(BUILD_DIR)/tmp-glibc not found. Run a build first."; \
		exit 1; \
	fi && \
	echo "  Searching in: $$TMP_DIR/work"
	@# Save kernel config - search for .config file directly in linux-xlnx work directories
	@TMP_DIR=$(BUILD_DIR)/tmp-glibc && \
	KERNEL_CONFIG_FILE=$$(find $$TMP_DIR/work -type f -path "*/linux-xlnx/*/linux-*/.config" 2>/dev/null | head -1) && \
	if [ -n "$$KERNEL_CONFIG_FILE" ] && [ -f "$$KERNEL_CONFIG_FILE" ]; then \
		cp $$KERNEL_CONFIG_FILE $(KERNEL_CONFIG) && \
		echo "  ✓ Saved kernel config to $(KERNEL_CONFIG)"; \
		echo "    Source: $$KERNEL_CONFIG_FILE"; \
	else \
		echo "  ✗ Kernel config not found (run 'make configure-kernel' first)"; \
		exit 1; \
	fi
	@echo "Kernel configuration save complete!"

# Save all current configurations from build to meta-kr260/configs
save-config: save-config-kernel
	@echo ""
	@# Save rootfs config (image recipe)
	@if [ -f "$(CURDIR)/meta-kr260/recipes-core/images/kria-image-kr260.bb" ]; then \
		echo "  ℹ Rootfs configuration is in meta-kr260/recipes-core/images/kria-image-kr260.bb"; \
	fi
	@echo "All configuration saves complete!"


compile-kernel: restore-configs
	@echo "Building kernel..."
	@cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) > /dev/null 2>&1 && MACHINE=$(MACHINE) BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) bitbake virtual/kernel"
	@echo "Kernel build complete!"

create-image-ub:
	@echo "Creating image.ub from kernel image..."
	@DEPLOY_DIR=$(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE) && \
	KERNEL_IMAGE=$$(find $$DEPLOY_DIR -name "Image--*.bin" -type f | head -1) && \
	if [ -z "$$KERNEL_IMAGE" ]; then \
		echo "Error: Kernel Image file not found in $$DEPLOY_DIR"; \
		exit 1; \
	fi && \
	echo "Found kernel image: $$KERNEL_IMAGE" && \
	TMP_DIR=$$(mktemp -d) && \
	trap "rm -rf $$TMP_DIR" EXIT && \
	echo "Copying and gzipping kernel image..." && \
	cp "$$KERNEL_IMAGE" "$$TMP_DIR/Image.bin" && \
	gzip "$$TMP_DIR/Image.bin" && \
	echo "Generating system.dtb from dts/Makefile..." && \
	$(MAKE) -C dts system.dtb BOARD_IP=$(BOARD_IP) BOARD_GATEWAY=$(BOARD_GATEWAY) BOARD_NETMASK=$(BOARD_NETMASK) NFS_SERVER=$(NFS_SERVER) NFS_ROOT=$(NFS_ROOT) && \
	cp dts/system.dtb "$$TMP_DIR/system.dtb" && \
	echo "DTB file generated successfully!" && \
	cp "$(CURDIR)/tools/image.its" "$$TMP_DIR/image.its" && \
	echo "Creating image.ub with mkimage..." && \
	cd $$TMP_DIR && \
	mkimage -f image.its -A arm64 -O linux -T kernel image.ub && \
	if [ ! -f "$$TMP_DIR/image.ub" ]; then \
		echo "Error: mkimage failed to create image.ub"; \
		exit 1; \
	fi && \
	cp "$$TMP_DIR/image.ub" "$$DEPLOY_DIR/image.ub" && \
	echo "image.ub created successfully!" && \
	BUILD_INFO="kernel" && \
	if [ -n "$$OVERLAY_FILE" ] && [ -f "$$OVERLAY_FILE" ]; then \
		BUILD_INFO="$$BUILD_INFO, DTB with overlay"; \
	else \
		BUILD_INFO="$$BUILD_INFO, DTB"; \
	fi && \
	echo "  - Includes $$BUILD_INFO" && \
	echo "Output: $$DEPLOY_DIR/image.ub"
	@echo ""
	@echo "Copy image.ub to TFTP server:"
	@echo "  cp $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/image.ub /tftpboot/"

# Convenience target: build kernel and create FIT image
build-kernel: compile-kernel create-image-ub
	@echo ""
	@echo "Kernel build and FIT image creation complete!"

build-rootfs: restore-configs
	@echo "Building rootfs.tar.gz with PYNQ and Jupyter..."
	@cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) > /dev/null 2>&1 && MACHINE=$(MACHINE) BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) bitbake kria-image-kr260"
	@echo "Rootfs build complete!"
	@echo "Output: $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/kria-image-kr260-$(MACHINE).rootfs.tar.gz"
	@echo ""
	@echo "Extract rootfs to NFS server:"
	@echo "  sudo tar -xzf $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/kria-image-kr260-$(MACHINE).rootfs.tar.gz -C $(NFS_ROOT)"

build-sdk: setup-env
	@echo "Building SDK toolchain..."
	@cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) > /dev/null 2>&1 && MACHINE=$(MACHINE) BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) bitbake kria-image-kr260 -c populate_sdk"
	@echo "SDK toolchain build complete!"
	@mv $(BUILD_DIR)/tmp-glibc/deploy/sdk/*toolchain*.sh $(BUILD_DIR)/tmp-glibc/deploy/sdk/kria-toolchain-kr260-sdk.sh
	@echo "Output: $(BUILD_DIR)/tmp-glibc/deploy/sdk/kria-toolchain-kr260-sdk.sh"

bitbake-shell: setup-env
	@echo "Opening bitbake shell..."
	@echo "Environment variables:"
	@echo "  MACHINE=$(MACHINE)"
	@echo "  BB_NUMBER_THREADS=$(BB_NUMBER_THREADS)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"
	@echo ""
	@echo "You can now run bitbake commands directly."
	@echo "Example: bitbake u-boot-xlnx"
	@echo ""
	@cd $(SOURCES_DIR) && \
		bash -c "source edf-init-build-env $(BUILD_DIR) && \
		export MACHINE=$(MACHINE) && \
		export BB_NUMBER_THREADS=$(BB_NUMBER_THREADS) && \
		bash"

build-all: build-kernel build-rootfs build-sdk
	@echo "All builds complete!"

clean-sstate:
	@echo "Cleaning sstate cache and orphaned files for u-boot-xlnx..."
	@find $(BUILD_DIR)/tmp-glibc/sstate-control -name "*u-boot-xlnx*" -type f -delete 2>/dev/null || true
	@find $(SSTATE_DIR) -name "*u-boot-xlnx*" -type f -delete 2>/dev/null || true
	@rm -rf $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/u-boot* 2>/dev/null || true
	@rm -rf $(BUILD_DIR)/tmp-glibc/pkgdata/$(MACHINE)/u-boot-xlnx* 2>/dev/null || true
	@rm -rf $(BUILD_DIR)/tmp-glibc/sysroots-components/*/u-boot-xlnx 2>/dev/null || true
	@echo "Sstate cache and orphaned files cleaned! Rebuild u-boot-xlnx to regenerate:"
	@echo "  cd $(SOURCES_DIR) && source edf-init-build-env $(BUILD_DIR) && MACHINE=$(MACHINE) bitbake u-boot-xlnx -c cleanall && bitbake u-boot-xlnx"

clean-build:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned!"

clean-all: clean-build
	@echo "Cleaning all directories..."
	@rm -rf $(DL_DIR) $(SSTATE_DIR)
	@rm -rf $(SOURCES_DIR)
	@echo "All directories cleaned!"

install-kernel:
	@if [ ! -f "$(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/image.ub" ]; then \
		echo "Error: image.ub not found. Run 'make build-kernel' first."; \
		exit 1; \
	fi
	@echo "Installing kernel to TFTP server..."
	@sudo cp $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/image.ub /tftpboot/
	@echo "Kernel installed to /tftpboot/image.ub"

install-rootfs:
	@if [ ! -f "$(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/kria-image-kr260-$(MACHINE).rootfs.tar.gz" ]; then \
		echo "Error: rootfs.tar.gz not found. Run 'make build-rootfs' first."; \
		exit 1; \
	fi
	@echo "Installing rootfs to NFS server..."
	@sudo rm -rf $(NFS_ROOT)
	@sudo mkdir -p $(NFS_ROOT)
	@sudo tar -xzf $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)/kria-image-kr260-$(MACHINE).rootfs.tar.gz -C $(NFS_ROOT)
	@echo "Rootfs installed to $(NFS_ROOT)"
