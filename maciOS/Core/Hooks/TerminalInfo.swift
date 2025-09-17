//
//  TerminalInfo.swift
//  maciOS
//
//  Created by Stossy11 on 24/08/2025.
//

import Foundation

var original_exit: UnsafeMutableRawPointer?
var original_abort: UnsafeMutableRawPointer?

struct winsize {
    var ws_row: UInt16
    var ws_col: UInt16
    var ws_xpixel: UInt16
    var ws_ypixel: UInt16
}

var terminalSize = winsize(ws_row: 72, ws_col: 82, ws_xpixel: 0, ws_ypixel: 0)
var original_isatty: UnsafeMutableRawPointer?
var original_tcgetattr: UnsafeMutableRawPointer?
var original_tcsetattr: UnsafeMutableRawPointer?
var original_ioctl: UnsafeMutableRawPointer?
var original_tcgetpgrp: UnsafeMutableRawPointer?

@_cdecl("my_isatty")
func my_isatty(_ fd: Int32) -> Int32 {
    if fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO {
        return 1
    }
    
    if let original = original_isatty {
        let originalFunc = unsafeBitCast(original, to: (@convention(c) (Int32) -> Int32).self)
        return originalFunc(fd)
    }
    
    return 0
}

@_cdecl("my_tcgetattr")
func my_tcgetattr(_ fd: Int32, _ termios_p: UnsafeMutablePointer<termios>) -> Int32 {
    if fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO {
        termios_p.pointee.c_iflag = UInt(ICRNL | IXON)
        termios_p.pointee.c_oflag = UInt(OPOST | ONLCR)
        termios_p.pointee.c_cflag = UInt(CREAD | CS8)
        termios_p.pointee.c_lflag = UInt(ICANON | ECHO | ECHOE | ECHOK | ISIG)
        
        var cc = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                 UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                 UInt8(0), UInt8(0), UInt8(0), UInt8(0))
        
        cc.4 = 4
        cc.3 = 28
        cc.8 = 127
        cc.2 = 3
        cc.9 = 21
        cc.18 = 1
        cc.15 = 26
        cc.19 = 0
        
        termios_p.pointee.c_cc = cc
        
        return 0
    }
    
    if let original = original_tcgetattr {
        let originalFunc = unsafeBitCast(original, to: (@convention(c) (Int32, UnsafeMutablePointer<termios>) -> Int32).self)
        return originalFunc(fd, termios_p)
    }
    
    return -1
}

@_cdecl("my_tcsetattr")
func my_tcsetattr(_ fd: Int32, _ optional_actions: Int32, _ termios_p: UnsafePointer<termios>) -> Int32 {
    if fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO {
        return 0
    }
    
    if let original = original_tcsetattr {
        let originalFunc = unsafeBitCast(original, to: (@convention(c) (Int32, Int32, UnsafePointer<termios>) -> Int32).self)
        return originalFunc(fd, optional_actions, termios_p)
    }
    
    return -1
}

@_cdecl("my_tcgetpgrp")
func my_tcgetpgrp(_ fd: Int32) -> pid_t {
    if fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO {
        return getpgrp()
    }
    
    if let original = original_tcgetpgrp {
        let originalFunc = unsafeBitCast(original, to: (@convention(c) (Int32) -> pid_t).self)
        return originalFunc(fd)
    }
    
    return -1
}

@_cdecl("my_ioctl")
func my_ioctl(_ fd: Int32, _ request: UInt, _ argp: UnsafeMutableRawPointer?) -> Int32 {
    let TIOCGWINSZ: UInt = 0x40087468
    let TIOCSWINSZ: UInt = 0x80087467
    
    if fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO {
        switch request {
        case TIOCGWINSZ:
            guard let argp = argp else {
                return -1
            }
            
            let address = UInt(bitPattern: argp)
            if address < 0x1000 {
                return -1
            }
            
            return 0
            
        case TIOCSWINSZ:
            guard let argp = argp else {
                return -1
            }
            
            let address = UInt(bitPattern: argp)
            if address == 0 || address % UInt(MemoryLayout<winsize>.alignment) != 0 {
                return -1
            }
            
            let winsizePtr = argp.assumingMemoryBound(to: winsize.self)
            memcpy(&terminalSize, winsizePtr, MemoryLayout<winsize>.size)
            return 0
            
        default:
            return 0
        }
    }
    
    if let original = original_ioctl {
        let originalFunc = unsafeBitCast(original, to: (@convention(c) (Int32, UInt, UnsafeMutableRawPointer?) -> Int32).self)
        return originalFunc(fd, request, argp)
    }
    
    return -1
}

func install_pty_hooks() {
    let isattyReplacement = unsafeBitCast(my_isatty as @convention(c) (Int32) -> Int32, to: UnsafeMutableRawPointer.self)
    let tcgetattrReplacement = unsafeBitCast(my_tcgetattr as @convention(c) (Int32, UnsafeMutablePointer<termios>) -> Int32, to: UnsafeMutableRawPointer.self)
    let tcsetattrReplacement = unsafeBitCast(my_tcsetattr as @convention(c) (Int32, Int32, UnsafePointer<termios>) -> Int32, to: UnsafeMutableRawPointer.self)
    let tcgetpgrpReplacement = unsafeBitCast(my_tcgetpgrp as @convention(c) (Int32) -> pid_t, to: UnsafeMutableRawPointer.self)
    let ioctlReplacement = unsafeBitCast(my_ioctl as @convention(c) (Int32, UInt, UnsafeMutableRawPointer?) -> Int32, to: UnsafeMutableRawPointer.self)

    var rebindings = [
        rebinding(name: strdup("isatty"), replacement: isattyReplacement, replaced: &original_isatty),
        rebinding(name: strdup("tcgetattr"), replacement: tcgetattrReplacement, replaced: &original_tcgetattr),
        rebinding(name: strdup("tcsetattr"), replacement: tcsetattrReplacement, replaced: &original_tcsetattr),
        rebinding(name: strdup("tcgetpgrp"), replacement: tcgetpgrpReplacement, replaced: &original_tcgetpgrp),
        rebinding(name: strdup("ioctl"), replacement: ioctlReplacement, replaced: &original_ioctl)
    ]

    let result = rebind_symbols(&rebindings, Int(rebindings.count))
    
    if result == 0 {
        NSLog("Successfully installed PTY hooks")
    } else {
        NSLog("Failed to install PTY hooks: %d", result)
    }
}

func updateTerminalSize(rows: UInt16, cols: UInt16) {
    terminalSize.ws_row = rows
    terminalSize.ws_col = cols
    
    kill(getpid(), SIGWINCH)
}

@_cdecl("my_exit")
func my_exit(_ status: Int32) {
    pthread_exit(nil)
}

@_cdecl("my_abort")
func my_abort() {
    NSLog("abort was called — but we're stubbing it!")
    
}

func install_exit_hook() {
    let exitReplacement = unsafeBitCast(my_exit as @convention(c) (Int32) -> Void, to: UnsafeMutableRawPointer.self)
    let abortReplacement = unsafeBitCast(my_abort as @convention(c) () -> Void, to: UnsafeMutableRawPointer.self)

    var exit_rebinding = rebinding(
        name: strdup("exit"),
        replacement: exitReplacement,
        replaced: &original_exit
    )
    
    var exit2_rebinding = rebinding(
        name: strdup("_exit"),
        replacement: exitReplacement,
        replaced: &original_exit
    )

    var abort_rebinding = rebinding(
        name: strdup("abort"),
        replacement: abortReplacement,
        replaced: &original_abort
    )
    
    install_pty_hooks()

    let result1 = rebind_symbols(&exit_rebinding, 1)
    let result2 = rebind_symbols(&exit2_rebinding, 1)
    let result3 = rebind_symbols(&abort_rebinding, 1)

    if result1 + result2 + result3 == 0 {
        NSLog("Successfully rebound exit() and abort()")
    } else {
        NSLog("Failed to rebind exit() or abort()")
    }
}
