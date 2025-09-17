//
//  DocumentPicker.swift
//  maciOS
//
//  Created by Stossy11 on 29/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

class DockumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    var onPick: (URL) -> Void
    
    init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let firstURL = urls.first {
            let cool = firstURL.startAccessingSecurityScopedResource()
            onPick(firstURL)
            if cool {
                firstURL.stopAccessingSecurityScopedResource()
            }
        }
    }
}
