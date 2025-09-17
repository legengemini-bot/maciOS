//
//  WindowDockView.swift
//  maciOS
//
//  Created by Stossy11 on 13/09/2025.
//


import SwiftUI
import SwiftTerm

struct WindowDockView: View {
    @ObservedObject var manager = WindowViewManager.shared

    var body: some View {
        HStack(spacing: 8) {
            // Minimized floating NSWindows
            ForEach(minimizedFloatingWindows.indices, id: \.self) { index in
                let window = minimizedFloatingWindows[index]
                Button(action: {
                    restoreFloatingWindow(window)
                }) {
                    Text(windowTitle(window))
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
            }

            // Minimized native SwiftUI windows
            ForEach(minimizedNativeWindows.indices, id: \.self) { index in
                let window = minimizedNativeWindows[index]
                Button(action: {
                    restoreNativeWindow(window)
                }) {
                    if window.window.base is AnyView {
                        if let title = window.window.title {
                            Text(title)
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                        } else {
                            if index == 0 {
                                Text("Window")
                                    .padding(6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(6)
                            } else {
                                Text("Window \(index)")
                                    .padding(6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    } else {
                        Text(viewTypeName(window))
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    // MARK: - Filter minimized windows

    var minimizedFloatingWindows: [(shown: Bool, frame: CGRect, window: NSWindow)] {
        manager.floatingWindows.filter { !$0.shown }
    }

    var minimizedNativeWindows: [(shown: Bool, window: AnyWindowRepresentable)] {
        manager.nativeFloatingWindow.filter { !$0.shown }
    }

    // MARK: - Restore windows

    func restoreFloatingWindow(_ window: (shown: Bool, frame: CGRect, window: NSWindow)) {
        if let index = manager.floatingWindows.firstIndex(where: { $0.window == window.window }) {
            manager.floatingWindows[index].shown = true
            window.window.makeKeyAndOrderFront(nil)
        }
    }

    func restoreNativeWindow(_ window: (shown: Bool, window: AnyWindowRepresentable)) {
        if let index = manager.nativeFloatingWindow.firstIndex(where: { $0.window == window.window }) {
            manager.nativeFloatingWindow[index].shown = true
        }
        
    }

    // MARK: - Titles

    func windowTitle(_ window: (shown: Bool, frame: CGRect, window: NSWindow)) -> String {
        window.window.title.isEmpty ? "Untitled" : window.window.title
    }

    func viewTypeName(_ window: (shown: Bool, window: AnyWindowRepresentable)) -> String {
        // If it's AnyView, try to get the underlying type using Mirror
        if window.window is AnyView {
            return "AnyView \(UUID().uuidString)"
        }
        if window.window.base is TerminalView {
            return "Terminal"
        } else {
            return String(describing: type(of: window.window.base))
        }
    }
}
