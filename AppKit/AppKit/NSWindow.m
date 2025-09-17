//
//  NSWindow.m
//  AppKit-iOS
//
//  Created by Stossy11 on 28/08/2025.
//

#import "NSWindow.h"
#import "NSImage.h"

@implementation NSWindowBridgeViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    self.view.backgroundColor = [UIColor systemBackgroundColor];

    NSLog(@"Bridge viewDidLoad: bridge view frame=%@", NSStringFromCGRect(self.view.frame));

    if (self.nsWindow.contentViewController) {
        if ([self.nsWindow.contentViewController respondsToSelector:@selector(viewDidLoad)]) {
            [self.nsWindow.contentViewController viewDidLoad];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSLog(@"Bridge viewWillAppear: bridge frame=%@, window frame=%@",
          NSStringFromCGRect(self.view.bounds),
          NSStringFromCGRect(self.nsWindow.frame));

    // Clear existing subviews
    for (UIView *subview in self.view.subviews) {
        [subview removeFromSuperview];
    }

    if (self.nsWindow.contentViewController) {
        if ([self.nsWindow.contentViewController respondsToSelector:@selector(viewWillAppear)]) {
            [self.nsWindow.contentViewController viewWillAppear];
        }

        NSView *controllerView = self.nsWindow.contentViewController.view;
        if (controllerView) {
            // Set the NSView frame to match window bounds (not window frame)
            controllerView.frame = CGRectMake(0, 0, self.nsWindow.frame.size.width, self.nsWindow.frame.size.height);

            [self.view addSubview:controllerView.uiView];

            // Use bounds for content frame, not window frame
            CGRect contentFrame = CGRectMake(0, 0, self.nsWindow.frame.size.width, self.nsWindow.frame.size.height);
            controllerView.uiView.frame = contentFrame;
            controllerView.uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            NSLog(@"Bridge: Added controller view with frame=%@", NSStringFromCGRect(controllerView.uiView.frame));
        }
    } else if (self.nsWindow.contentView) {
        [self.view addSubview:self.nsWindow.contentView.uiView];

        // Use bounds for content frame
        CGRect contentFrame = CGRectMake(0, 0, self.nsWindow.frame.size.width, self.nsWindow.frame.size.height);
        self.nsWindow.contentView.uiView.frame = contentFrame;
        self.nsWindow.contentView.uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        NSLog(@"Bridge: Added content view with frame=%@", NSStringFromCGRect(self.nsWindow.contentView.uiView.frame));
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.nsWindow.contentViewController) {
        if ([self.nsWindow.contentViewController respondsToSelector:@selector(viewDidAppear)]) {
            [self.nsWindow.contentViewController viewDidAppear];
        }
    }
    [self becomeFirstResponder];

    NSLog(@"Bridge viewDidAppear: Final setup complete");
}

@end

@implementation NSImageView

+ (instancetype)imageViewWithImage:(NSImage*)image {
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:CGRectZero];
    imageView.image = image;
    return imageView;
}

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        if ([NSThread isMainThread]) {
            [self createImageViewUI:frameRect];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self createImageViewUI:frameRect];
            });
        }
        _contentMode = UIViewContentModeScaleAspectFit;
        _animatesContents = NO;
    }
    return self;
}

- (void)createImageViewUI:(CGRect)frameRect {
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.userInteractionEnabled = YES;
    [self.uiView addSubview:_imageView];
}

- (void)setImage:(NSImage *)image {
    _image = image;
    UIImage *uiImage = image.uiImage;



    if ([NSThread isMainThread]) {
        self.imageView.image = uiImage;

        [self.imageView setNeedsDisplay];
        [self.imageView setNeedsLayout];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.imageView.image = uiImage;
            [self.imageView setNeedsDisplay];
            [self.imageView setNeedsLayout];
        });
    }
}

- (void)setImage:(NSImage*)image animated:(BOOL)animated {
    _image = image;
    UIImage *uiImage = image.uiImage;
    if (animated) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView transitionWithView:self.imageView
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.imageView.image = uiImage;
                            }
                            completion:nil];
        });
    } else {
        [self setImage:image];
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    _contentMode = contentMode;
    if ([NSThread isMainThread]) {
        self.imageView.contentMode = contentMode;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.contentMode = contentMode;
        });
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (_imageView) {
        _imageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }
}

@end

@interface NSTextField ()
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UITextField *singleLineField;

@end

@implementation NSTextField

@synthesize stringValue = _stringValue;
@synthesize autoresizingMask = _autoresizingMask;
@synthesize font = _font;

+ (instancetype)labelWithString:(NSString *)stringValue {
    NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    field.stringValue = stringValue ?: @"";
    field.editable = NO;
    field.selectable = NO;
    field.bordered = NO;
    field.bezeled = NO;
    field.drawsBackground = NO;
    field.textColor = [NSColor labelColor];
    return field;
}

+ (instancetype)textFieldWithString:(NSString *)stringValue {
    NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectZero];
    field.stringValue = stringValue ?: @"";
    return field;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _editable = YES;
        _selectable = YES;
        _bordered = YES;
        _bezeled = YES;
        _drawsBackground = YES;
        _alignment = NSTextAlignmentLeft;
        _placeholderString = @"";
        _stringValue = @"";
        _autoresizingMask = UIViewAutoresizingNone;
        _font = [NSFont systemFontOfSize:17];

        _contentView = [[NSView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _contentView.uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentView.uiView.backgroundColor = [UIColor clearColor];
        [self addSubview:_contentView];

        [self rebuildContentView];
    }
    return self;
}


- (void)rebuildContentView {

    for (NSView *subview in [self.contentView.subviews copy]) {
        [subview removeFromSuperview];
    }
    self.labelView = nil;
    self.textView = nil;
    self.singleLineField = nil;


    NSView *wrapperView = [[NSView alloc] initWithFrame:self.contentView.bounds];
    wrapperView.uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:wrapperView];

    UIFont *uiFont = (UIFont *)self.font ?: [UIFont systemFontOfSize:17];

    if (self.editable) {

        UITextView *tv = [[UITextView alloc] initWithFrame:wrapperView.bounds];
        tv.autoresizingMask = self.autoresizingMask;
        tv.delegate = self;
        tv.scrollEnabled = NO;
        tv.text = self.stringValue;
        tv.textAlignment = self.alignment;
        tv.font = uiFont;
        if (self.textColor) {
            tv.textColor = self.textColor.uiColor;
        }
        [wrapperView.uiView addSubview:tv];
        self.textView = tv;
    }
    else if (self.selectable) {

        UITextView *tv = [[UITextView alloc] initWithFrame:wrapperView.bounds];
        tv.autoresizingMask = self.autoresizingMask;
        tv.editable = NO;
        tv.scrollEnabled = NO;
        tv.selectable = YES;
        tv.text = self.stringValue;
        tv.textAlignment = self.alignment;
        tv.font = uiFont;
        if (self.textColor) {
            tv.textColor = self.textColor.uiColor;
        }
        [wrapperView.uiView addSubview:tv];
        self.textView = tv;
    }
    else {

        UILabel *lbl = [[UILabel alloc] initWithFrame:wrapperView.bounds];
        lbl.autoresizingMask = self.autoresizingMask;
        lbl.numberOfLines = 0;
        lbl.lineBreakMode = NSLineBreakByWordWrapping;
        lbl.text = self.stringValue;
        lbl.textAlignment = self.alignment;
        lbl.font = uiFont;
        if (self.textColor) {
            lbl.textColor = self.textColor.uiColor;
        }
        [wrapperView.uiView addSubview:lbl];
        self.labelView = lbl;
    }
}


- (void)setEditable:(BOOL)editable {
    if (_editable != editable) {
        _editable = editable;
        [self rebuildContentView];
    }
}

- (void)setSelectable:(BOOL)selectable {
    if (_selectable != selectable) {
        _selectable = selectable;
        [self rebuildContentView];
    }
}

- (void)setFont:(NSFont *)font {
    _font = font ?: [NSFont systemFontOfSize:17];


    UIFont *uiFont = (UIFont *)_font;
    if (self.textView) {
        self.textView.font = uiFont;
    }
    if (self.labelView) {
        self.labelView.font = uiFont;
    }
    if (self.singleLineField) {
        self.singleLineField.font = uiFont;
    }
}

- (void)setStringValue:(NSString *)stringValue {
    NSString *oldValue = _stringValue;
    _stringValue = [stringValue copy] ?: @"";

    NSLog(@"NSTextField setStringValue: '%@' (length=%lu)",
          [_stringValue substringToIndex:MIN(50, _stringValue.length)],
          (unsigned long)_stringValue.length);


    BOOL oldHasNewlines = [oldValue containsString:@"\n"];
    BOOL newHasNewlines = [_stringValue containsString:@"\n"];
    BOOL needsRebuild = (oldHasNewlines != newHasNewlines) && !self.editable && !self.selectable;

    if (needsRebuild) {
        [self rebuildContentView];
    } else {

        if (self.textView) {
            self.textView.text = _stringValue;
            NSLog(@"Updated UITextView with text length=%lu", (unsigned long)self.textView.text.length);
        }
        if (self.labelView) {
            self.labelView.text = _stringValue;
            NSLog(@"Updated UILabel with text length=%lu", (unsigned long)self.labelView.text.length);
        }
        if (self.singleLineField) {
            self.singleLineField.text = _stringValue;
            NSLog(@"Updated UITextField with text length=%lu", (unsigned long)self.singleLineField.text.length);
        }
    }
}
- (NSString *)stringValue {
    if (self.textView) return self.textView.text ?: @"";
    if (self.labelView) return self.labelView.text ?: @"";
    if (self.singleLineField) return self.singleLineField.text ?: @"";
    return _stringValue ?: @"";
}

- (void)setPlaceholderString:(NSString *)placeholderString {
    _placeholderString = [placeholderString copy] ?: @"";
    if (self.singleLineField) {
        self.singleLineField.placeholder = _placeholderString;
    }

}

- (void)setAlignment:(NSTextAlignment)alignment {
    _alignment = alignment;
    if (self.textView) self.textView.textAlignment = alignment;
    if (self.labelView) self.labelView.textAlignment = alignment;
    if (self.singleLineField) self.singleLineField.textAlignment = alignment;
}

- (void)setTextColor:(NSColor *)textColor {
    _textColor = textColor;
    UIColor *ui = textColor ? textColor.uiColor : ([UIColor labelColor]);
    if (self.textView) self.textView.textColor = ui;
    if (self.labelView) self.labelView.textColor = ui;
    if (self.singleLineField) self.singleLineField.textColor = ui;
}

- (void)setDrawsBackground:(BOOL)drawsBackground {
    _drawsBackground = drawsBackground;
    UIColor *bg = drawsBackground ? [UIColor systemBackgroundColor] : [UIColor clearColor];
    if (self.textView) self.textView.backgroundColor = bg;
    if (self.labelView) self.labelView.backgroundColor = bg;
    if (self.singleLineField) self.singleLineField.backgroundColor = bg;
}

- (void)setAutoresizingMask:(UIViewAutoresizing)autoresizingMask {
    _autoresizingMask = autoresizingMask;

    if (self.textView) {
        self.textView.autoresizingMask = autoresizingMask;
    } else if (self.labelView) {
        self.labelView.autoresizingMask = autoresizingMask;
    } else if (self.singleLineField) {
        self.singleLineField.autoresizingMask = autoresizingMask;
    }
}

- (UIViewAutoresizing)autoresizingMask {
    return _autoresizingMask;
}


- (void)selectAll:(id)sender {
    if (self.textView) {
        [self.textView selectAll:sender];
    } else if (self.singleLineField) {
        [self.singleLineField selectAll:sender];
    }
}


- (void)textViewDidChange:(UITextView *)textView {
    _stringValue = textView.text;

}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _stringValue = textField.text;

}

@end

@implementation NSView

@synthesize frame = _frame;
@synthesize bounds = _bounds;
@synthesize subviews = _subviews;
@synthesize superview = _superview;
@synthesize window = _window;
@synthesize alphaValue = _alphaValue;
@synthesize wantsLayer = _wantsLayer;
@synthesize hidden = _hidden;
@synthesize backgroundColor = _backgroundColor;
@synthesize layer = _layer;
@synthesize uiView = _uiView;
@synthesize tag = _tag;

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super init];
    if (self) {
        _frame = frameRect;
        _bounds = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
        _subviews = [NSMutableArray array];


        if ([NSThread isMainThread]) {
            _uiView = [[UIView alloc] initWithFrame:frameRect];
            _uiView.backgroundColor = [UIColor clearColor];

            _uiView.clipsToBounds = NO;
            _alphaValue = 1.0;
            _wantsLayer = NO;
            _hidden = NO;
            _tag = 0;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self->_uiView = [[UIView alloc] initWithFrame:frameRect];
                _uiView.backgroundColor = [UIColor clearColor];

                _uiView.clipsToBounds = NO;
                _alphaValue = 1.0;
                _wantsLayer = NO;
                _hidden = NO;
                _tag = 0;
            });
        }


    }
    return self;
}

- (void)addSubview:(NSView*)view {
    if (!view) return;

    NSView *wrappedView = nil;
    
    if ([view isKindOfClass:[NSView class]]) {
        wrappedView = (NSView *)view;
    }
    else if ([view isKindOfClass:[UIView class]]) {
        UIView *uiView = (UIView *)view;
        NSView *contentView = [[NSView alloc] initWithFrame:self.uiView.bounds];
        NSView *wrapperView = [[NSView alloc] initWithFrame:contentView.bounds];
        wrapperView.uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [contentView addSubview:wrapperView];
        [wrapperView.uiView addSubview:uiView];
        uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        wrappedView = contentView;
    } else {
        return;
    }

    [_subviews addObject:wrappedView];
    wrappedView.superview = self;
    wrappedView.window = self.window;
    
    CGRect uiKitFrame = [wrappedView convertRectToUIKit:wrappedView.frame];
    wrappedView.uiView.frame = uiKitFrame;
    
    [self.uiView addSubview:wrappedView.uiView];
    
    [wrappedView updateSubviewWindowReferences];
}
- (void)syncCoordinateSystems {
    if (self.superview) {
        CGRect convertedFrame = [self convertRectToUIKit:self.frame];
        self.uiView.frame = convertedFrame;
    }
    
    for (NSView *subview in self.subviews) {
        [subview syncCoordinateSystems];
    }
}

- (void)addSubview:(NSView*)view positioned:(NSWindowOrderingMode)place relativeTo:(NSView*)otherView {
    if (!view) return;
    
    NSUInteger index = otherView ? [_subviews indexOfObject:otherView] : NSNotFound;
    if (place == NSWindowAbove && index != NSNotFound) {
        [_subviews insertObject:view atIndex:index + 1];
    } else if (place == NSWindowBelow && index != NSNotFound) {
        [_subviews insertObject:view atIndex:index];
    } else {
        [_subviews addObject:view];
    }
    
    view.superview = self;
    view.window = self.window;
    
    [self.uiView addSubview:view.uiView];
    
    view.uiView.frame = view.frame;
    
    if (place == NSWindowAbove && otherView) {
        [self.uiView bringSubviewToFront:view.uiView];
    } else if (place == NSWindowBelow && otherView) {
        [self.uiView sendSubviewToBack:view.uiView];
    }
    
    [view updateSubviewWindowReferences];
}

- (void)removeFromSuperview {
    if (self.superview) {
        [self.superview.subviews removeObject:self];
        [self.uiView removeFromSuperview];
        self.superview = nil;
        self.window = nil;
        [self updateSubviewWindowReferences];
    }
}

- (void)setNeedsDisplay:(BOOL)needsDisplay {
    [self.uiView setNeedsDisplay];
}

- (void)drawRect:(CGRect)dirtyRect {

}

- (NSView*)hitTest:(CGPoint)point {
    if (self.hidden || self.alphaValue == 0 || !CGRectContainsPoint(self.bounds, point)) {
        return nil;
    }
    for (NSView *subview in [self.subviews reverseObjectEnumerator]) {
        NSView *hitView = [subview hitTest:[subview convertPoint:point fromView:self]];
        if (hitView) {
            return hitView;
        }
    }
    return self;
}

- (BOOL)isDescendantOf:(NSView*)view {
    NSView *currentView = self;
    while (currentView) {
        if (currentView == view) {
            return YES;
        }
        currentView = currentView.superview;
    }
    return NO;
}

- (void)setNeedsLayout {
    [self.uiView setNeedsLayout];
}

- (void)layoutSubviews {
    [self.uiView layoutIfNeeded];
}

- (NSView*)viewWithTag:(NSInteger)tag {
    if (self.tag == tag) {
        return self;
    }
    for (NSView *subview in self.subviews) {
        NSView *foundView = [subview viewWithTag:tag];
        if (foundView) {
            return foundView;
        }
    }
    return nil;
}

- (void)updateSubviewWindowReferences {
    for (NSView *subview in self.subviews) {
        subview.window = self.window;
        [subview updateSubviewWindowReferences];
    }
}

- (CGRect)convertRectToUIKit:(CGRect)nsRect {
    CGRect converted = nsRect;
    if (self.superview) {
        converted.origin.y = self.superview.bounds.size.height - nsRect.origin.y - nsRect.size.height;
    } else if (self.window) {
        converted.origin.y = self.window.frame.size.height - nsRect.origin.y - nsRect.size.height;
    }
    return converted;
}

- (CGPoint)convertPointToUIKit:(CGPoint)nsPoint {
    CGPoint converted = nsPoint;
    if (self.superview) {
        converted.y = self.superview.bounds.size.height - nsPoint.y;
    } else if (self.window) {
        converted.y = self.window.frame.size.height - nsPoint.y;
    }
    return converted;
}

- (CGPoint)convertPoint:(CGPoint)point fromView:(NSView*)view {
    if (!view) {
        return [self.uiView convertPoint:point fromView:nil];
    }
    return [self.uiView convertPoint:point fromView:view.uiView];
}

- (void)setFrame:(CGRect)frame {
    _frame = frame;
    _bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
    
    CGRect uiKitFrame = [self convertRectToUIKit:frame];
    self.uiView.frame = uiKitFrame;
    
    for (NSView *subview in _subviews) {
        CGRect subviewUIKitFrame = [subview convertRectToUIKit:subview.frame];
        subview.uiView.frame = subviewUIKitFrame;
    }
}



- (void)setBounds:(CGRect)bounds {
    _bounds = bounds;
    self.uiView.bounds = [self convertRectToUIKit:bounds];
}

- (void)setAlphaValue:(CGFloat)alphaValue {
    _alphaValue = alphaValue;
    self.uiView.alpha = alphaValue;
}

- (void)setHidden:(BOOL)hidden {
    _hidden = hidden;
    self.uiView.hidden = hidden;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.uiView.backgroundColor = backgroundColor.uiColor ?: [UIColor clearColor];
}

- (void)setWantsLayer:(BOOL)wantsLayer {
    _wantsLayer = wantsLayer;
    if (wantsLayer && !self.layer) {
        self.layer = [CALayer layer];
        self.uiView.layer.backgroundColor = self.backgroundColor.uiColor.CGColor;
        [self.uiView.layer addSublayer:self.layer];
    }
}

- (void)setTag:(NSInteger)tag {
    _tag = tag;
    self.uiView.tag = tag;
}

@end

@implementation NSViewController

@synthesize view = _view;
@synthesize nibName = _nibName;
@synthesize nibBundle = _nibBundle;
@synthesize parentViewController = _parentViewController;
@synthesize childViewControllers = _childViewControllers;

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super init];
    if (self) {
        _nibName = [nibNameOrNil copy];
        _nibBundle = nibBundleOrNil;
        _childViewControllers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    return [self initWithNibName:nil bundle:nil];
}

- (void)loadView {
    if (!self.view) {
        self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 800, 600)];
        self.view.uiView.backgroundColor = [UIColor systemBackgroundColor];
        NSLog(@"NSViewController loadView: created view with frame=%@",
              NSStringFromCGRect(self.view.frame));
    }
}

- (void)viewDidLoad {
}

- (void)viewWillAppear {
}

- (void)viewDidAppear {
}

- (void)viewWillDisappear {
}

- (void)viewDidDisappear {
}

- (void)addChildViewController:(NSViewController*)childController {
    if (!childController) return;
    childController.parentViewController = self;
    [self.childViewControllers addObject:childController];
}

- (void)removeFromParentViewController {
    [self.parentViewController.childViewControllers removeObject:self];
    self.parentViewController = nil;
}

@end

@implementation NSControl

@synthesize enabled = _enabled;
@synthesize controlSize = _controlSize;
@synthesize target = _target;
@synthesize action = _action;
@synthesize stringValue = _stringValue;
@synthesize integerValue = _integerValue;
@synthesize doubleValue = _doubleValue;
@synthesize floatValue = _floatValue;

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _enabled = YES;
        _controlSize = NSControlSizeRegular;
        _stringValue = @"";
        _integerValue = 0;
        _doubleValue = 0.0;
        _floatValue = 0.0f;
        _target = nil;
        _action = NULL;
    }
    return self;
}

- (void)sendAction:(SEL)action to:(id)target {
    [self sendAction:action to:target forEvent:nil];
}

- (BOOL)sendAction:(SEL)action to:(id)target forEvent:(NSEvent*)event {
    if (!target || !action) {
        return NO;
    }
    if (![target respondsToSelector:action]) {
        return NO;
    }
    @try {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:action withObject:self];
        #pragma clang diagnostic pop
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}

- (void)takeStringValueFrom:(id)sender {
    if ([sender respondsToSelector:@selector(stringValue)]) {
        self.stringValue = [sender stringValue];
    }
}

- (void)takeIntValueFrom:(id)sender {
    if ([sender respondsToSelector:@selector(integerValue)]) {
        self.integerValue = [sender integerValue];
    }
}

- (void)takeDoubleValueFrom:(id)sender {
    if ([sender respondsToSelector:@selector(doubleValue)]) {
        self.doubleValue = [sender doubleValue];
    }
}

- (void)takeFloatValueFrom:(id)sender {
    if ([sender respondsToSelector:@selector(floatValue)]) {
        self.floatValue = [sender floatValue];
    }
}


- (void)setStringValue:(NSString *)stringValue {
    _stringValue = [stringValue copy] ?: @"";
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *number = [formatter numberFromString:_stringValue];
    if (number) {
        _integerValue = [number integerValue];
        _doubleValue = [number doubleValue];
        _floatValue = [number floatValue];
    }
}

- (void)setIntegerValue:(NSInteger)integerValue {
    _integerValue = integerValue;
    _doubleValue = (double)integerValue;
    _floatValue = (float)integerValue;
    _stringValue = [@(integerValue) stringValue];
}

- (void)setDoubleValue:(double)doubleValue {
    _doubleValue = doubleValue;
    _integerValue = (NSInteger)doubleValue;
    _floatValue = (float)doubleValue;
    _stringValue = [@(doubleValue) stringValue];
}

- (void)setFloatValue:(float)floatValue {
    _floatValue = floatValue;
    _doubleValue = (double)floatValue;
    _integerValue = (NSInteger)floatValue;
    _stringValue = [@(floatValue) stringValue];
}

@end

@implementation NSButton

+ (instancetype)buttonWithTitle:(NSString*)title target:(id)target action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    button.title = title;
    button.target = target;
    button.action = action;
    return button;
}

+ (instancetype)checkboxWithTitle:(NSString*)title target:(id)target action:(SEL)action {
    NSButton *button = [self buttonWithTitle:title target:target action:action];
    [button setButtonType:NSButtonTypeSwitch];
    return button;
}

+ (instancetype)radioButtonWithTitle:(NSString*)title target:(id)target action:(SEL)action {
    NSButton *button = [self buttonWithTitle:title target:target action:action];
    [button setButtonType:NSButtonTypeRadio];
    return button;
}

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        if ([NSThread isMainThread]) {
            [self createButtonUI:frameRect];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self createButtonUI:frameRect];
            });
        }
        _bezelStyle = NSBezelStyleRounded;
        _bordered = YES;
        _state = NSControlStateValueOff;
        _buttonType = NSButtonTypeMomentaryPushIn;
        _title = @"";
    }
    return self;
}

- (void)createButtonUI:(CGRect)frameRect {
    _button = [UIButton buttonWithType:UIButtonTypeSystem];
    _button.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
    _button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor systemGrayColor] forState:UIControlStateDisabled];
    _button.backgroundColor = [UIColor systemBackgroundColor];
    _button.layer.borderColor = [UIColor systemGrayColor].CGColor;
    _button.layer.borderWidth = 1.0;
    _button.layer.cornerRadius = 8.0;
    [_button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _button.userInteractionEnabled = YES;
    [self.uiView addSubview:_button];
    [_button layoutIfNeeded];
    [_button setNeedsDisplay];
}

- (void)setTarget:(id)target {
    [super setTarget:target];
}

- (void)setAction:(SEL)action {
    [super setAction:action];
}

- (void)setTitle:(NSString *)title {
    _title = title ?: @"Button";
    if ([NSThread isMainThread]) {
        [self.button setTitle:_title forState:UIControlStateNormal];
        [self.button setNeedsDisplay];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.button setTitle:self.title forState:UIControlStateNormal];
            [self.button setNeedsDisplay];
        });
    }
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self.button setImage:image forState:UIControlStateNormal];
}

- (void)setButtonType:(NSButtonType)type {
    _buttonType = type;
    switch (type) {
        case NSButtonTypeSwitch:
        case NSButtonTypeRadio:
            break;
        default:
            break;
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if ([NSThread isMainThread]) {
        self.button.enabled = enabled;
        [self updateButtonAppearance];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.button.enabled = enabled;
            [self updateButtonAppearance];
        });
    }
}

- (void)updateButtonAppearance {
    if (self.enabled) {
        self.button.alpha = 1.0;
        [self.button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    } else {
        self.button.alpha = 0.6;
        [self.button setTitleColor:[UIColor systemGrayColor] forState:UIControlStateNormal];
    }
    [self.button setNeedsDisplay];
    [self.button setNeedsLayout];
}

- (void)makeKeyAndVisible {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateButtonAppearance];
    });
}

- (void)highlight:(BOOL)flag {
    self.button.highlighted = flag;
}

- (void)performClick:(id)sender {
    [self buttonPressed:self.button];
}

- (void)buttonPressed:(UIButton*)sender {
    switch (self.buttonType) {
        case NSButtonTypeSwitch:
        case NSButtonTypeRadio:
            self.state = (self.state == NSControlStateValueOff) ? NSControlStateValueOn : NSControlStateValueOff;
            break;
        default:
            break;
    }
    if (self.target && self.action) {
        BOOL success = [self sendAction:self.action to:self.target forEvent:nil];
        if (!success) {
            if ([self.target respondsToSelector:self.action]) {
                @try {
                    NSMethodSignature *signature = [self.target methodSignatureForSelector:self.action];
                    if (signature) {
                        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                        [invocation setTarget:self.target];
                        [invocation setSelector:self.action];
                        if (signature.numberOfArguments > 2) {
                            [invocation setArgument:&self atIndex:2];
                        }
                        [invocation invoke];
                    }
                } @catch (NSException *exception) {
                }
            }
        }
    }
}

@end

NSString * const NSWindowDidCreateNotification = @"NSWindowDidCreateNotification";

@implementation NSWindow

@synthesize frame = _frame;
@synthesize styleMask = _styleMask;
@synthesize alphaValue = _alphaValue;
@synthesize opaque = _opaque;
@synthesize minWidth = _minWidth;
@synthesize minHeight = _minHeight;
@synthesize maxWidth = _maxWidth;
@synthesize maxHeight = _maxHeight;
@synthesize visible = _visible;
@synthesize title = _title;
@synthesize titleDidChange = _titleDidChange;
@synthesize backgroundColor = _backgroundColor;
@synthesize delegate = _delegate;
@synthesize resizable = _resizable;
@synthesize minSize = _minSize;
@synthesize maxSize = _maxSize;
@synthesize contentView = _contentView;
@synthesize contentViewController = _contentViewController;
@synthesize identifier = _identifier;
@synthesize applicationIdentifier = _applicationIdentifier;
@synthesize bridgeViewController = _bridgeViewController;

- (instancetype)initWithContentRect:(CGRect)contentRect
                          styleMask:(NSWindowStyleMask)style
                            backing:(NSBackingStoreType)backingStoreType
                              defer:(BOOL)flag {
    self = [super init];
    if (self) {
        _identifier = [NSUUID UUID];
        _applicationIdentifier = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.unknown.app";
        _frame = contentRect;
        _styleMask = style;
        _backingStoreType = &backingStoreType;
        _alphaValue = 1.0;
        _opaque = YES;
        _minWidth = 100.0;
        _minHeight = 100.0;
        _maxWidth = CGFLOAT_MAX;
        _maxHeight = CGFLOAT_MAX;
        _visible = NO;
        _title = @"";
        _resizable = (style & NSWindowStyleMaskResizable) != 0;
        _minSize = CGSizeMake(_minWidth, _minHeight);
        _maxSize = CGSizeMake(_maxWidth, _maxHeight);
        _bridgeViewController = [[NSWindowBridgeViewController alloc] init];
        _bridgeViewController.nsWindow = self;
        _contentView = [[NSView alloc] initWithFrame:contentRect];
        _contentView.window = self;
        [self setupViewHierarchy];


        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidCreateNotification
                                                           object:self
                                                         userInfo:@{@"nsWindow": self}];
    }
    return self;
}

- (void)setupViewHierarchy {
    if (self.contentViewController) {
        if (!self.contentViewController.view) {
            [self.contentViewController loadView];
        }
        self.contentViewController.view.window = self;
        self.contentView = self.contentViewController.view;
    }

    if (self.contentView) {
        self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.contentView.window = self;
        
        [self.contentView syncCoordinateSystems];

        NSLog(@"NSWindow setupViewHierarchy: contentView frame=%@, window frame=%@",
              NSStringFromCGRect(self.contentView.frame),
              NSStringFromCGRect(self.frame));
    }
}



- (void)makeKeyAndVisible {
    self.visible = YES;
    [self makeKeyWindow];
    [self orderFront:self];

    NSLog(@"NSWindow makeKeyAndVisible: visible=%d, contentView=%@",
          self.visible, self.contentView);
}
- (void)makeKeyWindow {

    if ([self.delegate respondsToSelector:@selector(windowDidBecomeKey:)]) {

    }
}

- (void)orderOut:(id)sender {
    self.visible = NO;
    [self.contentView.uiView removeFromSuperview];
}

- (void)orderFront:(id)sender {
    self.visible = YES;

    if (self.contentView && self.bridgeViewController) {
        if (![self.contentView.uiView isDescendantOfView:self.bridgeViewController.view]) {
            [self.bridgeViewController.view addSubview:self.contentView.uiView];
        }

        CGRect contentFrame = self.bridgeViewController.view.bounds;
        self.contentView.uiView.frame = contentFrame;
        self.contentView.uiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        NSLog(@"NSWindow orderFront: set contentView frame to %@",
              NSStringFromCGRect(self.contentView.uiView.frame));
    }
}
- (void)orderBack:(id)sender {

}

- (void)makeKeyAndOrderFront:(id)sender {
    [self makeKeyWindow];
    [self orderFront:sender];
}

- (void)setFrame:(CGRect)frame display:(BOOL)displayFlag {
    [self setFrame:frame display:displayFlag animate:NO];
}

- (void)setFrame:(CGRect)frame display:(BOOL)displayFlag animate:(BOOL)animateFlag {
    _frame = [self constrainFrameRect:frame toScreen:[UIScreen mainScreen]];
    self.contentView.frame = _frame;
    self.bridgeViewController.view.frame = _frame;
    if (displayFlag) {
        [self.contentView setNeedsDisplay:YES];
        [self.contentView layoutSubviews];
    }
}

- (void)center {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat x = (screenSize.width - self.frame.size.width) / 2;
    CGFloat y = (screenSize.height - self.frame.size.height) / 2;
    [self setFrame:CGRectMake(x, y, self.frame.size.width, self.frame.size.height) display:YES];
}

- (void)miniaturize:(id)sender {
    if ([self.delegate respondsToSelector:@selector(windowDidMiniaturize:)]) {
        [self.delegate windowDidMiniaturize:[NSNotification notificationWithName:@"windowDidMiniaturize" object:self]];
    }
}

- (void)deminiaturize:(id)sender {
}

- (void)zoom:(id)sender {
}

- (void)close {
    if ([self.delegate respondsToSelector:@selector(windowShouldClose:)] && ![self.delegate windowShouldClose:self]) {
        return;
    }
    [self orderOut:self];
    if ([self.delegate respondsToSelector:@selector(windowWillClose:)]) {
        [self.delegate windowWillClose:[NSNotification notificationWithName:@"windowWillClose" object:self]];
    }
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)becomeKeyWindow {
}

- (void)resignKeyWindow {
}

- (void)becomeMainWindow {
}

- (void)resignMainWindow {
}

- (void)setResizable:(BOOL)resizable {
    _resizable = resizable;
}

- (void)setMinSize:(CGSize)minSize {
    _minSize = minSize;
    _minWidth = minSize.width;
    _minHeight = minSize.height;
}

- (void)setMaxSize:(CGSize)maxSize {
    _maxSize = maxSize;
    _maxWidth = maxSize.width;
    _maxHeight = maxSize.height;
}

- (CGRect)constrainFrameRect:(CGRect)frameRect toScreen:(UIScreen*)screen {
    if (!screen) {
        return frameRect;
    }
    CGRect screenBounds = screen.bounds;
    CGFloat newWidth = MIN(MAX(frameRect.size.width, self.minWidth), self.maxWidth);
    CGFloat newHeight = MIN(MAX(frameRect.size.height, self.minHeight), self.maxHeight);
    CGFloat newX = MAX(MIN(frameRect.origin.x, screenBounds.size.width - newWidth), 0);
    CGFloat newY = MAX(MIN(frameRect.origin.y, screenBounds.size.height - newHeight), 0);
    return CGRectMake(newX, newY, newWidth, newHeight);
}

- (void)setContentView:(NSView *)contentView {
    if (_contentView != contentView) {
        [_contentView removeFromSuperview];

        if ([contentView isKindOfClass:[NSView class]]) {
            _contentView = contentView;
        } else if ([contentView isKindOfClass:[UIView class]]) {

            UIView *uiView = (UIView *)contentView;

            NSView *wrappedView = [[NSView alloc] initWithFrame:uiView.frame];
            [wrappedView.uiView addSubview:uiView];
            uiView.frame = wrappedView.uiView.bounds;
            _contentView = wrappedView;
        }

        _contentView.window = self;
        [self setupViewHierarchy];
        if (self.visible) {
            [self orderFront:self];
        }
    }
}


- (void)setContentViewController:(NSViewController *)contentViewController {
    if (_contentViewController != contentViewController) {
        [_contentViewController removeFromParentViewController];
        _contentViewController = contentViewController;

        if (contentViewController) {

            if (!contentViewController.view) {
                [contentViewController loadView];
                [contentViewController viewDidLoad];
            }


            contentViewController.view.window = self;


            self.contentView = contentViewController.view;

            NSLog(@"NSWindow setContentViewController: set contentView to %@, frame=%@",
                  contentViewController.view, NSStringFromCGRect(contentViewController.view.frame));
        }
    }
}




- (void)addChildViewController:(NSViewController*)childController {
    if (!childController) return;
    childController.parentViewController = self.contentViewController;
    [self.contentViewController addChildViewController:childController];
    [self setupViewHierarchy];
}

@end
