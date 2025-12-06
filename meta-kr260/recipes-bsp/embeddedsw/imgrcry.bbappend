# Configure imgrcry for k26-smk-kr-sdt to find image-recovery binary
# The imgrcry recipe needs to wait for image-recovery to deploy
# The image-recovery recipe is built in the default multiconfig, not a separate one
# So we use IMGRCRY_DEPENDS (not IMGRCRY_MCDEPENDS) to ensure image-recovery deploys first
IMGRCRY_DEPENDS:k26-smk-kr-sdt = "image-recovery:do_deploy"

# Ensure the deploy directory is correct (use DEPLOY_DIR_IMAGE which is where image-recovery deploys)
# Remove any trailing slash to avoid double slashes in the path
IMGRCRY_DEPLOY_DIR:k26-smk-kr-sdt = "${@d.getVar('DEPLOY_DIR_IMAGE').rstrip('/')}"
IMGRCRY_IMAGE_NAME:k26-smk-kr-sdt = "image-recovery-${MACHINE}"
