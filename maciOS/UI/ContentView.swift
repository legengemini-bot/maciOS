//
//  ContentView.swift
//  maciOS
//
//  Created by Stossy11 on 22/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftTerm
import Combine

struct ContentView: View {
    @State var machO: [MachOPatcher] = []
    @StateObject private var floatingWindows = WindowViewManager.shared
    @StateObject private var terminalDelegate = iOSTerminalDelegate()
    
    @State private var documentPickerDelegate: DockumentPickerDelegate?
    
    var body: some View {
        ZStack {
            MenuBarView(machO: $machO)
            
            KeyPressView()
                .allowsHitTesting(false)
            

            
            WindowServer()
                .scaleEffect(0.8)
                // .modifier(NonRetinaScalingModifier())
            VStack {
                Spacer()
                
                WindowDockView()
                    .zIndex(10000)
            }
        }
        .onAppear() {
            setupTerminal()
        }
    }
    
    private func setupTerminal() {
        let view = createTerminalView()
        floatingWindows.addNativeWindow(view)
        
        floatingWindows.addNativeWindow(AnyView(DoomControllerView()), "Virtual Keyboard")
    }
    

    
    func createTerminalView() -> TerminalView {
        let terminalView = TerminalView()
        
        terminalView.terminalDelegate = terminalDelegate
        
        terminalView.allowMouseReporting = true
        terminalView.frame = CGRect(x: 0, y: 0, width: 640, height: 480)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            terminalView.font = UIFont.monospacedSystemFont (ofSize: 10, weight: .regular)
        }
        
        terminalDelegate.setTerminalView(terminalView)
        return terminalView
    }
}

struct DoomControllerView: View {
    var body: some View {
        VStack(spacing: 20) {
            HoldableButton(label: "W", keyCode: 13) // W = 13
            HStack(spacing: 20) {
                HoldableButton(label: "A", keyCode: 0)  // A = 0
                HoldableButton(label: "S", keyCode: 1)  // S = 1
                HoldableButton(label: "D", keyCode: 2)  // D = 2
            }
            HStack(spacing: 20) {
                HoldableButton(label: "Enter", keyCode: 36) // Enter = 36
                HoldableButton(label: "Esc", keyCode: 53)   // Escape = 53
            }
        }
        .font(.title)
        .padding()
    }
}

/// A reusable SwiftUI button that sends keyDown on press and keyUp on release
struct HoldableButton: View {
    let label: String
    let keyCode: UInt16
    
    @State private var isPressed = false
    
    var body: some View {
        Text(label)
            .frame(width: 80, height: 80)
            .background(isPressed ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
            .cornerRadius(12)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                if pressing {
                    sendKeyDown()
                    isPressed = true
                } else {
                    sendKeyUp()
                    isPressed = false
                }
            }, perform: {})
    }
    
    private func sendKeyDown() {
         let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: Date().timeIntervalSince1970,
            characters: "",
            charactersIgnoringModifiers: "",
            keyCode: keyCode
        )
        
        NSEvent.send(event)
    }
    
    private func sendKeyUp() {
        let event = NSEvent.keyEvent(
            with: .keyUp,
            location: .zero,
            modifierFlags: [],
            timestamp: Date().timeIntervalSince1970,
            characters: "",
            charactersIgnoringModifiers: "",
            keyCode: keyCode
        )
        
        NSEvent.send(event)
    }
}


struct KeyPressView: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: UIViewController {
        
        // Allow this controller to become first responder
        override var canBecomeFirstResponder: Bool { true }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder() // important to start receiving key events
        }
        
        
        // Capture all key presses
        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                guard let key = press.key else { continue }
                print("Key pressed: \(key.characters), keyCode: \(key.keyCode.rawValue)")
                
                let event = NSEvent.keyEvent(
                    with: .keyDown,
                    location: .zero,
                    modifierFlags: [],
                    timestamp: press.timestamp, // use the real press timestamp
                    characters: key.characters,
                    charactersIgnoringModifiers: key.charactersIgnoringModifiers,
                    keyCode: UInt16(mapIOSKeycodeToMacOS(key.keyCode.rawValue) ?? 0)
                )
                
                NSEvent.send(event)
            }
            super.pressesBegan(presses, with: event)
        }
        
        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                guard let key = press.key else { continue }
                
                let event = NSEvent.keyEvent(
                    with: .keyUp,
                    location: .zero,
                    modifierFlags: [],
                    timestamp: press.timestamp, // use the real press timestamp
                    characters: key.characters,
                    charactersIgnoringModifiers: key.charactersIgnoringModifiers,
                    keyCode: UInt16(mapIOSKeycodeToMacOS(key.keyCode.rawValue) ?? 0)
                )
                
                NSEvent.send(event)
            }
            super.pressesEnded(presses, with: event)
        }
    }
    
    func makeUIViewController(context: Context) -> Coordinator {
        Coordinator()
    }
    
    func updateUIViewController(_ uiViewController: Coordinator, context: Context) {}
}

func mapIOSKeycodeToMacOS(_ iOSKeycode: Int) -> Int? {
    let keycodeMap: [Int: Int] = [
        // Numbers
        4: 0,   // A -> Ad
        5: 11,  // B -> B
        6: 8,   // C -> C
        7: 2,   // D -> D
        8: 14,  // E -> E
        9: 3,   // F -> F
        10: 5,  // G -> G
        11: 4,  // H -> H
        12: 34, // I -> I
        13: 38, // J -> J
        14: 40, // K -> K
        15: 37, // L -> L
        16: 46, // M -> M
        17: 45, // N -> N
        18: 31, // O -> O
        19: 35, // P -> P
        20: 12, // Q -> Q
        21: 15, // R -> R
        22: 1,  // S -> S
        23: 17, // T -> T
        24: 32, // U -> U
        25: 9,  // V -> V
        26: 13, // W -> W
        27: 7,  // X -> X
        28: 16, // Y -> Y
        29: 6,  // Z -> Z
        
        // Numbers (top row)
        30: 29, // 1 -> 1
        31: 18, // 2 -> 2
        32: 19, // 3 -> 3
        33: 20, // 4 -> 4
        34: 21, // 5 -> 5
        35: 23, // 6 -> 6
        36: 22, // 7 -> 7
        37: 26, // 8 -> 8
        38: 28, // 9 -> 9
        39: 25, // 0 -> 0
        
        // Special keys
        40: 36, // Enter/Return -> Return
        41: 53, // Escape -> Escape
        42: 51, // Backspace -> Delete
        43: 48, // Tab -> Tab
        44: 49, // Space -> Space
        
        // Symbols
        45: 27, // - -> -
        46: 24, // = -> =
        47: 33, // [ -> [
        48: 30, // ] -> ]
        49: 42, // \ -> \
        51: 41, // ; -> ;
        52: 39, // ' -> '
        53: 50, // ` -> `
        54: 43, // , -> ,
        55: 47, // . -> .
        56: 44, // / -> /
        
        // Function keys
        58: 122, // F1 -> F1
        59: 120, // F2 -> F2
        60: 99,  // F3 -> F3
        61: 118, // F4 -> F4
        62: 96,  // F5 -> F5
        63: 97,  // F6 -> F6
        64: 98,  // F7 -> F7
        65: 100, // F8 -> F8
        66: 101, // F9 -> F9
        67: 109, // F10 -> F10
        68: 103, // F11 -> F11
        69: 111, // F12 -> F12
        
        // Arrow keys
        79: 123, // Right Arrow -> Right Arrow
        80: 124, // Left Arrow -> Left Arrow
        81: 125, // Down Arrow -> Down Arrow
        82: 126, // Up Arrow -> Up Arrow
        
        // Modifiers
        224: 55, // Left Cmd -> Left Cmd
        225: 54, // Left Shift -> Left Shift
        226: 58, // Left Alt/Option -> Left Option
        227: 59, // Left Ctrl -> Left Control
        228: 55, // Right Cmd -> Right Cmd (same as left on macOS)
        229: 60, // Right Shift -> Right Shift
        230: 61, // Right Alt/Option -> Right Option
        231: 62, // Right Ctrl -> Right Control
    ]
    
    return keycodeMap[iOSKeycode]
}

class DocumentPickerContainer: UIView {
    private let picker: UIDocumentPickerViewController
    
    init(picker: UIDocumentPickerViewController) {
        self.picker = picker
        super.init(frame: .zero)
        setupPicker()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPicker() {
        backgroundColor = .systemBackground
        
        addSubview(picker.view)
        picker.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            picker.view.topAnchor.constraint(equalTo: topAnchor),
            picker.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        picker.view.isUserInteractionEnabled = true
        isUserInteractionEnabled = true
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Make sure touches are properly forwarded to the picker
        let result = super.hitTest(point, with: event)
        if result == self {
            return picker.view.hitTest(point, with: event)
        }
        return result
    }
}

#Preview {
    ContentView()
}


extension Character {
    var isPrintable: Bool {
        return !isWhitespace && !isNewline
    }
}

struct NavigationStack<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 16.0, *) {
            SwiftUI.NavigationStack(root: content)
        } else {
            NavigationView(content: content)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}


