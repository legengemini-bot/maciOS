//
//  FloatingWindowView.swift
//  maciOS
//
//  Created by Stossy11 on 29/08/2025.
//

import SwiftUI
import SwiftTerm
import UIKit

struct FloatingWindow<Content: View>: View {
    @State var title: String
    let content: () -> Content
    var uikit = false
    
    @State private var offset: CGSize = .zero
    @State private var windowSize: CGRect = .zero
    @State private var currentSize: CGSize = CGSize(width: 400, height: 300)
    var nsWindow: NSWindow?
    var nativeWindow: AnyWindowRepresentable?
    
    // Window management
    @StateObject private var windowManager = WindowViewManager.shared
    @State private var windowID: WindowID
    
    init(title: String, nativeWindow: AnyWindowRepresentable? = nil,@ViewBuilder content: @escaping () -> Content, nsWindow: NSWindow? = nil) {
        self.title = title
        self.content = content
        self.nativeWindow = nativeWindow
        self.nsWindow = nsWindow
        
        if let nsWindow = nsWindow {
            self._windowID = State(initialValue: WindowID(type: .nsWindow(windowID: nsWindow.identifier.uuidString ?? UUID().uuidString)))
        } else {
            self._windowID = State(initialValue: WindowID(type: .native(index: Int.random(in: 0...10000))))
        }
    }
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            DraggableTitleBar(
                title: title,
                offset: $offset,
                isActive: windowManager.isActive(id: windowID),
                onTitleBarTapped: {
                    windowManager.bringToFront(id: windowID)
                },
                window: nsWindow,
                nativeWindow: nativeWindow
            )
            .frame(height: 30)
            .allowsHitTesting(true)
            
            if !uikit {
                content()
                    .allowsHitTesting(windowManager.isActive(id: windowID))
                    .disabled(!windowManager.isActive(id: windowID))
                    .background(Color(uiColor: .systemBackground))
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .allowsHitTesting(false)
                                .onAppear {
                                    let rect = CGRect(origin: .zero, size: geo.size)
                                    windowSize = rect
                                    if currentSize == .zero || (currentSize.width == 0 && currentSize.height == 0) {
                                        currentSize = geo.size
                                    }
                                }
                                .onChange(of: geo.size) { newSize in
                                    let rect = CGRect(origin: .zero, size: newSize)
                                    windowSize = rect
                                    if currentSize.width == 0 && currentSize.height == 0 {
                                        currentSize = newSize
                                    }
                                }
                        }
                            .allowsHitTesting(false)
                    )
                    .overlay {
                        FloatingHitTestUIView(
                            onActivate: { windowManager.bringToFront(id: windowID) },
                            isActive: { windowManager.isActive(id: windowID) }
                        )
                        .frame(width: currentSize.width, height: currentSize.height + 30)
                    }
            } else {
                content()
                    .background(Color(uiColor: .systemBackground))
                    .frame(width: currentSize.width, height: currentSize.height)
                    .overlay {
                        FloatingHitTestUIView(
                            onActivate: { windowManager.bringToFront(id: windowID) },
                            isActive: { windowManager.isActive(id: windowID) }
                        )
                        .frame(width: currentSize.width, height: currentSize.height + 30)
                    }
            }
        }
        .frame(width: currentSize.width, height: currentSize.height + 30)
        .cornerRadius(12)
        .shadow(radius: windowManager.isActive(id: windowID) ? 20 : 5)
        .scaleEffect(windowManager.isActive(id: windowID) ? 1.0 : 0.98)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    windowManager.isActive(id: windowID) ?
                    Color.blue.opacity(0.2) : Color.clear,
                    lineWidth: windowManager.isActive(id: windowID) ? 2 : 1
                )
        )
        .overlay(
            Group {
                if nsWindow?.resizable == true {
                    ResizeHandle(currentSize: $currentSize, nsWindow: nsWindow)
                        .allowsHitTesting(true)
                } else if nsWindow == nil {
                    ResizeHandle(currentSize: $currentSize, nsWindow: nsWindow)
                        .allowsHitTesting(true)
                }
            }
        )
        .offset(offset)
        .zIndex(Double(windowManager.zIndex(for: windowID)))
        .allowsHitTesting(true)
        .onTapGesture {
            windowManager.bringToFront(id: windowID)
        }
        .onAppear {
            windowManager.registerWindow(id: windowID)
        }
        .onDisappear {
            windowManager.removeWindow(id: windowID)
        }
        .animation(.easeOut(duration: 0.2), value: windowManager.isActive(id: windowID))
    }
}

struct FloatingHitTestUIView: UIViewRepresentable {
    var onActivate: () -> Void
    var isActive: () -> Bool

    func makeUIView(context: Context) -> FloatingHitTestView {
        let view = FloatingHitTestView()
        view.backgroundColor = .clear
        view.onActivateWindow = onActivate
        view.isWindowActive = isActive
        return view
    }

    func updateUIView(_ uiView: FloatingHitTestView, context: Context) {
        uiView.onActivateWindow = onActivate
        uiView.isWindowActive = isActive
    }
}

class FloatingHitTestView: UIView {

    var onActivateWindow: (() -> Void)?
    var isWindowActive: (() -> Bool)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if event?.type != .touches {
            return nil
        }
        
        if isWindowActive?() == true {
            return nil
        }
        
        return self
    }
    
    // Override to prevent keyboard input when not active
    override var canBecomeFirstResponder: Bool {
        return isWindowActive?() == true
    }
}

class WindowFocusTextField: UITextField {
    var isWindowActiveCheck: (() -> Bool)?
    
    override var canBecomeFirstResponder: Bool {
        return isWindowActiveCheck?() == true
    }
    
    override func becomeFirstResponder() -> Bool {
        guard isWindowActiveCheck?() == true else { return false }
        return super.becomeFirstResponder()
    }
    
    // Intercept key presses and only allow them if window is active
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard isWindowActiveCheck?() == true else { return }
        super.pressesBegan(presses, with: event)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard isWindowActiveCheck?() == true else { return }
        super.pressesEnded(presses, with: event)
    }
}

struct ResizeHandle: View {
    @Binding var currentSize: CGSize
    let nsWindow: NSWindow?
    
    @State private var isDragging = false
    @State private var startSize: CGSize = .zero
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            withAnimation(.none) {
                                if !isDragging {
                                    isDragging = true
                                    startSize = currentSize
                                }
                                
                                let minWidth: CGFloat = nsWindow?.minSize.width ?? 200
                                let maxWidth: CGFloat = nsWindow?.maxSize.width ?? 1200
                                let minHeight: CGFloat = nsWindow?.minSize.height ?? 150
                                let maxHeight: CGFloat = nsWindow?.maxSize.height ?? 800
                                
                                let newWidth = max(
                                    minWidth,
                                    min(
                                        maxWidth,
                                        startSize.width + value.translation.width
                                    )
                                )
                                
                                let newHeight = max(
                                    minHeight,
                                    min(
                                        maxHeight,
                                        startSize.height + value.translation.height
                                    )
                                )
                                
                                let newSize = CGSize(width: newWidth, height: newHeight)
                                currentSize = newSize
                                
                                if let window = nsWindow {
                                    let newFrame = CGRect(
                                        origin: window.frame.origin,
                                        size: CGSize(width: newWidth, height: newHeight + 30)
                                    )
                                    window.setFrame(newFrame, display: true, animate: false)
                                }
                            }
                        }
                )
                .padding(8)
            }
        }
    }
}

struct UIViewWrapper<Content: UIView>: UIViewRepresentable {
    let uiView: Content
    
    func makeUIView(context: Context) -> Content {
        uiView.isUserInteractionEnabled = true
        return uiView
    }
    
    func updateUIView(_ uiView: Content, context: Context) {
        if let superview = uiView.superview {
            uiView.frame = superview.bounds
        }
        
        uiView.isUserInteractionEnabled = true
    }
}



extension FloatingWindow where Content == UIViewWrapper<UIView> {
    init(title: String, uiView: UIView, windowSize: CGRect, nativeWindow: AnyWindowRepresentable? = nil) {
        self.title = title
        self.windowSize = windowSize
        self.currentSize = windowSize.size
        self.content = { UIViewWrapper(uiView: uiView) }
        self.uikit = true
        self.nsWindow = nil
        self.nativeWindow = nativeWindow
        self._windowID = State(initialValue: WindowID(type: .native(index: Int.random(in: 0...10000))))
    }
    
    init(window: NSWindow) {
        self.title = window.title ?? ""
        self.windowSize = window.frame
        self.currentSize = window.frame.size
        self.content = { UIViewWrapper(uiView: window.contentView.uiView) }
        self.uikit = true
        self.nsWindow = window
        self.nativeWindow = nil
        self._windowID = State(initialValue: WindowID(type: .nsWindow(windowID: window.identifier.uuidString ?? UUID().uuidString)))
        
        window.titleDidChange = { [self] newTitle in
            DispatchQueue.main.async {
                self.title = newTitle ?? ""
            }
        }
    }
}



struct DraggableTitleBar: UIViewRepresentable {
    let title: String
    @Binding var offset: CGSize
    let isActive: Bool
    let onTitleBarTapped: () -> Void
    var window: NSWindow?
    var nativeWindow: AnyWindowRepresentable?
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemGray6
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let redCircle = createCircleView(color: .systemRed, sfSymbolName: "xmark", coordinator: context.coordinator)
        let yellowCircle = createCircleView(color: .systemYellow, sfSymbolName: "minus", coordinator: context.coordinator) {
            if let window, let firstIndex = WindowViewManager.shared.floatingWindows.firstIndex(where: { $0.window == window }) {
                print("wa")
                WindowViewManager.shared.floatingWindows[firstIndex].shown = false
            } else if let nativeWindow = nativeWindow?.base, nativeWindow is TerminalView {
                WindowViewManager.shared.nativeFloatingWindow[0].shown = false
                print("wo")
            } else if let nativeWindow, let firstIndex = WindowViewManager.shared.nativeFloatingWindow.firstIndex(where: { $0.window == nativeWindow }) {
                print("we")
                WindowViewManager.shared.nativeFloatingWindow[firstIndex].shown = false
            }
            
            print(nativeWindow)
            
        }
        let greenCircle = createCircleView(color: .systemGreen, sfSymbolName: "arrow.up.left.and.arrow.down.right", coordinator: context.coordinator)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.tag = 100 // Tag for easy retrieval
        
        stackView.addArrangedSubview(redCircle)
        stackView.addArrangedSubview(yellowCircle)
        stackView.addArrangedSubview(greenCircle)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(UIView()) // Spacer
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6),
            
            redCircle.widthAnchor.constraint(equalToConstant: 12),
            redCircle.heightAnchor.constraint(equalToConstant: 12),
            yellowCircle.widthAnchor.constraint(equalToConstant: 12),
            yellowCircle.heightAnchor.constraint(equalToConstant: 12),
            greenCircle.widthAnchor.constraint(equalToConstant: 12),
            greenCircle.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        
        containerView.addGestureRecognizer(panGesture)
        containerView.addGestureRecognizer(tapGesture)
        
        // Update visual state based on active status
        updateActiveState(containerView, isActive: isActive)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.offsetBinding = $offset
        context.coordinator.onTitleBarTapped = onTitleBarTapped
        
        // Update title label text
        if let stackView = uiView.subviews.first as? UIStackView,
           let titleLabel = stackView.arrangedSubviews.compactMap({ $0 as? UILabel }).first {
            titleLabel.text = title
        }
        
        // Update visual state based on active status
        updateActiveState(uiView, isActive: isActive)
    }
    
    private func updateActiveState(_ view: UIView, isActive: Bool) {
        UIView.animate(withDuration: 0.2) {
            view.backgroundColor = isActive ? UIColor.systemGray5 : UIColor.systemGray6
            view.alpha = isActive ? 1.0 : 0.9
        }
        
        // Update traffic light colors based on active state
        if let stackView = view.subviews.first as? UIStackView {
            let circles = stackView.arrangedSubviews.prefix(3)
            for (index, circle) in circles.enumerated() {
                UIView.animate(withDuration: 0.2) {
                    if isActive {
                        switch index {
                        case 0: circle.backgroundColor = .systemRed
                        case 1: circle.backgroundColor = .systemYellow
                        case 2: circle.backgroundColor = .systemGreen
                        default: break
                        }
                    } else {
                        circle.backgroundColor = .systemGray4
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(offsetBinding: $offset, onTitleBarTapped: onTitleBarTapped)
    }
    
    private func createCircleView(color: UIColor, sfSymbolName: String, coordinator: Coordinator, callback: (() -> Void)? = nil) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = color
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add action if callback provided
        if let callback = callback {
            let target = ClosureSleeve(callback)
            button.addTarget(target, action: #selector(ClosureSleeve.invoke), for: .touchUpInside)
            // Store the target to prevent deallocation
            objc_setAssociatedObject(button, "target", target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Create symbol image view for hover effect
        let symbolImageView = UIImageView()
        symbolImageView.image = UIImage(systemName: sfSymbolName)
        symbolImageView.tintColor = .black
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.alpha = 0
        symbolImageView.isUserInteractionEnabled = false
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(symbolImageView)
        
        NSLayoutConstraint.activate([
            symbolImageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            symbolImageView.widthAnchor.constraint(equalToConstant: 10),
            symbolImageView.heightAnchor.constraint(equalToConstant: 10),
            button.widthAnchor.constraint(equalToConstant: 12),
            button.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Add hover gesture
        let hover = UIHoverGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleHover(_:)))
        button.addGestureRecognizer(hover)
        
        button.accessibilityElements = [symbolImageView]
        
        return button
    }

    

    // Helper class to store closure for UIGestureRecognizer
    class ClosureSleeve: NSObject {
        let closure: () -> Void
        init (_ closure: @escaping () -> Void) { self.closure = closure }
        @objc func invoke() { closure() }
    }

    
    class Coordinator: NSObject {
        var offsetBinding: Binding<CGSize>
        var onTitleBarTapped: () -> Void
        private var initialOffset: CGSize = .zero
        
        init(offsetBinding: Binding<CGSize>, onTitleBarTapped: @escaping () -> Void) {
            self.offsetBinding = offsetBinding
            self.onTitleBarTapped = onTitleBarTapped
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .began:
                initialOffset = offsetBinding.wrappedValue
                onTitleBarTapped() // Bring to front when dragging starts
            case .changed:
                offsetBinding.wrappedValue = CGSize(
                    width: initialOffset.width + translation.x,
                    height: initialOffset.height + translation.y
                )
            default: break
            }
        }
        
        @objc func handleHover(_ gesture: UIHoverGestureRecognizer) {
            guard let circle = gesture.view,
                  let symbolImageView = circle.accessibilityElements?.first as? UIImageView else { return }

            switch gesture.state {
            case .began, .changed:
                symbolImageView.alpha = 1
            case .ended:
                symbolImageView.alpha = 0
            default: break
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            onTitleBarTapped()
        }
    }
}
