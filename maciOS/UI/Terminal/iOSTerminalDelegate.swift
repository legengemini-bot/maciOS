//
//  iOSTerminalDelegate.swift
//  maciOS
//
//  Created by Stossy11 on 24/08/2025.
//

import SwiftUI
import Combine
import SwiftTerm

class iOSTerminalDelegate: NSObject, TerminalViewDelegate, ObservableObject {
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var inputPipe: Pipe?
    
    private var stdoutBuffer = ""
    private var stderrBuffer = ""
    
    @Published var stdoutLines: [String] = []
    @Published var stderrLines: [String] = []
    @AppStorage("HideErrorLogs") var hideLogs = true
    
    private var originalStdout: Int32 = -1
    private var originalStderr: Int32 = -1
    private var originalStdin: Int32 = -1
    
     var terminalView: TerminalView?
    private var inputBuffer = ""
    
    override init() {
        super.init()
        setupRedirection()
    }
    
    func setTerminalView(_ terminalView: TerminalView) {
        self.terminalView = terminalView
        updateTerminalSize(rows: UInt16(terminalView.getTerminal().cols), cols: UInt16(terminalView.getTerminal().rows))
    }
    
    private func setupRedirection() {
        outputPipe = Pipe()
        errorPipe = Pipe()
        inputPipe = Pipe()
        
        guard let outputPipe = outputPipe,
              let errorPipe = errorPipe,
              let inputPipe = inputPipe else { return }
        
        // Store original file descriptors
        originalStdout = dup(STDOUT_FILENO)
        originalStderr = dup(STDERR_FILENO)
        originalStdin = dup(STDIN_FILENO)
        
        // Set unbuffered mode for stdout/stderr
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        
        // Redirect streams
        dup2(outputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(errorPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        dup2(inputPipe.fileHandleForReading.fileDescriptor, STDIN_FILENO)
        
        // stdout reader
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let string = String(data: data, encoding: .utf8) else { return }
            
            // Write back to original stdout
            if let originalStdout = self?.originalStdout, originalStdout != -1 {
                _ = data.withUnsafeBytes { ptr in
                    write(originalStdout, ptr.baseAddress, data.count)
                }
            }
            
            DispatchQueue.main.async {
                self?.appendToBuffer(&self!.stdoutBuffer, incoming: string, isError: false)
            }
        }

        // stderr reader
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let string = String(data: data, encoding: .utf8) else { return }
            
            // Write back to original stderr
            if let originalStderr = self?.originalStderr, originalStderr != -1 {
                _ = data.withUnsafeBytes { ptr in
                    write(originalStderr, ptr.baseAddress, data.count)
                }
            }
            
            Task {
                await MainActor.run {
                    self?.appendToBuffer(&self!.stderrBuffer, incoming: string, isError: true)
                }
            }
        }

    }
    
    private func appendToBuffer(_ buffer: inout String, incoming: String, isError: Bool) {
        buffer += incoming
        
        while let range = buffer.range(of: "\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])
            
            guard let cleaned = cleanLog(line), !cleaned.isEmpty else { continue }
            
            if isError {
                stderrLines.append(cleaned)
                terminalView?.feed(text: cleaned + "\r\n")
            } else {
                stdoutLines.append(cleaned)
                terminalView?.feed(text: cleaned + "\r\n")
            }
        }
    }
    
    private func cleanLog(_ raw: String) -> String? {
        if hideLogs {
            if raw.contains(":"), raw.contains("\(Bundle.main.bundleName)["), raw.contains("]") { return nil }
            if raw.contains("OSLOG-"), !raw.contains("Failed to load dylib: dlopen") { return nil }
        }
        return raw
    }
    
    private func restoreStandardStreams() {
        return;
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        
        setvbuf(stdout, nil, _IOFBF, Int(BUFSIZ))
        setvbuf(stderr, nil, _IOFBF, Int(BUFSIZ))
        
        if originalStdout != -1 {
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
        }
        if originalStderr != -1 {
            dup2(originalStderr, STDERR_FILENO)
            close(originalStderr)
        }
        if originalStdin != -1 {
            dup2(originalStdin, STDIN_FILENO)
            close(originalStdin)
        }
        
        try? outputPipe?.fileHandleForReading.close()
        try? outputPipe?.fileHandleForWriting.close()
        try? errorPipe?.fileHandleForReading.close()
        try? errorPipe?.fileHandleForWriting.close()
        try? inputPipe?.fileHandleForReading.close()
        try? inputPipe?.fileHandleForWriting.close()
    }
    
    
    // MARK: - TerminalViewDelegate
    
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        updateTerminalSize(rows: UInt16(newRows), cols: UInt16(newCols))
    }
    
    func setTerminalTitle(source: TerminalView, title: String) {
        // Handle title changes
    }
    
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        // Handle directory changes
    }
    
    // This is the key function - it receives input from the terminal and forwards it to stdin
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        guard let inputPipe = inputPipe else { return }
        
        // Convert the raw bytes to data and write directly to stdin pipe
        let inputData = Data(data)
        DispatchQueue.main.async {
            self.terminalView?.feed(text: String(data: inputData, encoding: .utf8) ?? "")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try inputPipe.fileHandleForWriting.write(contentsOf: inputData)
                
            } catch {
                DispatchQueue.main.async {
                    print("Error writing to stdin pipe: \(error)")
                }
            }
        }
    }

    func scrolled(source: TerminalView, position: Double) {
        // Handle scrolling
    }
    
    func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        if let url = URL(string: link) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    func bell(source: TerminalView) {
        #if os(iOS)
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        #endif
    }
    
    func clipboardCopy(source: TerminalView, content: Data) {
        if let string = String(data: content, encoding: .utf8) {
            #if os(iOS)
            UIPasteboard.general.string = string
            #endif
        }
    }
    
    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
        // Handle iTerm2 specific content
    }
    
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
        // Handle visual changes
    }
    
    deinit {
        restoreStandardStreams()
    }
}

extension Bundle {
    var bundleName: String {
        return object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown"
    }
}
