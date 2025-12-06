# Override image-recovery sources for the KR260 machine
# In 2025.2, image recovery is pulled from artifactory (cannot be generated in SDT flow)
#
# The recipe uses IR_PATH and WEB_PATH with machine-specific overrides
# We pin k26-smk-kr-sdt to known-good URLs

COMPATIBLE_MACHINE:k26-smk-kr-sdt = "${MACHINE}"

# Use known image-recovery paths (direct URLs to avoid expansion issues)
IR_PATH:k26-smk-kr-sdt = 'https://edf.amd.com/sswreleases/rel-v2025.2/image-recovery/2025.2/10090801/ImgRecovery.elf'
WEB_PATH:k26-smk-kr-sdt = 'https://edf.amd.com/sswreleases/rel-v2025.2/image-recovery/2025.2/10090801/web.img'

# Also set the SHA256 checksums
SRC_URI[k26-smk-kr-sdt_ir.sha256sum] = 'f0eebf410b3397b70e2aa3f33d16cdb31e1699b64e75cbb0a2b7a00364f4ded5'
SRC_URI[k26-smk-kr-sdt_web.sha256sum] = '0825518aea24c3104a58b0f847436db03a92d8d4366baad6594c4d03de09d8cb'
