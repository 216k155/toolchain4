#!/bin/bash

# Files I can't find in on opensource.apple.com :
# include/mach/mach_port.h
# ... this is because they're made from
#     cd /usr/src/toolchain4/cctools2odcctools/sdkroot_remake/xnu-2050.18.24/osfmk/mach
#     make SRCROOT=../..
# ... /bin/sh: xcodebuild: command not found
#     make: /usr/bin/xcrun: Command not found
#     make: /usr/bin/xcrun: Command not found
#     ... lots of that ...
#     /bin/sh: arch: command not found
#     ../../makedefs/MakeInc.def:211: *** Could not determine INSTALL_ARCH_DEFAULT. Stop.

set +e

. ../bash-tools.sh

# For dyld.h.
DYLDNAME=dyld
#DYLDVERS=195.5
DYLDVERS=210.2.3
DYLDDISTFILE=${DYLDNAME}-${DYLDVERS}.tar.gz
#TARBALLS_URL=http://www.opensource.apple.com/tarballs
TARBALLS_URL=$HOME/Dropbox/darwin-compilers-work/tarballs
OSXVER=10.7
LIBCVERS=825.25
LIBMVERS=2026
LIBSYSTEMVERS=169.3
LIBUNWINDVERS=30
# XNU is weird. Some versions have arm bits in, others don't.
XNUVERS=2050.18.24
#XNUVERS=1699.32.7
#XNUVERS=1228.9.59
#includes libkern/ppc/OSByteOrder.h (and libkern/arm/OSByteOrder.h) but is missing bsd/i386/limits.h, bsd/i386/_limits.h and libkern/libkern/OSKextLib.h
#XNUVERS=1228
# Older architecture (e.g. http://www.opensource.apple.com/tarballs/architecture/architecture-254.0.5.tar.gz)
#  are about 3x bigger than 262 (53k vs 18k)??
ARCHITECTUREVERS=258
#ARCHITECTUREVERS=254.0.5
#ARCHITECTUREVERS=262
# The goal is to find every file in:
OSXSDKROOTPATCH=$PWD/0100-add_sdkroot_headers.patch
# There's some files that are patched in this patch file:
# b/include/architecture/i386/fpu.h
# b/include/architecture/i386/frame.h
# ...  find out why ...


# The only place I can find thread_act.h is in chameleon sources?
# Well, it's probably an idea to determine the minimum set of headers
# needed to build cctools at this point.

mkdir sdkroot_remake
pushd sdkroot_remake

mkdir sdk-orig
pushd sdk-orig
patch -p1 < $OSXSDKROOTPATCH
popd

download $TARBALLS_URL/Libc/Libc-$LIBCVERS.tar.gz
download $TARBALLS_URL/Libm/Libm-$LIBMVERS.tar.gz
download $TARBALLS_URL/Libsystem/Libsystem-$LIBSYSTEMVERS.tar.gz
download $TARBALLS_URL/xnu/xnu-$XNUVERS.tar.gz
download $TARBALLS_URL/architecture/architecture-$ARCHITECTUREVERS.tar.gz
download $TARBALLS_URL/libunwind/libunwind-$LIBUNWINDVERS.tar.gz

tar -xzf Libc-$LIBCVERS.tar.gz
tar -xzf Libm-$LIBMVERS.tar.gz
tar -xzf Libsystem-$LIBSYSTEMVERS.tar.gz
tar -xzf xnu-$XNUVERS.tar.gz
tar -xzf architecture-$ARCHITECTUREVERS.tar.gz
tar -xzf libunwind-$LIBUNWINDVERS.tar.gz

mkdir include-new

for FILE in alignment.h byte_order.h i386/alignment.h i386/asm_help.h i386/byte_order.h i386/cpu.h i386/desc.h i386/io.h i386/pio.h i386/reg_help.h i386/sel.h i386/table.h i386/tss.h; do
    mkdir -p $(dirname sdk-new/include/architecture/$FILE)
    cp architecture-$ARCHITECTUREVERS/$FILE sdk-new/include/architecture/$FILE
done

cp Libm-$LIBMVERS/Source/Intel/fenv.h sdk-new/include/architecture/i386/
cp Libm-$LIBMVERS/Source/Intel/math.h sdk-new/include/architecture/i386/
mkdir sdk-new/include/architecture/ppc/
cp Libm-$LIBMVERS/Source/PowerPC/fenv.h sdk-new/include/architecture/ppc/
cp Libm-$LIBMVERS/Source/PowerPC/math.h sdk-new/include/architecture/ppc/

# xnu/bsd doesn't have:
# i386/eflags.h i386/user_ldt.h
for FILE in i386/endian.h i386/fasttrap_isa.h i386/limits.h i386/param.h i386/profile.h i386/setjmp.h i386/signal.h i386/types.h i386/vmparam.h i386/_limits.h i386/_param.h i386/_structs.h i386/_types.h; do
    mkdir -p $(dirname sdk-new/include/$FILE)
    cp xnu-$XNUVERS/bsd/$FILE sdk-new/include/$FILE
done

for FILE in i386/eflags.h i386/user_ldt.h; do
    mkdir -p $(dirname sdk-new/include/$FILE)
    cp xnu-$XNUVERS/osfmk/$FILE sdk-new/include/$FILE
done

for FILE in i386/_OSByteOrder.h i386/OSByteOrder.h machine/OSByteOrder.h _OSByteOrder.h OSAtomic.h OSByteOrder.h OSDebug.h OSKextLib.h OSReturn.h OSTypes.h; do
    mkdir -p $(dirname sdk-new/include/libkern/$FILE)
    cp xnu-$XNUVERS/libkern/libkern/$FILE sdk-new/include/libkern/$FILE
done

cp Libc-$LIBCVERS/include/libkern/OSCacheControl.h sdk-new/include/libkern/OSCacheControl.h
cp Libc-$LIBCVERS/include/libkern/OSAtomic.h       sdk-new/include/libkern/OSAtomic.h


# include/mach/i386/thread_state.h important looking difference.
# #define I386_THREAD_STATE_MAX	(224)    /* Size of biggest state possible */
# vs
# #define I386_THREAD_STATE_MAX	(144)    /* Size of biggest state possible */
# missing: include/mach/i386/asm.h include/mach/i386/task.h include/mach/i386/thread_act.h
#  extras: include/mach/i386/flipc_dep.h include/mach/i386/Makefile include/mach/i386/syscall_sw.h
#  extras: include/mach/machine/Makefile include/mach/machine/syscall_sw.h
# missing: include/mach/x86_64/* -> task.h, thread_act.h
# missing: include/mach/clock.h include/mach/clock_priv.h include/mach/clock_reply.h include/mach/exc.h include/mach/host_priv.h include/mach/host_sercurity.h
#  extras: include/mach/alert.h include/mach/branch_predicates.h include/mach/events_info.h flipc_cb.h flipc_debug.h flipc_device.h flipc_locks.h flipc_types.h
cp -rf xnu-$XNUVERS/osfmk/mach       sdk-new/include/
cp -rf xnu-$XNUVERS/osfmk/mach_debug sdk-new/include/

mkdir -p sdk-new/include/machine
cp xnu-$XNUVERS/bsd/machine/endian.h sdk-new/include/machine/
cp xnu-$XNUVERS/bsd/machine/_types.h sdk-new/include/machine/
cp xnu-$XNUVERS/bsd/machine/types.h  sdk-new/include/machine/

mkdir -p sdk-new/include/mach-o
cp libunwind-$LIBUNWINDVERS/include/mach-o/compact_unwind_encoding.h sdk-new/include/mach-o

mkdir -p sdk-new/include/sys
cp xnu-$XNUVERS/bsd/sys/_types.h sdk-new/include/sys/

popd

exit 0

include/ar.h
# Can be gotten from architecture-$ARCHITECTUREVERS.tar.gz
# except [X] which can (probably be gotten from Libm)
include/architecture/alignment.h
include/architecture/byte_order.h          [This is more recent (2008) in the SDK... "Please note that the byte ordering functions in this file are deprecated."]
include/architecture/i386/alignment.h
include/architecture/i386/asm_help.h
include/architecture/i386/byte_order.h
include/architecture/i386/cpu.h
include/architecture/i386/desc.h
[X] include/architecture/i386/fenv.h
include/architecture/i386/io.h
[X] include/architecture/i386/math.h
include/architecture/i386/pio.h]
include/architecture/i386/reg_help.h
include/architecture/i386/sel.h
include/architecture/i386/table.h
include/architecture/i386/tss.h
[X] include/architecture/ppc/fenv.h
[X] include/architecture/ppc/math.h

# Can maybe be gotten from xnu-2050.18.24\EXTERNAL_HEADERS
include/Availability.h
include/AvailabilityInternal.h
include/AvailabilityMacros.h

include/CommonCrypto/CommonDigest.h -> not needed.
include/i386/eflags.h
include/i386/endian.h
include/i386/fasttrap_isa.h
include/i386/limits.h
include/i386/param.h
include/i386/profile.h
include/i386/setjmp.h
include/i386/signal.h
include/i386/types.h
include/i386/user_ldt.h
include/i386/vmparam.h
include/i386/_limits.h
include/i386/_param.h
include/i386/_structs.h
include/i386/_types.h

# All these can be gotten from xnu-2050.18.24/libkern/libkern
# OSAtomic.h is fairly different though, and arm include is missing from xnu.
# OSTypes.h on the other hand, has || defined(__arm__) missing from Mac OSXSDK.
include/libkern/i386/OSByteOrder.h
include/libkern/i386/_OSByteOrder.h
include/libkern/machine/OSByteOrder.h
include/libkern/OSAtomic.h
include/libkern/OSByteOrder.h
include/libkern/OSCacheControl.h
include/libkern/OSDebug.h
include/libkern/OSKextLib.h
include/libkern/OSReturn.h
include/libkern/OSTypes.h
include/libkern/_OSByteOrder.h

include/libunwind.h

# Err... xnu-2050.7.9/osfmk/mach                 [a]
# or.... xnu-2050.7.9/libsyscall/mach/mach       [b]
# or.... MISSING                                 [X]

[a] include/mach/audit_triggers.defs
[a] include/mach/boolean.h
[a] include/mach/bootstrap.h
[a] include/mach/clock.defs
[X] include/mach/clock.h
[a] include/mach/clock_priv.defs
[X] include/mach/clock_priv.h
[a] include/mach/clock_reply.defs
[X] include/mach/clock_reply.h
[a] include/mach/clock_types.defs
[a] include/mach/clock_types.h
[a] include/mach/error.h
[a] include/mach/exc.defs
[X] include/mach/exc.h
[a] include/mach/exception.h
[a] include/mach/exception_types.h          [a] adds EXC_RESOURCE		11
[a] include/mach/host_info.h                [a] adds struct _processor_statistics_np and struct host_basic_info_old
[a] include/mach/host_notify.h
[a] include/mach/host_notify_reply.defs
[X] include/mach/host_priv.defs             [a] does not contain routine host_load_symbol_table(
[X] include/mach/host_priv.h
[a] include/mach/host_reboot.h
[a] include/mach/host_security.defs
[X] include/mach/host_security.h
[a] include/mach/host_special_ports.h       [a] adds #define HOST_GSSD_PORT			(12 + HOST_MAX_SPECIAL_KERNEL_PORT)

include/mach/i386/asm.h
include/mach/i386/boolean.h
include/mach/i386/exception.h
include/mach/i386/fp_reg.h
include/mach/i386/kern_return.h
include/mach/i386/machine_types.defs
include/mach/i386/ndr_def.h
include/mach/i386/processor_info.h
include/mach/i386/rpc.h
include/mach/i386/sdt_isa.h
include/mach/i386/task.h
[b] include/mach/i386/thread_act.h           [b] is missing #elif defined(__arm__) #include <mach/arm/thread_act.h>
include/mach/i386/thread_state.h
include/mach/i386/thread_status.h
include/mach/i386/vm_param.h
include/mach/i386/vm_types.h
include/mach/i386/_structs.h
include/mach/kern_return.h
include/mach/kmod.h
include/mach/ledger.defs
include/mach/ledger.h
include/mach/lock_set.defs
include/mach/lock_set.h
include/mach/mach.h
include/mach/machine/asm.h
include/mach/machine/boolean.h
include/mach/machine/exception.h
include/mach/machine/kern_return.h
include/mach/machine/machine_types.defs
include/mach/machine/ndr_def.h
include/mach/machine/processor_info.h
include/mach/machine/rpc.h
include/mach/machine/sdt.h
include/mach/machine/sdt_isa.h
include/mach/machine/thread_state.h
include/mach/machine/thread_status.h
include/mach/machine/vm_param.h
include/mach/machine/vm_types.h
[b] include/mach/mach_error.h
include/mach/mach_exc.defs
include/mach/mach_host.defs
include/mach/mach_host.h
include/mach/mach_init.h
[b] include/mach/mach_interface.h            #include <mach/ledger.h> missing from [b].
include/mach/mach_param.h
include/mach/mach_port.defs
include/mach/mach_port.h
include/mach/mach_syscalls.h
include/mach/mach_time.h
include/mach/mach_traps.h
include/mach/mach_types.defs
include/mach/mach_types.h
include/mach/mach_vm.defs
include/mach/mach_vm.h
include/mach/memory_object_types.h
include/mach/message.h
include/mach/mig.h
include/mach/mig_errors.h
include/mach/ndr.h
include/mach/notify.defs
include/mach/notify.h
include/mach/policy.h
include/mach/port.h
[b] include/mach/port_obj.h
include/mach/processor.defs
include/mach/processor.h
include/mach/processor_info.h
include/mach/processor_set.defs
include/mach/processor_set.h
include/mach/rpc.h
include/mach/sdt.h
include/mach/security.defs
include/mach/semaphore.h
include/mach/shared_memory_server.h
include/mach/shared_region.h
include/mach/std_types.defs
include/mach/std_types.h
[b] include/mach/sync.h
include/mach/sync_policy.h
include/mach/task.defs
[b] include/mach/task.h                  [b] is missing #elif defined(__arm__) #include <mach/arm/task.h>
include/mach/task_access.defs
include/mach/task_info.h
include/mach/task_ledger.h
include/mach/task_policy.h
include/mach/task_special_ports.h
include/mach/thread_act.defs
include/mach/thread_act.h
include/mach/thread_info.h
include/mach/thread_policy.h
include/mach/thread_special_ports.h
include/mach/thread_status.h
include/mach/thread_switch.h
include/mach/time_value.h
include/mach/vm_attributes.h
include/mach/vm_behavior.h
include/mach/vm_inherit.h
include/mach/vm_map.defs
include/mach/vm_map.h
include/mach/vm_param.h
include/mach/vm_prot.h
include/mach/vm_purgable.h
include/mach/vm_region.h
include/mach/vm_statistics.h
include/mach/vm_sync.h
[b] include/mach/vm_task.h
include/mach/vm_types.h
include/mach/x86_64/task.h
include/mach/x86_64/thread_act.h
include/mach-o/compact_unwind_encoding.h
include/machine/endian.h
include/machine/types.h
include/machine/_types.h
include/mach_debug/hash_info.h
include/mach_debug/ipc_info.h
include/mach_debug/lockgroup_info.h
include/mach_debug/mach_debug_types.h
include/mach_debug/page_info.h
include/mach_debug/vm_info.h
include/mach_debug/zone_info.h
include/sys/_types.h
include/TargetConditionals.h
ld64/include/mach/machine.h
ld64/include/mach-o/dyld-interposing.h
ld64/include/mach-o/dyld.h
ld64/include/mach-o/dyld_debug.h
ld64/include/mach-o/dyld_gdb.h
ld64/include/mach-o/dyld_images.h
ld64/include/mach-o/dyld_priv.h
libprunetrie/include/mach-o/compact_unwind_encoding.h
