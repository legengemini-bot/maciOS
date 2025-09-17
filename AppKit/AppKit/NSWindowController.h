//
//  NSWindowController.h
//  AppKit-iOS
//
//  Created by Stossy11 on 14/09/2025.
//

#import <Foundation/Foundation.h>
#import "NSResponder.h"

@class NSWindow;
@class NSViewController;
@class NSDocument;

NS_ASSUME_NONNULL_BEGIN

@interface NSWindowController : NSResponder

@property (nonatomic, strong, nullable) NSWindow *window;
@property (nonatomic, strong, nullable) NSDocument *document;
@property (nonatomic, copy, readonly, nullable) NSString *windowNibName;
@property (nonatomic, strong, readonly, nullable) NSBundle *windowNibBundle;
@property (nonatomic, weak, nullable) id owner;
@property (nonatomic, copy, nullable) NSString *windowFrameAutosaveName;
@property (nonatomic, assign) BOOL shouldCascadeWindows;
@property (nonatomic, assign) BOOL shouldCloseDocument;

// Initialization
- (instancetype)init;
- (instancetype)initWithWindow:(nullable NSWindow *)window;
- (instancetype)initWithWindowNibName:(NSString *)windowNibName;
- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner;
- (instancetype)initWithWindowNibName:(NSString *)windowNibName bundle:(nullable NSBundle *)bundle;

// Window management
- (void)loadWindow;
- (void)windowDidLoad;
- (void)windowWillLoad;

// Window lifecycle
- (void)showWindow:(nullable id)sender;
- (void)close;

// Window controller hierarchy
- (IBAction)performClose:(nullable id)sender;

// Cascading
- (CGPoint)cascadeTopLeftFromPoint:(CGPoint)topLeftPoint;

// Document association
- (void)setDocument:(nullable NSDocument *)document;
- (void)setDocumentEdited:(BOOL)dirtyFlag;

// Convenience methods
- (nullable NSViewController *)contentViewController;
- (void)setContentViewController:(nullable NSViewController *)contentViewController;

@end

NS_ASSUME_NONNULL_END
