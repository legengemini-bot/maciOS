//
//  SwiftTermView.swift
//  maciOS
//
//  Created by Stossy11 on 24/08/2025.
//

import SwiftTerm
import SwiftUI

struct SwiftTermView: UIViewRepresentable {
    @StateObject private var terminalDelegate = iOSTerminalDelegate()
    
    func makeUIView(context: Context) -> TerminalView {
        let terminalView = TerminalView()
        terminalView.terminalDelegate = terminalDelegate
        
        terminalView.allowMouseReporting = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            terminalView.font = UIFont.monospacedSystemFont (ofSize: 10, weight: .regular)
        }
        
        terminalDelegate.setTerminalView(terminalView)
        
        return terminalView
    }
    
    func updateUIView(_ uiView: TerminalView, context: Context) {
    }
}
