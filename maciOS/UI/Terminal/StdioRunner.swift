//
//  StdioRunner.swift
//  maciOS
//
//  Created by Stossy11 on 30/08/2025.
//

import Foundation
import Combine
import Darwin

class StdioRunner: ObservableObject {
    private var inputPipe: [Int32] = [0, 0]
    private var outputPipe: [Int32] = [0, 0]
    
    // Change to emit individual lines instead of accumulating
    @Published var newOutputLine: String = ""
    
    private var readingQueue = DispatchQueue(label: "stdio-reader", qos: .utility)
    private var isReading = true
    
    // Store original file descriptors
    private let originalStdout = dup(STDOUT_FILENO)
    private let originalStderr = dup(STDERR_FILENO)
    
    init() {
        setupPipes()
        startReadingOutput()
    }
    
    private func setupPipes() {
        guard pipe(&inputPipe) == 0, pipe(&outputPipe) == 0 else {
            print("Failed to create pipes")
            return
        }
        
        // Make reading non-blocking
        var flags = fcntl(outputPipe[0], F_GETFL)
        fcntl(outputPipe[0], F_SETFL, flags | O_NONBLOCK)
        
        // Redirect stdout and stderr to our output pipe
        dup2(outputPipe[1], STDOUT_FILENO)
        dup2(outputPipe[1], STDERR_FILENO)
        
        // Close write end in parent (we only read)
        close(outputPipe[1])
        // Close read end of input pipe in parent (we only write)
        close(inputPipe[0])
    }
    
    func sendInput(_ text: String) {
        let data = text.data(using: .utf8) ?? Data()
        data.withUnsafeBytes { bytes in
            write(inputPipe[1], bytes.bindMemory(to: UInt8.self).baseAddress, data.count)
        }
    }
    
    private func startReadingOutput() {
        readingQueue.async { [weak self] in
            guard let self = self else { return }
            
            var buffer = [UInt8](repeating: 0, count: 4096)
            var partialLine = ""
            
            while self.isReading {
                let bytesRead = read(self.outputPipe[0], &buffer, buffer.count)
                
                if bytesRead > 0 {
                    if let chunk = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
                        let lines = (partialLine + chunk).components(separatedBy: .newlines)
                        
                        // Process complete lines
                        for i in 0..<lines.count - 1 {
                            let line = lines[i]
                            if !line.isEmpty {
                                DispatchQueue.main.async {
                                    self.newOutputLine = line
                                }
                            }
                        }
                        
                        // Keep the last part as partial line
                        partialLine = lines.last ?? ""
                    }
                } else if bytesRead == 0 {
                    // EOF - process any remaining partial line
                    if !partialLine.isEmpty {
                        DispatchQueue.main.async {
                            self.newOutputLine = partialLine
                        }
                    }
                    break
                } else {
                    // Error or would block
                    if errno == EAGAIN || errno == EWOULDBLOCK {
                        // No data available right now, wait a bit
                        usleep(10000) // 10ms
                    } else {
                        // Real error
                        break
                    }
                }
            }
        }
    }
    
    deinit {
        isReading = false
        
        // Restore original stdout/stderr
        dup2(originalStdout, STDOUT_FILENO)
        dup2(originalStderr, STDERR_FILENO)
        
        // Close our pipes
        close(inputPipe[1])
        close(outputPipe[0])
        close(originalStdout)
        close(originalStderr)
    }
}
