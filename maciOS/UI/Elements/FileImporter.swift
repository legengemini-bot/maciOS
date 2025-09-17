//
//  FileImporter.swift
//  maciOS
//
//  Created by Stossy11 on 22/08/2025.
//

import UIKit
import UniformTypeIdentifiers
import Combine

class FileImporterManager: NSObject, ObservableObject, UIDocumentPickerDelegate {
    static let shared = FileImporterManager()
    
    private var currentCompletion: ((Result<[URL], Error>) -> Void)?
    private var currentDocumentPicker: UIDocumentPickerViewController?
    private var securityScopedURLs: [URL] = []
    
    private override init() {
        super.init()
    }
    
    func importFiles(
        types: [UTType],
        allowMultiple: Bool = false,
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        self.currentCompletion = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = allowMultiple
        documentPicker.modalPresentationStyle = .formSheet
        
        self.currentDocumentPicker = documentPicker
        
        guard let topViewController = getTopViewController() else {
            let error = NSError(
                domain: "FileImporterManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to find presenting view controller."]
            )
            currentCompletion?(.failure(error))
            return
        }
        
        topViewController.present(documentPicker, animated: true)
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return nil }
        
        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }
    
    private func stopAccessingSecurityScopedResources() {
        for url in securityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        securityScopedURLs.removeAll()
    }
    
    private func cleanup() {
        currentCompletion = nil
        currentDocumentPicker = nil
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var accessibleURLs: [URL] = []
        
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                securityScopedURLs.append(url)
                accessibleURLs.append(url)
            } else {
                accessibleURLs.append(url)
            }
        }
        
        currentCompletion?(.success(accessibleURLs))
        cleanup()
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        let error = NSError(
            domain: "FileImporterManager",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "User cancelled the document picker."]
        )
        currentCompletion?(.failure(error))
        cleanup()
    }
}

extension FileImporterManager {
    
    func importSingleFile(completion: @escaping (Result<URL, Error>) -> Void) {
        importFiles(types: [.item], allowMultiple: false) { result in
            switch result {
            case .success(let urls):
                if let firstURL = urls.first {
                    completion(.success(firstURL))
                } else {
                    completion(.failure(NSError(domain: "FileImporterManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No file selected."])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func importMultipleFiles(completion: @escaping (Result<[URL], Error>) -> Void) {
        importFiles(types: [.item], allowMultiple: true, completion: completion)
    }
    
    func importImages(allowMultiple: Bool = false, completion: @escaping (Result<[URL], Error>) -> Void) {
        importFiles(types: [.image], allowMultiple: allowMultiple, completion: completion)
    }
    
    func importDocuments(allowMultiple: Bool = false, completion: @escaping (Result<[URL], Error>) -> Void) {
        let documentTypes: [UTType] = [.pdf, .plainText, .rtf, .html, .xml, .json]
        importFiles(types: documentTypes, allowMultiple: allowMultiple, completion: completion)
    }
}

extension URL {
    @available(iOS, introduced: 14.0, deprecated: 16.0, message: "Use URL.documentsDirectory on iOS 16 and above")
    static var documentsDirectory: URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory
    }
}
