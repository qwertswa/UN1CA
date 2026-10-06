ADD_SNAP_LIB()
{
    local REL="$1"
    local SRC

    if [ -f "$FW_PATH/vendor/$REL" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "$REL" 0 0 644 "u:object_r:vendor_file:s0"
        return 0
    fi

    for SRC in dm1qxxx dm2qxxx dm3qxxx; do
        if [ -f "$PREBUILTS_DIR/$SRC/vendor/$REL" ]; then
            LOGW "$REL not present in the target firmware; using prebuilts/samsung/$SRC"
            ADD_TO_WORK_DIR "$SRC" "vendor" "$REL" 0 0 644 "u:object_r:vendor_file:s0"
            return 0
        fi
    done

    LOGW "$REL Not found in firmware or prebuilts; skipped.."
    find "$FW_PATH" "$PREBUILTS_DIR" -name "$(basename "$REL")" 2> /dev/null | head -n 5 | sed 's/^/      /' >&2 || true
}

# Helper: Add Snap HAL lib (same_process_hal_file)
ADD_SNAP_HAL_LIB()
{
    local REL="$1"
    local SRC

    if [ -f "$FW_PATH/vendor/$REL" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "$REL" 0 0 644 "u:object_r:same_process_hal_file:s0"
        return 0
    fi

    for SRC in dm1qxxx dm2qxxx dm3qxxx; do
        if [ -f "$PREBUILTS_DIR/$SRC/vendor/$REL" ]; then
            LOGW "$REL not present in the target firmware; using prebuilts/samsung/$SRC"
            ADD_TO_WORK_DIR "$SRC" "vendor" "$REL" 0 0 644 "u:object_r:same_process_hal_file:s0"
            return 0
        fi
    done

    LOGW "$REL Not found in firmware or prebuilts; skipped.."
    find "$FW_PATH" "$PREBUILTS_DIR" -name "$(basename "$REL")" 2> /dev/null | head -n 5 | sed 's/^/      /' >&2 || true
}

ADD_TO_WORK_DIR "dm1qxxx" "vendor" "bin/hw/vendor.samsung.hardware.securesnap-service" 0 2000 755 "u:object_r:hal_securesnap_default_exec:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "bin/hw/vendor.samsung.hardware.snap-service" 0 2000 755 "u:object_r:snap_hidl_exec:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "bin/snap_utility_64" 0 2000 755 "u:object_r:snap_utility_exec:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "bin/snaplite_utility_64" 0 2000 755 "u:object_r:snap_utility_exec:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/init/snap_utility.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/init/snaplite_utility.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/init/vendor.samsung.hardware.securesnap-lazy.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/init/vendor.samsung.hardware.snap-lazy.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/snap_gpu_kernel_64.bin" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/snaplite_cache.bin" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/vintf/manifest/vendor.samsung.hardware.securesnap-default.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "etc/vintf/manifest/vendor.samsung.hardware.snap-default.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_SNAP_HAL_LIB "lib64/libc++_shared.so"
ADD_SNAP_HAL_LIB "lib64/libsnap_compute.so"
ADD_SNAP_HAL_LIB "lib64/libsnap_compute_wrapper.so"
ADD_SNAP_HAL_LIB "lib64/libsnap_vndk.so"
ADD_SNAP_HAL_LIB "lib64/libsnaplite_native.so"
ADD_SNAP_HAL_LIB "lib64/libsnaplite_wrapper.so"
ADD_SNAP_LIB "lib64/libsnap_compute_secure.so"
ADD_SNAP_LIB "lib64/libsnap_compute_wrapper_secure.so"
ADD_SNAP_LIB "lib64/libsnap_qnn.so"
ADD_SNAP_LIB "lib64/libsnap_vndk_secure.so"
ADD_SNAP_LIB "lib64/libsnaplite_native_secure.so"
ADD_SNAP_LIB "lib64/libsnaplite_wrapper_secure.so"
ADD_SNAP_LIB "lib64/libsnapmw.so"
ADD_SNAP_LIB "lib64/vendor.samsung.hardware.snap-V1-ndk.so"
ADD_SNAP_LIB "lib64/snap/libQnnHtp.so"
ADD_SNAP_LIB "lib64/snap/libQnnHtpV73Stub.so"
ADD_SNAP_LIB "lib64/snap/libQnnSystem.so"
