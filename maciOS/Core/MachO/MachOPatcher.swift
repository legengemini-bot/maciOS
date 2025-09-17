//
//  MachOPatcher.swift
//  maciOS
//
//  Created by Stossy11 on 22/08/2025.
//

import Darwin
import Foundation
import MachO
import SwiftUI


class MachOPatcher: Equatable {
    static func == (lhs: MachOPatcher, rhs: MachOPatcher) -> Bool {
        lhs.fileURL == rhs.fileURL && rhs.patchedURL == lhs.patchedURL
    }
    
    var fileURL: URL
    var patchedURL: URL
    var knownFrameworks: [(String, String)] {
       return [
            ("/usr/lib/libpcre.0.dylib", "@rpath/libpcre.1.dylib"),
            ("/opt/homebrew/opt/pcre2/lib/libpcre2-32.0.dylib", "@rpath/libpcre.1.dylib"),
            ("/usr/lib/libSystem.B.dylib", "@rpath/LIBSYSTEM.dylib"),
            ("/System/Library/PrivateFrameworks/AuthKit.framework/Versions/A/AuthKit", "/System/Library/PrivateFrameworks/AuthKit.framework/AuthKit"),
            ("/System/Library/PrivateFrameworks/AOSKit.framework/Versions/A/AOSKit", "/System/Library/PrivateFrameworks/AOSKit.framework/AOSKit"),
            ("/opt/homebrew/opt/ncurses/lib/libncursesw.6.dylib", "@rpath/libncursesw.6.dylib"),
            ("/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation", "@rpath/Foundation.dylib"),
            ("/System/Library/Frameworks/CryptoKit.framework/Versions/A/CryptoKit", "/System/Library/Frameworks/CryptoKit.framework/CryptoKit"),
            ("/System/Library/Frameworks/OpenCL.framework/Versions/A/OpenCL", "@executable_path/Frameworks/OpenCL.framework/OpenCL"),
            ("/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation", "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"),
            ("/System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices", "@rpath/CoreServices.dylib"),
            ("/System/Library/Frameworks/Security.framework/Versions/A/Security", "/System/Library/Frameworks/Security.framework/Security"),
            ("/System/Library/Frameworks/AVFoundation.framework/Versions/A/AVFoundation", "/System/Library/Frameworks/AVFoundation.framework/AVFoundation"),
            ("/System/Library/Frameworks/Cocoa.framework/Versions/A/Cocoa", "@executable_path/Frameworks/Cocoa.framework/Cocoa"),
            ("/System/Library/Frameworks/CoreAudio.framework/Versions/A/CoreAudio", "/System/Library/Frameworks/CoreAudio.framework/CoreAudio"),
            ("/System/Library/Frameworks/CoreMedia.framework/Versions/A/CoreMedia", "/System/Library/Frameworks/CoreMedia.framework/CoreMedia"),
            ("/System/Library/Frameworks/CoreVideo.framework/Versions/A/CoreVideo", "@rpath/CoreVideo.dylib"),
            ("/System/Library/Frameworks/Kerberos.framework/Versions/A/Kerberos", "/System/Library/Frameworks/Kerberos.framework/Kerberos"),
            ("/System/Library/Frameworks/IOBluetooth.framework/Versions/A/IOBluetooth", "@executable_path/Frameworks/IOBluetooth.framework/IOBluetooth"),
            ("/System/Library/Frameworks/CoreBluetooth.framework/Versions/A/CoreBluetooth", "/System/Library/Frameworks/CoreBluetooth.framework/CoreBluetooth"),
            ("/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit", "@rpath/IOKit.dylib"),
            ("/System/Library/Frameworks/Metal.framework/Versions/A/Metal", "/System/Library/Frameworks/Metal.framework/Metal"),
            ("/System/Library/Frameworks/MetalKit.framework/Versions/A/MetalKit", "/System/Library/Frameworks/MetalKit.framework/MetalKit"),
            ("System/Library/Frameworks/LocalAuthentication.framework/Versions/A/LocalAuthentication", "/System/Library/Frameworks/LocalAuthentication.framework/LocalAuthentication"),
            ("/System/Library/Frameworks/CFNetwork.framework/Versions/A/CFNetwork", "/System/Library/Frameworks/CFNetwork.framework/CFNetwork"),
            ("/System/Library/Frameworks/SystemConfiguration.framework/Versions/A/SystemConfiguration", "/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration"),
            ("/System/Library/Frameworks/CoreWLAN.framework/Versions/A/CoreWLAN", "@executable_path/Frameworks/CoreWLAN.framework/CoreWLAN"),
            ("/System/Library/Frameworks/OpenGL.framework/Versions/A/OpenGL", "@rpath/CoreOpenGL.framework/CoreOpenGL"),
            ("/System/Library/PrivateFrameworks/DisplayServices.framework/Versions/A/DisplayServices", "@executable_path/Frameworks/DisplayServices.framework/DisplayServices"),
            ("/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit", "@executable_path/Frameworks/AppKit_iOS.framework/AppKit_iOS"),
            ("/System/Library/Frameworks/CoreGraphics.framework/Versions/A/CoreGraphics", "@rpath/CoreGraphics.dylib"),
            ("/System/Library/Frameworks/SwiftUI.framework/Versions/A/SwiftUI", "/System/Library/Frameworks/SwiftUI.framework/SwiftUI"),
            ("/System/Library/Frameworks/Combine.framework/Versions/A/Combine", "/System/Library/Frameworks/Combine.framework/Combine"),
            ("/System/Library/Frameworks/WebKit.framework/Versions/A/WebKit", "/System/Library/Frameworks/WebKit.framework/WebKit"),
        ]
    }
    
    init(_ path: URL) {
        self.fileURL = path
        self.patchedURL = URL.documentsDirectory.appendingPathComponent(fileURL.lastPathComponent + ".dylib")
    }
    
    func patchExecutable() -> URL? {
        guard copyOriginalFile() else { return nil }
        
        guard convertToDylib() != nil else { return nil }
        
        #if targetEnvironment(simulator)
        guard patchPlatform(targetPlatform: PLATFORM_IOSSIMULATOR) != nil else { return nil }
        #else
        guard patchPlatform(targetPlatform: PLATFORM_IOS) != nil else { return nil }
        #endif
        
        patchKnownFrameworks()
        
        return patchedURL
    }
    
    func patchKnownFrameworks(_ frameworks: [(String, String)] = []) {
        let newFrameworks = knownFrameworks + frameworks
        
        newFrameworks.forEach { replacePattern($0.0, with: $0.1) }
    }
    
    private func copyOriginalFile() -> Bool {
        do {
            if FileManager.default.fileExists(atPath: patchedURL.path) {
                try FileManager.default.removeItem(at: patchedURL)
            }
            let data = try Data(contentsOf: fileURL)
            try data.write(to: patchedURL)
            return true
        } catch {
            NSLog("Error copying file: \(error)")
            return false 
        }
    }
    
    
    func patchPlatform(targetPlatform: Int32) -> String? {
        if !FileManager.default.fileExists(atPath: patchedURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                try data.write(to: patchedURL)
            } catch {
                NSLog("Error copying file: \(error)")
                return nil
            }
        }
        
        guard let patchedPath = performPlatformPatch(filePath: patchedURL.path, targetPlatform: UInt32(targetPlatform)) else {
            return nil
        }
        
        return patchedPath
    }
    
    
    func convertToDylib(doInject: Bool = true) -> String? {
        if !FileManager.default.fileExists(atPath: patchedURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                try data.write(to: patchedURL)
            } catch {
                NSLog("Error copying file: \(error)")
                return nil
            }
        }
        
        let error = parseMachOFile(path: patchedURL.path) { [weak self] path, header, fd, filePtr in
            if header.pointee.cputype == CPU_TYPE_ARM64 {
                self?.patchExecSlice(path: path, header: header, doInject: doInject)
            }
        }
        
        if let error = error {
            NSLog("Error converting to dylib: \(error)")
            return nil
        }
        
        return patchedURL.path
    }
    
    
    @discardableResult
    func replacePattern(_ pattern: String, with replacement: String) -> Bool {
        return replacePatternInPatchedFile(pattern: pattern, replacement: replacement)
    }
    
    
    static func OSSwapInt32(_ value: UInt32) -> UInt32 {
        return value.byteSwapped
    }
    
    static func OSSwapInt32(_ value: Int32) -> Int32 {
        return value.byteSwapped
    }
    
    
    private func performPlatformPatch(filePath: String, targetPlatform: UInt32) -> String? {
        let fd = open(filePath, O_RDWR)
        guard fd >= 0 else {
            NSLog("Failed to open file: \(String(cString: strerror(errno)))")
            return nil
        }
        defer { close(fd) }
        
        var fileStat = stat()
        guard fstat(fd, &fileStat) == 0 else {
            NSLog("Failed to get file stats: \(String(cString: strerror(errno)))")
            return nil
        }
        
        let mapFlags: Int32
        #if os(iOS)
        mapFlags = MAP_SHARED
        #else
        mapFlags = MAP_PRIVATE
        #endif
        
        guard let fileData = mmap(nil, Int(fileStat.st_size), PROT_READ | PROT_WRITE, mapFlags, fd, 0) else {
            NSLog("Failed to mmap file: \(String(cString: strerror(errno)))")
            return nil
        }
        defer { munmap(fileData, Int(fileStat.st_size)) }
        
        let success = patchMachOFile(fileData: fileData, targetPlatform: targetPlatform)
        guard success else {
            return nil
        }
        
        msync(fileData, Int(fileStat.st_size), MS_SYNC)
        
        do {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: filePath)
            return filePath
        } catch {
            NSLog("Failed to set permissions: \(error)")
            return nil
        }
    }
    
    private func patchMachOFile(fileData: UnsafeRawPointer, targetPlatform: UInt32) -> Bool {
        let magic = fileData.load(as: UInt32.self)
        var foundAny = false
        
        switch magic {
        case FAT_MAGIC, FAT_CIGAM:
            foundAny = patchFatBinary(fileData: fileData, targetPlatform: targetPlatform)
            
        case MH_MAGIC_64:
            foundAny = patchSlice(fileData, targetPlatform: targetPlatform) ?? false
            
        default:
            NSLog("Unsupported Mach-O magic: \(String(format: "%08x", magic))")
            return false
        }
        
        if !foundAny {
            NSLog("No LC_BUILD_VERSION found in any slice")
        }
        
        return foundAny
    }
    
    private func patchFatBinary(fileData: UnsafeRawPointer, targetPlatform: UInt32) -> Bool {
        let fatHeader = fileData.load(as: fat_header.self)
        let archCount = Int(UInt32(bigEndian: fatHeader.nfat_arch))
        var foundAny = false
        
        for i in 0..<archCount {
            let archOffset = MemoryLayout<fat_header>.size + i * MemoryLayout<fat_arch>.size
            let archPtr = fileData.advanced(by: archOffset)
            let arch = archPtr.load(as: fat_arch.self)
            let sliceOffset = Int(UInt32(bigEndian: arch.offset))
            
            guard let patched = patchSlice(fileData.advanced(by: sliceOffset), targetPlatform: targetPlatform) else {
                NSLog("Failed to patch slice at offset \(sliceOffset)")
                continue
            }
            
            foundAny = foundAny || patched
        }
        
        return foundAny
    }
    
    private func patchSlice(_ slicePtr: UnsafeRawPointer, targetPlatform: UInt32) -> Bool? {
        let header = slicePtr.assumingMemoryBound(to: mach_header_64.self)
        guard header.pointee.magic == MH_MAGIC_64 else {
            return nil
        }
        
        var cmdPtr = slicePtr.advanced(by: MemoryLayout<mach_header_64>.size)
        var platformFound = false
        
        for _ in 0..<header.pointee.ncmds {
            let cmd = cmdPtr.assumingMemoryBound(to: load_command.self)
            
            if cmd.pointee.cmd == LC_BUILD_VERSION {
                let buildCmd = UnsafeMutablePointer<build_version_command>(OpaquePointer(cmd))
                NSLog("Patching platform from \(buildCmd.pointee.platform) to \(targetPlatform)")
                buildCmd.pointee.platform = targetPlatform
                platformFound = true
            }
            
            cmdPtr = cmdPtr.advanced(by: Int(cmd.pointee.cmdsize))
        }
        
        return platformFound
    }
    
    
    typealias ParseMachOCallback = (
        _ path: UnsafePointer<CChar>,
        _ header: UnsafeMutablePointer<mach_header_64>,
        _ fd: Int32,
        _ filePtr: UnsafeMutableRawPointer
    ) -> Void
    
    private func parseMachOFile(path: String, callback: ParseMachOCallback) -> String? {
        return path.withCString { cPath in
            parseMachO(path: cPath, callback: callback)
        }
    }
    
    private func parseMachO(path: UnsafePointer<CChar>, callback: ParseMachOCallback) -> String? {
        let fd = open(path, O_RDWR, 0o600)
        guard fd >= 0 else {
            return String(format: "Failed to open %s: %s", path, strerror(errno))
        }
        defer { close(fd) }
        
        var fileStat = stat()
        guard fstat(fd, &fileStat) == 0 else {
            return String(format: "Failed to stat %s: %s", path, strerror(errno))
        }
        
        guard let map = mmap(nil, Int(fileStat.st_size), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0),
              map != MAP_FAILED else {
            return String(format: "Failed to map %s: %s", path, strerror(errno))
        }
        defer {
            msync(map, Int(fileStat.st_size), MS_SYNC)
            munmap(map, Int(fileStat.st_size))
        }
        
        let magic = map.load(as: UInt32.self)
        
        switch magic {
        case FAT_CIGAM:
            return parseFatBinaryForCallback(map: map, path: path, callback: callback)
            
        case MH_MAGIC_64, MH_MAGIC:
            let machHeader = map.bindMemory(to: mach_header_64.self, capacity: 1)
            callback(path, machHeader, fd, map)
            return nil
            
        default:
            return "Not a Mach-O file"
        }
    }
    
    private func parseFatBinaryForCallback(map: UnsafeMutableRawPointer, path: UnsafePointer<CChar>, callback: ParseMachOCallback) -> String? {
        let fatHeader = map.bindMemory(to: fat_header.self, capacity: 1)
        var arch = (map + MemoryLayout<fat_header>.size).bindMemory(to: fat_arch.self, capacity: 1)
        
        let archCount = Self.OSSwapInt32(fatHeader.pointee.nfat_arch)
        
        for _ in 0..<archCount {
            if Self.OSSwapInt32(arch.pointee.cputype) == CPU_TYPE_ARM64 {
                let offset = Int(Self.OSSwapInt32(arch.pointee.offset))
                let machHeader = (map + offset).bindMemory(to: mach_header_64.self, capacity: 1)
                callback(path, machHeader, -1, map)
            }
            arch = arch.advanced(by: 1)
        }
        
        return nil
    }
    
    @discardableResult
    private func replacePatternInPatchedFile(pattern: String, replacement: String) -> Bool {
        guard FileManager.default.fileExists(atPath: patchedURL.path) else {
            print("File does not exist at path: \(patchedURL.path)")
            return false
        }
        
        do {
            // Read from patchedURL, not fileURL
            let fileData = try Data(contentsOf: patchedURL)
            
            guard let patternData = pattern.data(using: .utf8),
                  let replacementData = replacement.data(using: .utf8) else {
                print("Failed to convert strings to data.")
                return false
            }
            
            let modifiedData = replacePattern(in: fileData, pattern: patternData, replacement: replacementData)
            
            // Write back to patchedURL
            try modifiedData.write(to: patchedURL)
            // print("File successfully modified: \(pattern) -> \(replacement)")
            return true
        } catch {
            print("Error reading or writing the file: \(error)")
            return false
        }
    }
    
    private func replacePattern(in data: Data, pattern: Data, replacement: Data) -> Data {
        var modifiedData = data
        var currentIndex = 0
        
        while let range = modifiedData.range(of: pattern, options: [], in: currentIndex..<modifiedData.count) {
            let patternLength = range.upperBound - range.lowerBound
            let replacementLength = replacement.count
            
            if replacementLength < patternLength {
                let paddedReplacement = replacement + Data(repeating: 0, count: patternLength - replacementLength)
                modifiedData.replaceSubrange(range, with: paddedReplacement)
            } else {
                modifiedData.replaceSubrange(range, with: replacement)
            }
            
            currentIndex = range.upperBound
        }
        
        return modifiedData
    }
    
    
    private func patchExecSlice(path: UnsafePointer<CChar>, header: UnsafeMutablePointer<mach_header_64>, doInject: Bool) {
        let imageHeaderPtr = UnsafeMutableRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size)
        
        // Convert executable to dylib
        convertExecutableToDylib(header: header)
        
        // Patch __PAGEZERO segment
        patchPageZeroSegment(imageHeaderPtr: imageHeaderPtr)
        
        // Handle dylib commands
        handleDylibCommands(path: path, header: header, doInject: doInject)
    }
    
    private func convertExecutableToDylib(header: UnsafeMutablePointer<mach_header_64>) {
        if header.pointee.magic == MH_MAGIC_64 {
            header.pointee.filetype = UInt32(MH_DYLIB)
            header.pointee.flags |= UInt32(MH_NO_REEXPORTED_DYLIBS)
            header.pointee.flags &= ~UInt32(MH_PIE)
        }
    }
    
    private func patchPageZeroSegment(imageHeaderPtr: UnsafeMutableRawPointer) {
        let segment = imageHeaderPtr.bindMemory(to: segment_command_64.self, capacity: 1)
        
        guard segment.pointee.cmd == LC_SEGMENT_64 || segment.pointee.cmd == LC_ID_DYLIB else {
            assertionFailure("Unexpected command type")
            return
        }
        
        if segment.pointee.cmd == LC_SEGMENT_64 && segment.pointee.vmaddr == 0 {
            assert(segment.pointee.vmsize == 0x100000000, "Unexpected vmsize")
            segment.pointee.vmaddr = 0x100000000 - 0x4000
            segment.pointee.vmsize = 0x4000
        }
    }
    
    private func handleDylibCommands(path: UnsafePointer<CChar>, header: UnsafeMutablePointer<mach_header_64>, doInject: Bool) {
        let imageHeaderPtr = UnsafeMutableRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size)
        var hasDylibCommand = false
        var dylibLoaderCommand: UnsafeMutablePointer<dylib_command>?
        let libCppPath = "/usr/lib/libc++.1.dylib"
        
        var command = imageHeaderPtr.bindMemory(to: load_command.self, capacity: 1)
        
        for _ in 0..<header.pointee.ncmds {
            switch command.pointee.cmd {
            case UInt32(LC_ID_DYLIB):
                hasDylibCommand = true
                
            case 0x114514:
                dylibLoaderCommand = UnsafeMutablePointer<dylib_command>(OpaquePointer(command))
                
            default:
                break
            }
            
            command = UnsafeMutableRawPointer(command)
                .advanced(by: Int(command.pointee.cmdsize))
                .bindMemory(to: load_command.self, capacity: 1)
        }
        
        if let dylibLoaderCommand = dylibLoaderCommand {
            dylibLoaderCommand.pointee.cmd = doInject ? UInt32(LC_LOAD_DYLIB) : 0x114514
            
            let namePtr = UnsafeMutableRawPointer(dylibLoaderCommand)
                .advanced(by: Int(dylibLoaderCommand.pointee.dylib.name.offset))
            strcpy(namePtr.assumingMemoryBound(to: CChar.self), libCppPath)
        } else {
            insertDylibCommand(
                cmd: doInject ? UInt32(LC_LOAD_DYLIB) : 0x114514,
                path: libCppPath,
                header: header
            )
        }
        
        if !hasDylibCommand {
            insertDylibCommand(cmd: UInt32(LC_ID_DYLIB), path: path, header: header)
        }
    }
    
    private func insertDylibCommand(cmd: UInt32, path: UnsafePointer<CChar>, header: UnsafeMutablePointer<mach_header_64>) {
        let name = determineName(cmd: cmd, path: path)
        let nameLength = strlen(name) + 1
        let cmdSize = MemoryLayout<dylib_command>.size + Int(rnd32(UInt32(nameLength), 8))
        
        let headerPtr = UnsafeMutableRawPointer(header)
        let dylibPtr = getDylibCommandPointer(cmd: cmd, header: header, cmdSize: cmdSize, headerPtr: headerPtr)
        
        configureDylibCommand(dylibPtr: dylibPtr, cmd: cmd, cmdSize: cmdSize, name: name, nameLength: nameLength)
        
        header.pointee.ncmds += 1
        header.pointee.sizeofcmds += UInt32(cmdSize)
    }
    
    private func determineName(cmd: UInt32, path: UnsafePointer<CChar>) -> UnsafePointer<CChar> {
        if cmd == LC_ID_DYLIB {
            guard let base = basename(UnsafeMutablePointer(mutating: path)) else {
                return path
            }
            return UnsafePointer(base)
        } else {
            return path
        }
    }
    
    func patchUndefinedSymbols(_ symbolsToRemove: [String] = []) -> Bool {
        guard FileManager.default.fileExists(atPath: patchedURL.path) else {
            NSLog("Patched file does not exist")
            return false
        }
        
        let defaultSymbolsToRemove = [
            "CGDisplayCopyAllDisplayModes",
            "_CGDisplayCopyAllDisplayModes",
            "_CGDisplayModeCopyPixelEncoding",
            "_CGDisplayModeGetPixelWidth",
            "_CGDisplayModeGetPixelHeight",
            "_CGDisplayModeGetRefreshRate",
            "_CGDisplayModeRelease",
            "_CGMainDisplayID",
            "_CGDisplayBounds",
            "_CGDisplayPixelsWide",
            "_CGDisplayPixelsHigh"
        ]
        
        let allSymbolsToRemove = defaultSymbolsToRemove + symbolsToRemove
        
        let error = parseMachOFile(path: patchedURL.path) { [weak self] path, header, fd, filePtr in
            if header.pointee.cputype == CPU_TYPE_ARM64 {
                self?.patchSymbolsInSlice(path: path, header: header, filePtr: filePtr, symbolsToRemove: allSymbolsToRemove)
            }
        }
        
        if let error = error {
            NSLog("Error patching symbols: \(error)")
            return false
        }
        
        return true
    }

    private func patchSymbolsInSlice(path: UnsafePointer<CChar>, header: UnsafeMutablePointer<mach_header_64>, filePtr: UnsafeMutableRawPointer, symbolsToRemove: [String]) {
        var dysymtabCmd: UnsafeMutablePointer<dysymtab_command>?
        var symtabCmd: UnsafeMutablePointer<symtab_command>?
        var linkeditSegment: UnsafeMutablePointer<segment_command_64>?
        
        // Find relevant load commands
        var command = UnsafeMutableRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size).bindMemory(to: load_command.self, capacity: 1)
        
        for _ in 0..<header.pointee.ncmds {
            switch command.pointee.cmd {
            case UInt32(LC_DYSYMTAB):
                dysymtabCmd = UnsafeMutablePointer<dysymtab_command>(OpaquePointer(command))
                
            case UInt32(LC_SYMTAB):
                symtabCmd = UnsafeMutablePointer<symtab_command>(OpaquePointer(command))
                
            case UInt32(LC_SEGMENT_64):
                let segment = UnsafeMutablePointer<segment_command_64>(OpaquePointer(command))
                let segName = withUnsafePointer(to: segment.pointee.segname) {
                    String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
                }
                if segName == "__LINKEDIT" {
                    linkeditSegment = segment
                }
                
            default:
                break
            }
            
            command = UnsafeMutableRawPointer(command).advanced(by: Int(command.pointee.cmdsize)).bindMemory(to: load_command.self, capacity: 1)
        }
        
        guard let dysymtab = dysymtabCmd,
              let symtab = symtabCmd,
              let linkedit = linkeditSegment else {
            NSLog("Could not find required symbol table commands")
            return
        }
        
        // Calculate base addresses
        let linkeditBase = filePtr.advanced(by: Int(linkedit.pointee.fileoff))
        let stringTable = linkeditBase.advanced(
            by: Int(UInt64(symtab.pointee.stroff) - linkedit.pointee.fileoff)
        )
        let symbolTable = linkeditBase.advanced(
            by: Int(UInt64(symtab.pointee.symoff) - linkedit.pointee.fileoff)
        ).bindMemory(to: nlist_64.self, capacity: Int(symtab.pointee.nsyms))

        // Process undefined symbols
        patchUndefinedSymbolsInTable(
            symbolTable: symbolTable,
            stringTable: stringTable,
            dysymtab: dysymtab,
            symbolsToRemove: symbolsToRemove
        )
    }

    private func patchUndefinedSymbolsInTable(
        symbolTable: UnsafeMutablePointer<nlist_64>,
        stringTable: UnsafeMutableRawPointer,
        dysymtab: UnsafeMutablePointer<dysymtab_command>,
        symbolsToRemove: [String]
    ) {
        let undefinedStart = Int(dysymtab.pointee.iundefsym)
        let undefinedCount = Int(dysymtab.pointee.nundefsym)
        
        var removedCount: UInt32 = 0
        
        for i in 0..<undefinedCount {
            let symbolIndex = undefinedStart + i
            let symbol = symbolTable.advanced(by: symbolIndex)
            
            // Get symbol name
            let nameOffset = Int(symbol.pointee.n_un.n_strx)
            let symbolName = String(cString: stringTable.advanced(by: nameOffset).assumingMemoryBound(to: CChar.self))
            
            // Check if this symbol should be removed
            if symbolsToRemove.contains(symbolName) {
                NSLog("Removing undefined symbol: \(symbolName)")
                
                // Mark symbol as removed by setting n_type to 0
                symbol.pointee.n_type = 0
                symbol.pointee.n_sect = 0
                symbol.pointee.n_desc = 0
                symbol.pointee.n_value = 0
                symbol.pointee.n_un.n_strx = 0
                
                removedCount += 1
            }
        }
        
        // Update the dysymtab command to reflect removed symbols
        if removedCount > 0 {
            dysymtab.pointee.nundefsym -= removedCount
            NSLog("Removed \(removedCount) undefined symbols")
        }
    }

    /// Patches out weak symbols that might cause loading issues
    func patchWeakSymbols(_ symbolsToWeaken: [String] = []) -> Bool {
        guard FileManager.default.fileExists(atPath: patchedURL.path) else {
            NSLog("Patched file does not exist")
            return false
        }
        
        let error = parseMachOFile(path: patchedURL.path) { [weak self] path, header, fd, filePtr in
            if header.pointee.cputype == CPU_TYPE_ARM64 {
                self?.weakenSymbolsInSlice(header: header, filePtr: filePtr, symbolsToWeaken: symbolsToWeaken)
            }
        }
        
        if let error = error {
            NSLog("Error weakening symbols: \(error)")
            return false
        }
        
        return true
    }

    private func weakenSymbolsInSlice(header: UnsafeMutablePointer<mach_header_64>, filePtr: UnsafeMutableRawPointer, symbolsToWeaken: [String]) {
        var symtabCmd: UnsafeMutablePointer<symtab_command>?
        var linkeditSegment: UnsafeMutablePointer<segment_command_64>?
        
        // Find symbol table and linkedit segment
        var command = UnsafeMutableRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size).bindMemory(to: load_command.self, capacity: 1)
        
        for _ in 0..<header.pointee.ncmds {
            switch command.pointee.cmd {
            case UInt32(LC_SYMTAB):
                symtabCmd = UnsafeMutablePointer<symtab_command>(OpaquePointer(command))
                
            case UInt32(LC_SEGMENT_64):
                let segment = UnsafeMutablePointer<segment_command_64>(OpaquePointer(command))
                let segName = withUnsafePointer(to: segment.pointee.segname) {
                    String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
                }
                if segName == "__LINKEDIT" {
                    linkeditSegment = segment
                }
                
            default:
                break
            }
            
            command = UnsafeMutableRawPointer(command).advanced(by: Int(command.pointee.cmdsize)).bindMemory(to: load_command.self, capacity: 1)
        }
        
        guard let symtab = symtabCmd,
              let linkedit = linkeditSegment else {
            NSLog("Could not find symbol table")
            return
        }
        
        let linkeditBase = filePtr.advanced(by: Int(linkedit.pointee.fileoff))
        let stringTable = linkeditBase.advanced(
            by: Int(UInt64(symtab.pointee.stroff) - linkedit.pointee.fileoff)
        )

        let symbolTable = linkeditBase.advanced(
            by: Int(UInt64(symtab.pointee.symoff) - linkedit.pointee.fileoff)
        ).bindMemory(to: nlist_64.self, capacity: Int(symtab.pointee.nsyms))

        // Process all symbols
        for i in 0..<Int(symtab.pointee.nsyms) {
            let symbol = symbolTable.advanced(by: i)
            let nameOffset = Int(symbol.pointee.n_un.n_strx)
            
            guard nameOffset > 0 else { continue }
            
            let symbolName = String(cString: stringTable.advanced(by: nameOffset).assumingMemoryBound(to: CChar.self))
            
            if symbolsToWeaken.contains(symbolName) {
                // Mark symbol as weak
                symbol.pointee.n_desc |= UInt16(N_WEAK_DEF)
                NSLog("Weakened symbol: \(symbolName)")
            }
        }
    }

    
    private func getDylibCommandPointer(
        cmd: UInt32,
        header: UnsafeMutablePointer<mach_header_64>,
        cmdSize: Int,
        headerPtr: UnsafeMutableRawPointer
    ) -> UnsafeMutablePointer<dylib_command> {
        
        if cmd == LC_ID_DYLIB {
            let dylibPtr = headerPtr
                .advanced(by: MemoryLayout<mach_header_64>.size)
                .assumingMemoryBound(to: dylib_command.self)
            
            // Move existing load commands forward to make space
            let loadCmdsSize = Int(header.pointee.sizeofcmds)
            let src = UnsafeRawPointer(dylibPtr)
            let dst = headerPtr.advanced(by: MemoryLayout<mach_header_64>.size + cmdSize)
            memmove(dst, src, loadCmdsSize)
            memset(dylibPtr, 0, cmdSize)
            
            return dylibPtr
        } else {
            return headerPtr
                .advanced(by: MemoryLayout<mach_header_64>.size + Int(header.pointee.sizeofcmds))
                .assumingMemoryBound(to: dylib_command.self)
        }
    }
    
    private func configureDylibCommand(
        dylibPtr: UnsafeMutablePointer<dylib_command>,
        cmd: UInt32,
        cmdSize: Int,
        name: UnsafePointer<CChar>,
        nameLength: Int
    ) {
        dylibPtr.pointee.cmd = cmd
        dylibPtr.pointee.cmdsize = UInt32(cmdSize)
        dylibPtr.pointee.dylib.name.offset = UInt32(MemoryLayout<dylib_command>.size)
        dylibPtr.pointee.dylib.compatibility_version = 0x10000
        dylibPtr.pointee.dylib.current_version = 0x10000
        dylibPtr.pointee.dylib.timestamp = 2
        
        let nameDst = UnsafeMutableRawPointer(dylibPtr)
            .advanced(by: Int(dylibPtr.pointee.dylib.name.offset))
        strncpy(nameDst.assumingMemoryBound(to: CChar.self), name, nameLength)
    }
    
    
    private func rnd32(_ value: UInt32, _ roundTo: UInt32) -> UInt32 {
        let mask = roundTo - 1
        return (value + mask) & ~mask
    }
}
