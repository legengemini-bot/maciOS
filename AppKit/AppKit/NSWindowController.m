//
//  NSWindowController.m
//  AppKit-iOS
//
//  Created by Stossy11 on 14/09/2025.
//

#import "NSWindowController.h"
#import "NSWindow.h"

@interface NSWindowController ()
@property (nonatomic, copy, readwrite, nullable) NSString *windowNibName;
@property (nonatomic, strong, readwrite, nullable) NSBundle *windowNibBundle;
@property (nonatomic, assign) BOOL windowLoaded;
@end


@implementation NSWindowController

@synthesize window = _window;
@synthesize document = _document;
@synthesize windowNibName = _windowNibName;
@synthesize windowNibBundle = _windowNibBundle;
@synthesize owner = _owner;
@synthesize windowFrameAutosaveName = _windowFrameAutosaveName;
@synthesize shouldCascadeWindows = _shouldCascadeWindows;
@synthesize shouldCloseDocument = _shouldCloseDocument;
@synthesize windowLoaded = _windowLoaded;

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super init];
    if (self) {
        [self commonInit];
        _window = window;
        _windowLoaded = (window != nil);
    }
    return self;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    return [self initWithWindowNibName:windowNibName owner:self];
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
    return [self initWithWindowNibName:windowNibName bundle:[NSBundle mainBundle] owner:owner];
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName bundle:(NSBundle *)bundle {
    return [self initWithWindowNibName:windowNibName bundle:bundle owner:self];
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName bundle:(NSBundle *)bundle owner:(id)owner {
    self = [super init];
    if (self) {
        [self commonInit];
        _windowNibName = [windowNibName copy];
        _windowNibBundle = bundle ?: [NSBundle mainBundle];
        _owner = owner;
    }
    return self;
}

- (void)commonInit {
    _shouldCascadeWindows = YES;
    _shouldCloseDocument = NO;
    _windowLoaded = NO;
}

#pragma mark - Window Loading

- (void)loadWindow {
    if (_windowLoaded || _window) {
        return;
    }
    
    [self windowWillLoad];
    
    if (_windowNibName && _windowNibBundle) {
        // In a real implementation, this would load from a nib file
        // For now, we'll create a default window
        NSLog(@"NSWindowController: Loading window from nib '%@' in bundle %@", _windowNibName, _windowNibBundle);
        
        // Create a default window since we don't have nib loading
        CGRect defaultFrame = CGRectMake(100, 100, 800, 600);
        _window = [[NSWindow alloc] initWithContentRect:defaultFrame
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
        _window.title = _windowNibName ?: @"Window";
    }
    
    if (!_window) {
        // Create a minimal default window
        CGRect defaultFrame = CGRectMake(100, 100, 800, 600);
        _window = [[NSWindow alloc] initWithContentRect:defaultFrame
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
        _window.title = @"Window";
    }
    
    _windowLoaded = YES;
    [self windowDidLoad];
}

- (void)windowWillLoad {
    // Subclasses can override this method to perform setup before the window is loaded
    NSLog(@"NSWindowController: windowWillLoad");
}

- (void)windowDidLoad {
    // Subclasses can override this method to perform setup after the window is loaded
    NSLog(@"NSWindowController: windowDidLoad for window: %@", _window);
    
    // Apply window frame autosave name if set
    if (_windowFrameAutosaveName && _windowFrameAutosaveName.length > 0) {
        [self restoreWindowFrame];
    }
}

#pragma mark - Window Management

- (void)showWindow:(id)sender {
    if (!_window) {
        [self loadWindow];
    }
    
    if (_shouldCascadeWindows) {
        CGPoint cascadePoint = [self cascadeTopLeftFromPoint:CGPointMake(100, 100)];
        CGRect frame = _window.frame;
        frame.origin = cascadePoint;
        _window.frame = frame;
    }
    
    [_window makeKeyAndOrderFront:sender];
    
    // Add to application's window list if not already there
    NSApplication *app = [NSApplication sharedApplication];
    if (![app.windows containsObject:_window]) {
        [app addWindow:_window];
    }
}


- (void)close {
    if (_window) {
        if (_windowFrameAutosaveName && _windowFrameAutosaveName.length > 0) {
            [self saveWindowFrame];
        }
        
        [_window close];
        
        // Remove from application's window list
        NSApplication *app = [NSApplication sharedApplication];
        [app removeWindow:_window];
    }
}

- (IBAction)performClose:(id)sender {
    [self close];
}

#pragma mark - Window Cascading

- (CGPoint)cascadeTopLeftFromPoint:(CGPoint)topLeftPoint {
    // Simple cascading implementation - offset by 20 points each time
    static NSInteger cascadeOffset = 0;
    cascadeOffset = (cascadeOffset + 20) % 200; // Reset after 200 pixels
    
    CGPoint cascadePoint = topLeftPoint;
    cascadePoint.x += cascadeOffset;
    cascadePoint.y += cascadeOffset;
    
    return cascadePoint;
}


#pragma mark - Document Association

- (void)setDocument:(NSDocument *)document {
    if (_document != document) {
        _document = document;
        
        // Update window title to reflect document
        if (_window && document) {
            // In a real implementation, this would use the document's display name
            _window.title = @"Document Window";
        }
    }
}

- (void)setDocumentEdited:(BOOL)dirtyFlag {
    // In macOS, this would show a dot in the close button
    // For iOS, we might update the window title or show some other indicator
    if (_window) {
        NSString *title = _window.title;
        if (dirtyFlag && ![title hasPrefix:@"• "]) {
            _window.title = [NSString stringWithFormat:@"• %@", title];
        } else if (!dirtyFlag && [title hasPrefix:@"• "]) {
            _window.title = [title substringFromIndex:2];
        }
    }
}

#pragma mark - Content View Controller

- (NSViewController *)contentViewController {
    return _window.contentViewController;
}

- (void)setContentViewController:(NSViewController *)contentViewController {
    if (!_window) {
        [self loadWindow];
    }
    _window.contentViewController = contentViewController;
}

#pragma mark - Window Frame Autosave

- (void)setWindowFrameAutosaveName:(NSString *)windowFrameAutosaveName {
    _windowFrameAutosaveName = [windowFrameAutosaveName copy];
}

- (void)saveWindowFrame {
    if (!_windowFrameAutosaveName || !_window) {
        return;
    }
    
    // Save the window frame to user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *frameString = NSStringFromCGRect(_window.frame);
    [defaults setObject:frameString forKey:_windowFrameAutosaveName];
    [defaults synchronize];
}

- (void)restoreWindowFrame {
    if (!_windowFrameAutosaveName || !_window) {
        return;
    }
    
    // Restore the window frame from user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *frameString = [defaults objectForKey:_windowFrameAutosaveName];
    if (frameString) {
        CGRect frame = CGRectFromString(frameString);
        if (!CGRectIsEmpty(frame)) {
            _window.frame = frame;
        }
    }
}

#pragma mark - Cleanup

- (void)dealloc {
    if (_windowFrameAutosaveName && _window) {
        [self saveWindowFrame];
    }
}

@end
