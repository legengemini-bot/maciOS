//
//  Execute.swift
//  maciOS
//
//  Created by Stossy11 on 23/08/2025.
//

import Foundation
import UIKit

struct LCMain {
    let entryOffset: UInt64
    let stackSize: UInt64
}

class Execute: NSObject {

    static func run(dylibPath: String) {
        NSLog("Attempting to run dylib at path: %@", dylibPath)
        
        guard FileManager.default.fileExists(atPath: dylibPath) else {
            NSLog("File does not exist at path: %@", dylibPath)
            return
        }
        
        guard let handle = dlopen(dylibPath, RTLD_NOW | RTLD_GLOBAL) else {
            if let error = dlerror() {
                let message = String(cString: error)
                NSLog("Failed to load dylib: %@", message)
            }
            return
        }
        NSLog("Dylib loaded successfully.")
        
        let entrySymbols = ["_main", "start", "_start", "main"]
        var entryPoint: UnsafeMutableRawPointer? = nil
        var lcmain: LCMain? = nil
        
        for symbol in entrySymbols {
            dlerror()
            if let sym = dlsym(handle, symbol), dlerror() == nil {
                entryPoint = sym
                NSLog("Found entry symbol: %@", symbol)
                break
            }
        }
        
        if entryPoint == nil {
            lcmain = getARM64EntryPoint(from: dylibPath)
            
            guard lcmain != nil else {
                NSLog("No entry symbol found.")
                return
            }
        }
        
        // Set environment variables FIRST
        let execute = Execute()
        execute.setEnvironmentVariables()
        
        NSLog("Environment variables set.")
        
        let progName = (dylibPath as NSString).lastPathComponent
        var argv: [UnsafeMutablePointer<CChar>?] = [strdup(progName)]
        
        // Add arguments if this is zsh
        if progName.contains("zsh") || progName == "zsh" {
            // Interactive login shell
            // argv.append(strdup("-i"))
        }
        
        argv.append(nil)
        
        
        
        let thread = Thread {
            NSLog("Executing dylib entry point...")
            let argc = Int32(argv.count - 1)
            if let _ = lcmain {
                _ = executeEntryPoint(for: dylibPath, argc, argv)
            } else {
                typealias EntryFunc = @convention(c) (Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> Int32
                let entry = unsafeBitCast(entryPoint, to: EntryFunc.self)
                
                print(Thread.current.name ?? "")
                _ = entry(argc, &argv)
                

            }
            
            NSLog("Dylib execution finished.")
        }
        
        thread.name = "executable-thread-\(UUID().uuidString)"
        thread.qualityOfService = .userInteractive
        if let lcmain {
            thread.stackSize = max(1024 * 1024, Int(lcmain.stackSize))
        }
        
        thread.start()
    }
    
    // NEW: Get TEXT segment base virtual address

    
    func setEnvironmentVariables() {
        let userName = NSUserName()
        let documentsDir = URL.documentsDirectory.path
        let shell = "/bin/zsh"
        let hostname = UIDevice.current.hostname ?? "localhost"
        let tmpDir = NSTemporaryDirectory()
        let pathEnv = "/bin:/usr/bin:/usr/local/bin:\(documentsDir)/bin"
        let launchInstanceID = UUID().uuidString
        let osLogRateLimit = "64"
        let securitySessionID = "18831"
        let termProgram = "maciOS"
        let termProgramVersion = "461"
        let termSessionID = UUID().uuidString
        let xpcFlags = "0x0"
        let xpcServiceName = "0"
        let cfBundleIdentifier = Bundle.main.bundleIdentifier ?? "com.stossy11.maciOS"

        var env: [String: String] = [
            "USER": userName,
            "LOGNAME": userName,
            "HOME": documentsDir,
            "PWD": documentsDir,
            "SHELL": shell,
            "HOSTNAME": hostname,
            "TMPDIR": tmpDir,
            "PATH": pathEnv,
            "LANG": "en_US.UTF-8",
            "LC_CTYPE": "UTF-8",
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "LaunchInstanceID": launchInstanceID,
            "OSLogRateLimit": osLogRateLimit,
            "SECURITYSESSIONID": securitySessionID,
            "TERM_PROGRAM": termProgram,
            "TERM_PROGRAM_VERSION": termProgramVersion,
            "TERM_SESSION_ID": termSessionID,
            "XPC_FLAGS": xpcFlags,
            "XPC_SERVICE_NAME": xpcServiceName,
            "__CFBundleIdentifier": cfBundleIdentifier,
            // Set PS1 properly for zsh
            "PS1": "%n@%m:%~$ ",
            // Also set PROMPT for zsh compatibility
            "PROMPT": "%n@%m:%~$ "
        ]

        for (key, value) in env {
            setenv(key, value, 1) // overwrite existing
        }
        
        NSLog("Environment variables set including PS1 and PROMPT")
    }
    
    static func getTextSegmentVMAddr(from path: String) -> UInt64? {
        guard let file = fopen(path, "rb") else { return nil }
        defer { fclose(file) }
        
        // Handle universal binaries
        var magic: UInt32 = 0
        fread(&magic, MemoryLayout<UInt32>.size, 1, file)
        fseek(file, 0, SEEK_SET)
        
        var sliceOffset: UInt32 = 0
        
        if magic == 0xcafebabe || magic == 0xbebafeca {
            let needsSwap = magic == 0xbebafeca
            
            struct fat_header {
                var magic: UInt32
                var nfat_arch: UInt32
            }
            struct fat_arch {
                var cputype: Int32
                var cpusubtype: Int32
                var offset: UInt32
                var size: UInt32
                var align: UInt32
            }
            
            var fatHeader = fat_header(magic: 0, nfat_arch: 0)
            fread(&fatHeader, MemoryLayout<fat_header>.size, 1, file)
            
            if needsSwap {
                fatHeader.nfat_arch = fatHeader.nfat_arch.byteSwapped
            }
            
            for i in 0..<fatHeader.nfat_arch {
                var arch = fat_arch(cputype: 0, cpusubtype: 0, offset: 0, size: 0, align: 0)
                fread(&arch, MemoryLayout<fat_arch>.size, 1, file)
                
                if needsSwap {
                    arch.cputype = arch.cputype.byteSwapped
                    arch.offset = arch.offset.byteSwapped
                }
                
                if arch.cputype == 0x0100000C { // CPU_ARM64
                    sliceOffset = arch.offset
                    break
                }
            }
        }
        
        fseek(file, Int(sliceOffset), SEEK_SET)
        
        // Read Mach-O header
        struct mach_header_64 {
            var magic: UInt32
            var cputype: Int32
            var cpusubtype: Int32
            var filetype: UInt32
            var ncmds: UInt32
            var sizeofcmds: UInt32
            var flags: UInt32
            var reserved: UInt32
        }
        
        var header = mach_header_64(magic: 0, cputype: 0, cpusubtype: 0, filetype: 0, ncmds: 0, sizeofcmds: 0, flags: 0, reserved: 0)
        fread(&header, MemoryLayout<mach_header_64>.size, 1, file)
        
        guard header.magic == 0xfeedfacf else { return nil }
        
        // Iterate load commands to find TEXT segment
        var currentOffset = Int(sliceOffset) + MemoryLayout<mach_header_64>.size
        
        for _ in 0..<header.ncmds {
            fseek(file, currentOffset, SEEK_SET)
            
            struct load_command {
                var cmd: UInt32
                var cmdsize: UInt32
            }
            
            var cmd = load_command(cmd: 0, cmdsize: 0)
            fread(&cmd, MemoryLayout<load_command>.size, 1, file)
            
            if cmd.cmd == 0x19 { // LC_SEGMENT_64
                fseek(file, currentOffset, SEEK_SET)
                
                struct segment_command_64 {
                    var cmd: UInt32
                    var cmdsize: UInt32
                    var segname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)
                    var vmaddr: UInt64
                    var vmsize: UInt64
                    var fileoff: UInt64
                    var filesize: UInt64
                    var maxprot: Int32
                    var initprot: Int32
                    var nsects: UInt32
                    var flags: UInt32
                }
                
                var segment = segment_command_64(cmd: 0, cmdsize: 0, segname: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), vmaddr: 0, vmsize: 0, fileoff: 0, filesize: 0, maxprot: 0, initprot: 0, nsects: 0, flags: 0)
                fread(&segment, MemoryLayout<segment_command_64>.size, 1, file)
                
                // Check if this is the __TEXT segment
                let segmentName = withUnsafePointer(to: &segment.segname) {
                    $0.withMemoryRebound(to: CChar.self, capacity: 16) {
                        String(cString: $0)
                    }
                }
                
                if segmentName == "__TEXT" {
                    return segment.vmaddr
                }
            }
            
            currentOffset += Int(cmd.cmdsize)
        }
        
        return nil
    }

    static func executeEntryPoint(for dylibPath: String, _ argc: Int32, _ argv: [UnsafeMutablePointer<CChar>?]) -> Int32 {
        guard let lcMain = getARM64EntryPoint(from: dylibPath) else {
            print("LC_MAIN not found.")
            return -1
        }
        
        guard let textVMAddr = getTextSegmentVMAddr(from: dylibPath) else {
            print("Failed to get TEXT segment vmaddr.")
            return -1
        }
        
        guard let base = getMemoryBase(for: dylibPath) else {
            print("Failed to retrieve in-memory base address.")
            return -1
        }
        
        // Calculate slide: difference between loaded address and expected vmaddr
        let baseAddr = UInt64(bitPattern: Int64(bitPattern: UInt64(UInt(bitPattern: base))))
        let slide = Int64(bitPattern: baseAddr) - Int64(bitPattern: textVMAddr)
        
        // Calculate actual entry point: TEXT vmaddr + entry offset + slide
        let actualEntryAddr = Int64(bitPattern: textVMAddr) + Int64(lcMain.entryOffset) + slide
        let entryPtr = UnsafeMutableRawPointer(bitPattern: Int(actualEntryAddr))
        
        guard let safeEntryPtr = entryPtr else {
            print("Invalid entry point address calculated.")
            return -1
        }
        
        print("TEXT vmaddr: 0x\(String(textVMAddr, radix: 16))")
        print("Entry offset: 0x\(String(lcMain.entryOffset, radix: 16))")
        print("Base address: 0x\(String(baseAddr, radix: 16))")
        print("Slide: 0x\(String(UInt64(bitPattern: slide), radix: 16))")
        print("Final entry point: 0x\(String(UInt64(bitPattern: actualEntryAddr), radix: 16))")
        
        typealias EntryFunc = @convention(c) (Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32
        let entryFunc = unsafeBitCast(safeEntryPtr, to: EntryFunc.self)
        var argv = argv
        
        return argv.withUnsafeMutableBufferPointer { buffer in
            entryFunc(argc, buffer.baseAddress)
        }
    }

    // Keep your existing functions unchanged
    static func getSliceOffset(for path: String, desiredCpu: cpu_type_t) -> UInt32? {
        guard let file = fopen(path, "rb") else { return nil }
        defer { fclose(file) }
        
        var magic: UInt32 = 0
        fread(&magic, MemoryLayout<UInt32>.size, 1, file)
        fseek(file, 0, SEEK_SET)
        
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            var fatHeader = fat_header()
            fread(&fatHeader, MemoryLayout<fat_header>.size, 1, file)
            
            for _ in 0..<fatHeader.nfat_arch {
                var arch = fat_arch()
                fread(&arch, MemoryLayout<fat_arch>.size, 1, file)
                
                if arch.cputype == desiredCpu {
                    return arch.offset
                }
            }
            return nil
        } else {
            // Not a universal binary
            return 0
        }
    }

    static func getARM64EntryPoint(from path: String) -> LCMain? {
        let CPU_ARM64: Int32 = 0x0100000C
        let LC_MAIN: UInt32 = 0x80000028
        let LC_UNIXTHREAD: UInt32 = 0x5
        
        print("Opening file: \(path)")
        guard let file = fopen(path, "rb") else {
            print("Failed to open file")
            return nil
        }
        defer { fclose(file) }
        
        // Read first 4 bytes to detect universal binary
        var magic: UInt32 = 0
        fread(&magic, MemoryLayout<UInt32>.size, 1, file)
        fseek(file, 0, SEEK_SET)
        
        var sliceOffset: UInt32 = 0
        
        if magic == 0xcafebabe || magic == 0xbebafeca { // FAT_MAGIC / FAT_CIGAM
            print("Universal binary detected")
            let needsSwap = magic == 0xbebafeca
            
            struct fat_header {
                var magic: UInt32
                var nfat_arch: UInt32
            }
            struct fat_arch {
                var cputype: Int32
                var cpusubtype: Int32
                var offset: UInt32
                var size: UInt32
                var align: UInt32
            }
            
            var fatHeader = fat_header(magic: 0, nfat_arch: 0)
            fread(&fatHeader, MemoryLayout<fat_header>.size, 1, file)
            
            if needsSwap {
                fatHeader.nfat_arch = fatHeader.nfat_arch.byteSwapped
            }
            
            print("Number of architectures: \(fatHeader.nfat_arch)")
            
            var found = false
            for i in 0..<fatHeader.nfat_arch {
                var arch = fat_arch(cputype: 0, cpusubtype: 0, offset: 0, size: 0, align: 0)
                fread(&arch, MemoryLayout<fat_arch>.size, 1, file)
                
                if needsSwap {
                    arch.cputype = arch.cputype.byteSwapped
                    arch.offset = arch.offset.byteSwapped
                }
                
                print("Arch \(i): cputype=0x\(String(arch.cputype, radix: 16)), offset=\(arch.offset)")
                if arch.cputype == CPU_ARM64 {
                    sliceOffset = arch.offset
                    found = true
                    print("Selected ARM64 slice at offset \(sliceOffset)")
                    break
                }
            }
            if !found {
                print("ARM64 slice not found in universal binary")
                return nil
            }
        } else {
            print("Single-arch binary detected")
        }
        
        // Seek to the Mach-O slice
        fseek(file, Int(sliceOffset), SEEK_SET)
        
        // Read Mach-O header
        struct mach_header_64 {
            var magic: UInt32
            var cputype: Int32
            var cpusubtype: Int32
            var filetype: UInt32
            var ncmds: UInt32
            var sizeofcmds: UInt32
            var flags: UInt32
            var reserved: UInt32
        }
        
        var header = mach_header_64(magic: 0, cputype: 0, cpusubtype: 0, filetype: 0, ncmds: 0, sizeofcmds: 0, flags: 0, reserved: 0)
        fread(&header, MemoryLayout<mach_header_64>.size, 1, file)
        
        guard header.magic == 0xfeedfacf else {
            print("Not a valid 64-bit Mach-O binary (magic: 0x\(String(header.magic, radix: 16)))")
            return nil
        }
        
        print("Mach-O header read: ncmds=\(header.ncmds), cputype=0x\(String(header.cputype, radix: 16))")
        
        // Verify this is actually ARM64
        if header.cputype != CPU_ARM64 {
            print("Binary is not ARM64 (cputype: 0x\(String(header.cputype, radix: 16)))")
            return nil
        }
        
        // Iterate load commands
        var currentOffset = Int(sliceOffset) + MemoryLayout<mach_header_64>.size
        
        for i in 0..<header.ncmds {
            fseek(file, currentOffset, SEEK_SET)
            
            struct load_command {
                var cmd: UInt32
                var cmdsize: UInt32
            }
            
            var cmd = load_command(cmd: 0, cmdsize: 0)
            fread(&cmd, MemoryLayout<load_command>.size, 1, file)
            
            print("Load command \(i): cmd=0x\(String(cmd.cmd, radix: 16)), cmdsize=\(cmd.cmdsize)")
            
            if cmd.cmd == LC_MAIN {
                print("Found LC_MAIN")
                fseek(file, currentOffset, SEEK_SET)
                
                struct entry_point_command {
                    var cmd: UInt32
                    var cmdsize: UInt32
                    var entryoff: UInt64
                    var stacksize: UInt64
                }
                
                var ep = entry_point_command(cmd: 0, cmdsize: 0, entryoff: 0, stacksize: 0)
                fread(&ep, MemoryLayout<entry_point_command>.size, 1, file)
                
                print("LC_MAIN: entryOffset=0x\(String(ep.entryoff, radix: 16)), stackSize=0x\(String(ep.stacksize, radix: 16))")
                return LCMain(entryOffset: ep.entryoff, stackSize: ep.stacksize)
            }
            else if cmd.cmd == LC_UNIXTHREAD {
                print("Found LC_UNIXTHREAD")
                fseek(file, currentOffset + MemoryLayout<load_command>.size, SEEK_SET)
                
                var flavor: UInt32 = 0
                var count: UInt32 = 0
                fread(&flavor, MemoryLayout<UInt32>.size, 1, file)
                fread(&count, MemoryLayout<UInt32>.size, 1, file)
                
                let ARM_THREAD_STATE64: UInt32 = 6
                print("Thread flavor: \(flavor), count: \(count)")
                
                if flavor == ARM_THREAD_STATE64 {
                    print("ARM_THREAD_STATE64 detected")
                    // Skip x0-x29 (30 registers), fp, lr, sp (3 more registers) = 33 * 8 bytes
                    fseek(file, 33 * 8, SEEK_CUR)
                    var pc: UInt64 = 0
                    fread(&pc, MemoryLayout<UInt64>.size, 1, file)
                    print("LC_UNIXTHREAD: entryOffset=0x\(String(pc, radix: 16))")
                    return LCMain(entryOffset: pc, stackSize: 0)
                }
            }
            
            currentOffset += Int(cmd.cmdsize)
        }
        
        print("No entry point found")
        return nil
    }

    static func getMemoryBase(for dylibPath: String) -> UnsafeMutableRawPointer? {
        let count = _dyld_image_count()
        let targetName = (dylibPath as NSString).lastPathComponent
        
        
        for i in 0..<count {
            guard let nameC = _dyld_get_image_name(i) else { continue }
            let imageName = String(cString: nameC)
            let imageBaseName = (imageName as NSString).lastPathComponent
            
            
            let matches = imageName == dylibPath ||
                         imageBaseName == targetName ||
                         imageName.hasSuffix(targetName) ||
                         dylibPath.hasSuffix(imageName)
            
            if matches {
                guard let headerPtr = _dyld_get_image_header(i) else { continue }
                
                let base = UnsafeMutableRawPointer(mutating: headerPtr)
                return base
            }
        }
        
        print("No matching image found")
        return nil
    }

}

@available(iOS 16.0, *)
func containsNSApplication(_ path: String) -> Bool {
    guard let file = fopen(path, "rb") else { return false }
    defer { fclose(file) }
    
    var header = mach_header_64()
    fread(&header, MemoryLayout<mach_header_64>.size, 1, file)
    
    // Very simplified; real-world parsing needs to iterate load commands
    if header.magic != MH_MAGIC_64 { return false }
    
    // Iterate load commands
    fseek(file, 0, SEEK_SET)
    let size = Int(header.sizeofcmds)
    var cmds = [UInt8](repeating: 0, count: size)
    fseek(file, MemoryLayout<mach_header_64>.size, SEEK_SET)
    fread(&cmds, size, 1, file)
    
    let data = Data(cmds)
    return data.withUnsafeBytes { ptr in
        return ptr.contains(NSData(bytes: "_OBJC_CLASS_$_NSApplication", length: 23) as Data)
    }
}

func containsNSApplication15(_ path: String) -> Bool {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return false
    }

    let symbol = "_OBJC_CLASS_$_NSApplication".utf8
    let symbolBytes = Array(symbol)

    let bytes = [UInt8](data)
    let symbolCount = symbolBytes.count
    let dataCount = bytes.count

    guard dataCount >= symbolCount else { return false }

    for i in 0...(dataCount - symbolCount) {
        var match = true
        for j in 0..<symbolCount {
            if bytes[i + j] != symbolBytes[j] {
                match = false
                break
            }
        }
        if match {
            return true
        }
    }

    return false
}


extension UIDevice {
    /// Returns the device's hostname using POSIX gethostname
    var hostname: String? {
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = gethostname(&buffer, Int(NI_MAXHOST))
        if result == 0 {
            return String(cString: buffer)
        } else {
            return nil
        }
    }
}

