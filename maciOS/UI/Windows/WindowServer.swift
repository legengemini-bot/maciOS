//
//  WindowServer.swift
//  maciOS
//
//  Created by Stossy11 on 31/08/2025.
//

import SwiftTerm
import SwiftUI

struct WindowServer: View {
    @StateObject private var floatingWindows = WindowViewManager.shared
    @StateObject private var terminalDelegate = iOSTerminalDelegate()
    
    var body: some View {
        ZStack {
            ForEach(Array(floatingWindows.nativeFloatingWindow.enumerated()), id: \.offset) { _, item in
                if item.shown {
                    if let item2 = item.window.base as? UIView {
                        if item2 is TerminalView {
                            FloatingWindow(
                                title: item.window.title ?? "Terminal",
                                uiView: item2,
                                windowSize: item2.frame, nativeWindow: item.window)
                            
                        } else {
                            FloatingWindow(
                                title: item.window.title ?? "",
                                uiView: item2,
                                windowSize: item2.frame, nativeWindow: item.window)
                        }
                    } else if let item2 = item.window.base as? AnyView {
                        FloatingWindow(
                            title: item.window.title ?? "",
                            nativeWindow: item.window
                        ) {
                            item2
                        }
                        .ignoresSafeArea()
                        .onAppear() {
                        }
                    }
                }
            }
            

            ForEach(Array(floatingWindows.floatingWindows.enumerated()), id: \.offset) { _, item in
                if item.shown {
                    FloatingWindow(window: item.window)
                        .ignoresSafeArea()
                }
            }
        }
    }
}
