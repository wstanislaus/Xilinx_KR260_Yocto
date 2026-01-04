# OpenCV bbappend for KR260 - Optimized for Robotics
# Restoring DNN and OpenCL for AI and GPU acceleration

# We keep contrib removed if you don't need experimental features (Sift/Surf)
PACKAGECONFIG:remove = " \
    contrib \
    openvino \
"

# Explicitly ensure these are IN if you want AI-based ball picking
PACKAGECONFIG:append = " dnn flatbuffers"

EXTRA_OECMAKE:append = " \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DWITH_ITT=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_OPENCL=ON \
    -DWITH_OPENVX=OFF \
    -DWITH_IPP=OFF \
    -DENABLE_NEON=ON \
    -DCPU_BASELINE=NEON \
"