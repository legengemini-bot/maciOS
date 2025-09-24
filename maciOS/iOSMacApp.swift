//
//  maciOSApp.swift
//  maciOS
//
//  Created by Stossy11 on 22/08/2025.
//

import SwiftUI
import CoreGraphics
import Combine
import UIKit

@main
struct maciOSApp: App {
    @StateObject private var mouse = MouseTracker.shared
    @State var cursor = UIImage()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .padding(.top)
                .overlay {
                    
                    if mouse.shown {
                        GeometryReader { geo in
                            ZStack {
                                Image(uiImage: cursor)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .position(
                                        x: mouse.location.x - geo.frame(in: .global).minX,
                                        y: mouse.location.y - geo.frame(in: .global).minY
                                    )
                                    .offset(x: 15, y: 15)
                            }
                        }
                    }
                }
                .onAppear {
                    setenv("LC_HOME_PATH", getenv("HOME"), 1)
                    init_bypassDyldLibValidation()
                    
                    let binURL = URL.documentsDirectory.appendingPathComponent("bin")
                    try? FileManager.default.createDirectory(at: binURL, withIntermediateDirectories: false)
                }
                .onAppear {
                    if let window = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows.first {
                        MouseTracker.shared.attach(to: window)
                    }

                    let cursorImage = UIImage(named: "Normal") ?? UIImage()
                    cursor = cursorImage

                    // show overlay window
                    CursorWindow.shared.makeKeyAndVisible()
                    
                    // hook mouse updates
                    MouseTracker.shared.onMove = { point in
                        CursorWindow.shared.updateCursor(image: cursorImage, at: point)
                    }
                    
                    NSWindowController.description()
                }
                .onOpenURL { url in
                    let patcher = MachOPatcher(url)
                    machO.append(patcher)
                    install_exit_hook()
                    if let exeURL = patcher.patchExecutable() {
                        Execute.run(dylibPath: exeURL.path)
                    }
                }
        }
    }
}

class CursorWindow: UIWindow {
    static let shared = CursorWindow()

    private let cursorView = UIImageView()

    private init() {
        super.init(frame: UIScreen.main.bounds)
        windowLevel = .alert + 1   // ensures it's above alerts
        backgroundColor = .clear
        isHidden = false
        isUserInteractionEnabled = false

        cursorView.contentMode = .scaleAspectFit
        cursorView.frame.size = CGSize(width: 30, height: 30)
        addSubview(cursorView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCursor(image: UIImage, at point: CGPoint) {
        cursorView.image = image
        cursorView.center = point
    }
}


class MouseTracker: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    static let shared = MouseTracker()
    let coordinator = Coordinator()
    
    @Published var shown = false
    @Published var location: CGPoint = .zero
    @Published var onMove: (CGPoint) -> Void = { _ in }
    
    private var lastLocation: CGPoint = .zero
    
    func attach(to window: UIWindow) {
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleMouse(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleMouse(_:)))
        pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        let pointerInteraction = UIPointerInteraction(delegate: coordinator)
        
        hover.delegate = self
        pan.delegate = self
        
        window.addGestureRecognizer(hover)
        window.addGestureRecognizer(pan)
        window.addInteraction(pointerInteraction)
    }
    
    @objc private func handleMouse(_ gesture: UIGestureRecognizer) {
        guard let view = gesture.view else { return }
        let loc = gesture.location(in: view)
        
        if let gesture = gesture as? UIHoverGestureRecognizer {
            shown = gesture.state != .cancelled
        }
        
        onMove(loc)
        
        self.location = loc
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    class Coordinator: NSObject, UIPointerInteractionDelegate {
        func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
            return UIPointerStyle.hidden()
        }
    }
}

struct NonRetinaScalingModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let bounds = geometry.size
            let native = UIScreen.main.nativeBounds.size
            let nativeScale = UIScreen.main.nativeScale
            
            let targetWidthPoints = native.width / nativeScale
            let targetHeightPoints = native.height / nativeScale
            
            let scaleFactor = min(bounds.width / targetWidthPoints,
                                  bounds.height / targetHeightPoints)
            
            content
                .frame(width: targetWidthPoints, height: targetHeightPoints)
                .scaleEffect(scaleFactor)
                .position(x: bounds.width / 2, y: bounds.height / 2) // center
        }
        
    }
}


func mach_task_self() -> mach_port_t {
    return mach_task_self_
}


