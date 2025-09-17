//
//  NSEvent.h
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NSEventType) {
    NSEventTypeLeftMouseDown = 1,
    NSEventTypeLeftMouseUp = 2,
    NSEventTypeRightMouseDown = 3,
    NSEventTypeRightMouseUp = 4,
    NSEventTypeMouseMoved = 5,
    NSEventTypeLeftMouseDragged = 6,
    NSEventTypeRightMouseDragged = 7,
    NSEventTypeMouseEntered = 8,
    NSEventTypeMouseExited = 9,
    NSEventTypeKeyDown = 10,
    NSEventTypeKeyUp = 11,
    NSEventTypeFlagsChanged = 12,
    NSEventTypeAppKitDefined = 13,
    NSEventTypeSystemDefined = 14,
    NSEventTypeApplicationDefined = 15,
    NSEventTypePeriodic = 16,
    NSEventTypeCursorUpdate = 17,
    NSEventTypeScrollWheel = 22,
    NSEventTypeTabletPoint = 23,
    NSEventTypeTabletProximity = 24,
    NSEventTypeOtherMouseDown = 25,
    NSEventTypeOtherMouseUp = 26,
    NSEventTypeOtherMouseDragged = 27,
    NSEventTypeGesture = 29,
    NSEventTypeMagnify = 30,
    NSEventTypeSwipe = 31,
    NSEventTypeRotate = 18,
    NSEventTypeBeginGesture = 19,
    NSEventTypeEndGesture = 20,
    NSEventTypeSmartMagnify = 32,
    NSEventTypeQuickLook = 33,
    NSEventTypePressure = 34,
    NSEventTypeDirectTouch = 37,
    NSEventTypeChangeMode = 38,
};


typedef NS_OPTIONS(NSUInteger, NSEventModifierFlags) {
    NSEventModifierFlagCapsLock = 1 << 16,
    NSEventModifierFlagShift = 1 << 17,
    NSEventModifierFlagControl = 1 << 18,
    NSEventModifierFlagOption = 1 << 19,
    NSEventModifierFlagCommand = 1 << 20,
    NSEventModifierFlagNumericPad = 1 << 21,
    NSEventModifierFlagHelp = 1 << 22,
    NSEventModifierFlagFunction = 1 << 23,
};


typedef NSUInteger NSEventMask;
#define NSEventMaskKeyDown (1UL << NSEventTypeKeyDown)
#define NSEventMaskKeyUp (1UL << NSEventTypeKeyUp)
#define NSEventMaskLeftMouseDown (1UL << NSEventTypeLeftMouseDown)
#define NSEventMaskLeftMouseUp (1UL << NSEventTypeLeftMouseUp)
#define NSEventMaskRightMouseDown (1UL << NSEventTypeRightMouseDown)
#define NSEventMaskRightMouseUp (1UL << NSEventTypeRightMouseUp)
#define NSEventMaskMouseMoved (1UL << NSEventTypeMouseMoved)
#define NSEventMaskLeftMouseDragged (1UL << NSEventTypeLeftMouseDragged)
#define NSEventMaskRightMouseDragged (1UL << NSEventTypeRightMouseDragged)
#define NSEventMaskAny NSUIntegerMax


@class NSEvent;
typedef NSEvent* _Nullable (^NSEventMonitorHandler)(NSEvent *event);

@interface NSEvent : NSObject {
    NSEventType _type;
    CGPoint _locationInWindow;
    NSEventModifierFlags _modifierFlags;
    NSTimeInterval _timestamp;
    NSString *_characters;
    NSString *_charactersIgnoringModifiers;
    unsigned short _keyCode;
}

@property (nonatomic, readonly) NSEventType type;
@property (nonatomic, readonly) CGPoint locationInWindow;
@property (nonatomic, readonly) NSEventModifierFlags modifierFlags;
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, readonly, nullable) NSString *characters;
@property (nonatomic, readonly, nullable) NSString *charactersIgnoringModifiers;
@property (nonatomic, readonly) unsigned short keyCode;

+ (instancetype)eventWithType:(NSEventType)type
                     location:(CGPoint)location
                modifierFlags:(NSEventModifierFlags)flags
                    timestamp:(NSTimeInterval)timestamp;

+ (instancetype)keyEventWithType:(NSEventType)type
                        location:(CGPoint)location
                   modifierFlags:(NSEventModifierFlags)flags
                       timestamp:(NSTimeInterval)timestamp
                      characters:(NSString *)characters
     charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers
                         keyCode:(unsigned short)keyCode;


+ (nullable id)addLocalMonitorForEventsMatchingMask:(NSEventMask)mask
                                            handler:(NSEventMonitorHandler)block;
+ (void)removeMonitor:(id)eventMonitor;

+ (void)sendEvent:(NSEvent *)event;

@end

NS_ASSUME_NONNULL_END
