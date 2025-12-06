# Configuration Files

This directory stores saved configuration files for U-Boot, kernel, and rootfs.

## Files

- `u-boot.config` - U-Boot configuration (.config file)
- `kernel.config` - Kernel configuration (.config file)
- `rootfs.config` - Rootfs configuration (not used, rootfs is configured via recipes)

## Usage

1. **Configure components:**
   ```bash
   make configure-uboot    # Opens U-Boot menuconfig
   make configure-kernel   # Opens kernel menuconfig
   make configure-rootfs   # Shows rootfs configuration location
   ```

2. **Save configurations:**
   ```bash
   make save-config        # Saves current configs from build to this directory
   ```

3. **Configurations are automatically restored** when building:
   - `make build-qspi`    # Restores U-Boot config
   - `make build-kernel`  # Restores kernel config
   - `make build-rootfs`  # Restores configs (if applicable)

## Manual Restore

To manually restore configurations:
```bash
make restore-configs
```

## Notes

- Configurations are saved from the build work directories after running menuconfig
- Saved configs are automatically restored before each build
- If no saved config exists, Yocto will use default configurations
