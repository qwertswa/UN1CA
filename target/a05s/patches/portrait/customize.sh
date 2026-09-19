# SNPE libs
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib/rfsa/adsp/libSnpeHtpV73Skel.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libSNPE.so" 0 0 644 "u:object_r:same_process_hal_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libSnpeCpu.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libSnpeGpu.so" 0 0 644 "u:object_r:same_process_hal_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libSnpeHtpV73Stub.so" 0 0 644 "u:object_r:same_process_hal_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libsnpe_dsp_domains_v3.so" 0 0 644 "u:object_r:same_process_hal_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libsnpe_wrapper.so" 0 0 644 "u:object_r:same_process_hal_file:s0"
ADD_TO_WORK_DIR "dm1qxxx" "vendor" "lib64/libsnpemw.so" 0 0 644 "u:object_r:vendor_file:s0"

# SNPE HACK
SET_PROP "vendor" "ro.hardware.chipname" "sm6225"
