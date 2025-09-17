//
//  WindowViewManager.swift
//  maciOS
//
//  Created by Stossy11 on 29/08/2025.
//

import SwiftUI
import Combine

protocol WindowRepresentable {

}


extension UIView: WindowRepresentable {}
extension AnyView: WindowRepresentable {}


struct AnyWindowRepresentable: Equatable {
    let base: WindowRepresentable
    let title: String?
    private let id: UUID

    init(_ base: WindowRepresentable, title: String? = nil) {
        self.base = base
        self.id = UUID()
        self.title = title
    }

    static func == (lhs: AnyWindowRepresentable, rhs: AnyWindowRepresentable) -> Bool {
        lhs.id == rhs.id
    }
}



struct WindowID: Hashable, Identifiable {
    let id = UUID()
    let type: WindowType
    
    enum WindowType: Hashable {
        case native(index: Int)
        case nsWindow(windowID: String)
    }
}

struct WindowMetadata {
    let id: WindowID
    var zIndex: Int
    var isActive: Bool
    
    init(id: WindowID, zIndex: Int, isActive: Bool = false) {
        self.id = id
        self.zIndex = zIndex
        self.isActive = isActive
    }
}

class WindowViewManager: ObservableObject {
    @Published var floatingWindows: [(shown: Bool, frame: CGRect, window: NSWindow)] = []
    @Published var nativeFloatingWindow: [(shown: Bool, window: AnyWindowRepresentable)] = []
    
    @Published var windowOrder: [WindowMetadata] = []
    private var nextZIndex: Int = 0
    
    static var shared = WindowViewManager()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidCreate(_:)),
            name: NSNotification.Name("NSWindowDidCreateNotification"),
            object: nil
        )
    }

    @objc private func windowDidCreate(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let window = userInfo["nsWindow"] as? NSWindow {
            DispatchQueue.main.async { [self] in
                floatingWindows.append((shown: true, frame: window.frame, window: window))
            }
        } else {
            
            print("noooo \(notification.userInfo), \(notification.userInfo?["nsWindow"] as? NSWindow)")
            
            
        }
    }
    
    public func addNativeWindow<Content: View>(title: String? = nil, @ViewBuilder content: () -> Content) {
        nativeFloatingWindow.append((shown: true, window: AnyWindowRepresentable(AnyView(content()), title: title)))
    }
    
    public func addNativeWindow(_ view: WindowRepresentable, _ title: String? = nil) {
        nativeFloatingWindow.append((shown: true, window: AnyWindowRepresentable(view, title: title)))
    }
    
    public func removeNativeWindow(at index: Int) {
        guard index < nativeFloatingWindow.count else { return }
        nativeFloatingWindow.remove(at: index)
    }
    
    func registerWindow(id: WindowID) {
        let metadata = WindowMetadata(id: id, zIndex: nextZIndex)
        windowOrder.append(metadata)
        nextZIndex += 1
    }
    
    func bringToFront(id: WindowID) {
        guard let index = windowOrder.firstIndex(where: { $0.id == id }) else { return }
        
        for i in windowOrder.indices {
            windowOrder[i].isActive = false
        }
        
        windowOrder[index].zIndex = nextZIndex
        windowOrder[index].isActive = true
        nextZIndex += 1
        
        windowOrder.sort { $0.zIndex < $1.zIndex }
    }
    
    func removeWindow(id: WindowID) {
        windowOrder.removeAll { $0.id == id }
    }
    
    func zIndex(for id: WindowID) -> Int {
        return windowOrder.first { $0.id == id }?.zIndex ?? 0
    }
    
    func isActive(id: WindowID) -> Bool {
        return windowOrder.first { $0.id == id }?.isActive ?? false
    }
    
    var frontmostWindow: WindowID? {
        return windowOrder.max { $0.zIndex < $1.zIndex }?.id
    }
}
