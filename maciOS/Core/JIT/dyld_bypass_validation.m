// Based on: https://blog.xpnsec.com/restoring-dyld-memory-loading
// https://github.com/xpn/DyldDeNeuralyzer/blob/main/DyldDeNeuralyzer/DyldPatch/dyldpatch.m

#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <sys/syscall.h>
#include <dirent.h>

#include "utils.h"

extern void EKJITLessHook(void* _target, void* _replacement, void** orig);

#define ASM(...) __asm__(#__VA_ARGS__)
// ldr x8, value; br x8; value: .ascii "\x41\x42\x43\x44\x45\x46\x47\x48"
static char patch[] = {0x88,0x00,0x00,0x58,0x00,0x01,0x1f,0xd6,0x1f,0x20,0x03,0xd5,0x1f,0x20,0x03,0xd5,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41};

// Signatures to search for
static char mmapSig[] = {0xB0, 0x18, 0x80, 0xD2, 0x01, 0x10, 0x00, 0xD4};
static char fcntlSig[] = {0x90, 0x0B, 0x80, 0xD2, 0x01, 0x10, 0x00, 0xD4};

extern void* __mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
extern int __fcntl(int fildes, int cmd, void* param);

typedef int (*fcntl_p)(int fildes, int cmd, void* param);
typedef void* (*mmap_p)(void *addr, size_t len, int prot, int flags, int fd, off_t offset);

// Originated from _kernelrpc_mach_vm_protect_trap
ASM(
.global _builtin_vm_protect \n
_builtin_vm_protect:     \n
    mov x16, #-0xe       \n
    svc #0x80            \n
    ret
);

static bool redirectFunction(char *name, void *patchAddr, void *target, void **orig) {
    EKJITLessHook(patchAddr, target, orig);
    
    NSLog(@"[DyldLVBypass] hook %s succeed!", name);
    return TRUE;
}

static bool searchAndPatch(char *name, char *base, char *signature, int length, void *target, void **orig) {
    char *patchAddr = NULL;
    
    for(int i=0; i < 0x100000; i++) {
        if (base[i] == signature[0] && memcmp(base+i, signature, length) == 0) {
            patchAddr = base + i;
            break;
        }
    }
    
    if (patchAddr == NULL) {
        NSLog(@"[DyldLVBypass] hook fails line %d", __LINE__);
        return FALSE;
    }
    
    NSLog(@"[DyldLVBypass] found %s at %p", name, patchAddr);
    return redirectFunction(name, patchAddr, target, orig);
}

static struct dyld_all_image_infos *_alt_dyld_get_all_image_infos(void) {
    static struct dyld_all_image_infos *result;
    if (result) {
        return result;
    }
    struct task_dyld_info dyld_info;
    mach_vm_address_t image_infos;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    kern_return_t ret;
    ret = task_info(mach_task_self_,
                    TASK_DYLD_INFO,
                    (task_info_t)&dyld_info,
                    &count);
    if (ret != KERN_SUCCESS) {
        return NULL;
    }
    image_infos = dyld_info.all_image_info_addr;
    result = (struct dyld_all_image_infos *)image_infos;
    return result;
}

void *getDyldBase(void) {
    return (void *)_alt_dyld_get_all_image_infos()->dyldImageLoadAddress;
}

// mmap

__attribute__((noinline,optnone,naked))
void BreakMarkJITMapping(uint64_t addr, size_t bytes) {
    asm("brk #0x69 \n"
        "ret");
}

char *file_path_with_length(const char *dir_path, int name_length) {
    DIR *dir = opendir(dir_path);
    if (!dir) return NULL;

    struct dirent *entry;
    char *result = NULL;

    while ((entry = readdir(dir)) != NULL) {
        if ((int)strlen(entry->d_name) == name_length) {
            size_t path_len = strlen(dir_path) + strlen(entry->d_name) + 2;
            result = (char *)malloc(path_len);
            if (result) {
                snprintf(result, path_len, "%s/%s", dir_path, entry->d_name);
            }
            break; // Return the first match
        }
    }

    closedir(dir);
    return result;
}

int ios_major_version(void) {
    NSOperatingSystemVersion os = [[NSProcessInfo processInfo] operatingSystemVersion];
    return (int)os.majorVersion;
}


static bool has_txm(void) {
    if (ios_major_version() < 19) {
        return false;
    }
    
    char *boot = file_path_with_length("/System/Volumes/Preboot", 36);
    if (boot) {
        char *boot_inner = file_path_with_length(boot, 96);
        if (boot_inner) {
            char txm_path[512];
            snprintf(txm_path, sizeof(txm_path),
                     "%s/usr/standalone/firmware/FUD/Ap,TrustedExecutionMonitor.img4", boot_inner);
            free(boot_inner);
            free(boot);
            return access(txm_path, F_OK) == 0;
        }
        free(boot);
    }

    char *fallback = file_path_with_length("/private/preboot", 96);
    if (fallback) {
        char txm_path[512];
        snprintf(txm_path, sizeof(txm_path),
                 "%s/usr/standalone/firmware/FUD/Ap,TrustedExecutionMonitor.img4", fallback);
        free(fallback);
        return access(txm_path, F_OK) == 0;
    }

    return false;
}

static void* common_hooked_mmap(mmap_p orig, void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
    void *map = orig(addr, len, prot, flags, fd, offset);
    if (map == MAP_FAILED && fd && (prot & PROT_EXEC)) {
        
        map = __mmap(addr, len, prot, flags | MAP_PRIVATE | MAP_ANON, 0, 0);
        if (has_txm()) {
            BreakMarkJITMapping((vm_address_t)map, len);
        }
        
        void *memoryLoadedFile = __mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, offset);
        // mirror `addr` (rx, JIT applied) to `mirrored` (rw)
        vm_address_t mirrored = 0;
        vm_prot_t cur_prot, max_prot;
        kern_return_t ret = vm_remap(mach_task_self(), &mirrored, len, 0, VM_FLAGS_ANYWHERE, mach_task_self(), (vm_address_t)map, false, &cur_prot, &max_prot, VM_INHERIT_SHARE);
        if(ret == KERN_SUCCESS) {
            vm_protect(mach_task_self(), mirrored, len, NO,
                    VM_PROT_READ | VM_PROT_WRITE);
            memcpy((void*)mirrored, memoryLoadedFile, len);
            vm_deallocate(mach_task_self(), mirrored, len);
        }
        munmap(memoryLoadedFile, len);
    }
    return map;
}


static void* hooked_dyld_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
    return common_hooked_mmap(__mmap, addr, len, prot, flags, fd, offset);
}

// fcntl

static int common_hooked_fcntl(fcntl_p orig, int fildes, int cmd, void *param) {
    if (cmd == F_ADDFILESIGS_RETURN) {
        char filePath[PATH_MAX];
        bzero(filePath, PATH_MAX);
        
        // Check if the file is our "in-memory" file
        if (__fcntl(fildes, F_GETPATH, filePath) != -1) {
            const char *homeDir = getenv("LC_HOME_PATH");
            if (!strncmp(filePath, homeDir, strlen(homeDir))) {
                fsignatures_t *fsig = (fsignatures_t*)param;
                // called to check that cert covers file.. so we'll make it cover everything ;)
                fsig->fs_file_start = 0xFFFFFFFF;
                return 0;
            }
        }
    }
    
    // Signature sanity check by dyld
    else if (cmd == F_CHECK_LV) {
        // Just say everything is fine
        return 0;
    }
    
    // If for another command or file, we pass through
    return orig(fildes, cmd, param);
}

static int hooked_dyld_fcntl(int fildes, int cmd, void *param) {
    return common_hooked_fcntl(__fcntl, fildes, cmd, param);
}

void init_bypassDyldLibValidation() {
    if (ios_major_version() < 19 || [[NSProcessInfo processInfo] isiOSAppOnMac]) {
        init_bypassDyldLibValidation18();
        return;
    }
    
    
    static BOOL bypassed;
    if (bypassed) return;
    bypassed = YES;

    NSLog(@"[DyldLVBypass] init");
    
    // Modifying exec page during execution may cause SIGBUS, so ignore it now
    // Only comment this out if only one thread (main) is running
    //signal(SIGBUS, SIG_IGN);
    
    char *dyldBase = getDyldBase();
    searchAndPatch("dyld_mmap", dyldBase, mmapSig, sizeof(mmapSig), hooked_dyld_mmap, NULL);
    searchAndPatch("dyld_fcntl", dyldBase, fcntlSig, sizeof(fcntlSig), hooked_dyld_fcntl, NULL);
}
