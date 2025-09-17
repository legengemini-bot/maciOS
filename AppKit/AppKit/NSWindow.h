//
//  NSWindow.h
//  AppKit-iOS
//
//  Created by Stossy11 on 28/08/2025.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSColor.h"
#import <Metal/Metal.h>
#import <MetalKit/MTKView.h>
#import "NSFont.h"
#import "NSApplication.h"
#import "NSResponder.h"
#import "NSImage.h"

@class NSWindow;
@class NSView;
@class NSViewController;
@class NSControl;
@class NSButton;
@class NSTextField;
@class NSEvent;

typedef NS_OPTIONS(NSUInteger, NSWindowStyleMask) {
    NSWindowStyleMaskBorderless = 0,
    NSWindowStyleMaskTitled = 1 << 0,
    NSWindowStyleMaskClosable = 1 << 1,
    NSWindowStyleMaskMiniaturizable = 1 << 2,
    NSWindowStyleMaskResizable = 1 << 3
};

typedef NS_ENUM(NSInteger, NSBackingStoreType) {
    NSBackingStoreRetained = 0,
    NSBackingStoreNonretained = 1,
    NSBackingStoreBuffered = 2
};

typedef NS_ENUM(NSInteger, NSButtonType) {
    NSButtonTypeMomentaryLight = 0,
    NSButtonTypePushOnPushOff = 1,
    NSButtonTypeToggle = 2,
    NSButtonTypeSwitch = 3,
    NSButtonTypeRadio = 4,
    NSButtonTypeMomentaryChange = 5,
    NSButtonTypeOnOff = 6,
    NSButtonTypeMomentaryPushIn = 7
};

typedef NS_ENUM(NSInteger, NSControlStateValue) {
    NSControlStateValueOff = 0,
    NSControlStateValueOn = 1,
    NSControlStateValueMixed = -1
};

typedef NS_ENUM(NSInteger, NSControlSize) {
    NSControlSizeRegular = 0,
    NSControlSizeSmall = 1,
    NSControlSizeMini = 2
};

typedef NS_ENUM(NSInteger, NSBezelStyle) {
    NSBezelStyleRounded = 1,
    NSBezelStyleRegularSquare = 2,
    NSBezelStyleThickSquare = 3,
    NSBezelStyleThickerSquare = 4,
    NSBezelStyleDisclosure = 5,
    NSBezelStyleShadowlessSquare = 6,
    NSBezelStyleCircular = 7,
    NSBezelStyleTexturedSquare = 8,
    NSBezelStyleHelpButton = 9,
    NSBezelStyleSmallSquare = 10,
    NSBezelStyleTexturedRounded = 11,
    NSBezelStyleRoundRect = 12,
    NSBezelStyleRecessed = 13,
    NSBezelStyleRoundedDisclosure = 14,
    NSBezelStyleInline = 15
};

typedef NS_ENUM(NSInteger, NSWindowOrderingMode) {
    NSWindowAbove = 1,
    NSWindowBelow = -1,
    NSWindowOut = 0
};

@protocol NSWindowDelegate <NSObject>
@optional
- (BOOL)windowShouldClose:(NSWindow*)sender;
- (void)windowWillClose:(NSNotification*)notification;
- (void)windowDidMiniaturize:(NSNotification*)notification;
@end

@interface NSWindowBridgeViewController : UIViewController
@property (nonatomic, weak) NSWindow *nsWindow;
@end


extern NSString * const NSWindowDidCreateNotification;

@interface NSWindow : NSResponder

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSWindowStyleMask styleMask;
@property (nonatomic, assign) CGFloat alphaValue;
@property (nonatomic, assign, getter=isOpaque) BOOL opaque;
@property (nonatomic, assign) CGFloat minWidth;
@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) CGFloat maxHeight;
@property (nonatomic, assign, getter=isVisible) BOOL visible;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) void (^titleDidChange)(NSString *newTitle);
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, weak) id<NSWindowDelegate> delegate;
@property (nonatomic, assign) BOOL resizable;
@property (nonatomic, assign) CGSize minSize;
@property (nonatomic, assign) CGSize maxSize;

@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, assign) NSBackingStoreType *backingStoreType;
@property (nonatomic, strong) NSViewController *contentViewController;
@property (nonatomic, strong, readonly) NSWindowBridgeViewController *bridgeViewController;

@property (nonatomic, strong, readonly) NSUUID *identifier;
@property (nonatomic, copy, readonly) NSString *applicationIdentifier;

- (instancetype)initWithContentRect:(CGRect)contentRect
                          styleMask:(NSWindowStyleMask)style
                            backing:(NSBackingStoreType)backingStoreType
                              defer:(BOOL)flag;

- (void)makeKeyAndVisible;
- (void)makeKeyWindow;
- (void)orderOut:(id)sender;
- (void)orderFront:(id)sender;
- (void)orderBack:(id)sender;
- (void)makeKeyAndOrderFront:(id)sender;

- (void)setFrame:(CGRect)frame display:(BOOL)displayFlag;
- (void)setFrame:(CGRect)frame display:(BOOL)displayFlag animate:(BOOL)animateFlag;
- (void)center;

- (void)miniaturize:(id)sender;
- (void)deminiaturize:(id)sender;
- (void)zoom:(id)sender;
- (void)close;

- (BOOL)canBecomeKeyWindow;
- (BOOL)canBecomeMainWindow;
- (void)becomeKeyWindow;
- (void)resignKeyWindow;
- (void)becomeMainWindow;
- (void)resignMainWindow;

- (void)setResizable:(BOOL)resizable;
- (void)setMinSize:(CGSize)minSize;
- (void)setMaxSize:(CGSize)maxSize;
- (CGRect)constrainFrameRect:(CGRect)frameRect toScreen:(UIScreen*)screen;

- (void)setupViewHierarchy;

@end

@interface NSView : NSResponder

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, strong, readonly) NSMutableArray<NSView*> *subviews;
@property (nonatomic, weak) NSView *superview;
@property (nonatomic, weak) NSWindow *window;
@property (nonatomic, assign) CGFloat alphaValue;
@property (nonatomic, assign) BOOL wantsLayer;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) CALayer *layer;
@property (nonatomic, assign) NSInteger tag;


@property (nonatomic, strong, readonly) UIView *uiView;

- (instancetype)initWithFrame:(CGRect)frameRect;

- (void)addSubview:(NSView*)view;
- (void)addSubview:(NSView*)view positioned:(NSWindowOrderingMode)place relativeTo:(NSView*)otherView;
- (void)removeFromSuperview;

- (void)setNeedsDisplay:(BOOL)needsDisplay;
- (void)drawRect:(CGRect)dirtyRect;

- (NSView*)hitTest:(CGPoint)point;
- (BOOL)isDescendantOf:(NSView*)view;

- (void)setNeedsLayout;
- (void)layoutSubviews;

- (NSView*)viewWithTag:(NSInteger)tag;

- (void)updateSubviewWindowReferences;
- (CGRect)convertRectToUIKit:(CGRect)nsRect;
- (CGPoint)convertPoint:(CGPoint)point fromView:(NSView*)view;

@end

@interface NSViewController : NSResponder

@property (nonatomic, strong) NSView *view;
@property (nonatomic, copy, readonly) NSString *nibName;
@property (nonatomic, strong, readonly) NSBundle *nibBundle;
@property (nonatomic, weak) NSViewController *parentViewController;
@property (nonatomic, strong, readonly) NSMutableArray<NSViewController*> *childViewControllers;

@property (nonatomic, assign) CGSize preferredContentSize;

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;
- (instancetype)init;

- (void)loadView;
- (void)viewDidLoad;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;

- (void)addChildViewController:(NSViewController*)childController;
- (void)removeFromParentViewController;

@end

@interface NSControl : NSView

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, assign) NSControlSize controlSize;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;


@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, assign) NSInteger integerValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) float floatValue;

- (void)sendAction:(SEL)action to:(id)target;
- (BOOL)sendAction:(SEL)action to:(id)target forEvent:(NSEvent*)event;

- (void)takeStringValueFrom:(id)sender;
- (void)takeIntValueFrom:(id)sender;
- (void)takeDoubleValueFrom:(id)sender;
- (void)takeFloatValueFrom:(id)sender;

@end

@interface NSButton : NSControl

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) NSButtonType buttonType;
@property (nonatomic, assign) NSBezelStyle bezelStyle;
@property (nonatomic, assign, getter=isBordered) BOOL bordered;
@property (nonatomic, assign) NSControlStateValue state;


@property (nonatomic, strong, readonly) UIButton *button;

+ (instancetype)buttonWithTitle:(NSString*)title target:(id)target action:(SEL)action;
+ (instancetype)checkboxWithTitle:(NSString*)title target:(id)target action:(SEL)action;
+ (instancetype)radioButtonWithTitle:(NSString*)title target:(id)target action:(SEL)action;

- (void)setButtonType:(NSButtonType)type;
- (void)highlight:(BOOL)flag;
- (void)performClick:(id)sender;


- (void)buttonPressed:(UIButton*)sender;

@end

@interface NSTextField : NSControl <UITextViewDelegate, UITextFieldDelegate>

@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, copy) NSString *placeholderString;

@property (nonatomic, assign, getter=isEditable) BOOL editable;
@property (nonatomic, assign, getter=isSelectable) BOOL selectable;
@property (nonatomic, assign, getter=isBordered) BOOL bordered;
@property (nonatomic, assign, getter=isBezeled) BOOL bezeled;
@property (nonatomic, assign) NSTextAlignment alignment;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, assign) BOOL drawsBackground;
@property (nonatomic, assign) UIViewAutoresizing autoresizingMask;
@property (nonatomic, strong) NSFont *font;

+ (instancetype)labelWithString:(NSString *)stringValue;
+ (instancetype)textFieldWithString:(NSString *)stringValue;

- (void)selectAll:(id)sender;

@end

@interface NSImageView : NSView

@property (nonatomic, strong) NSImage *image;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, assign) BOOL animatesContents;

@property (nonatomic, strong, readonly) UIImageView *imageView;

+ (instancetype)imageViewWithImage:(NSImage*)image;

- (void)setImage:(NSImage*)image animated:(BOOL)animated;

@end

int NSApplicationMain(int argc, const char *argv[]);
