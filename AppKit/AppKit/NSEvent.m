//
//  NSEvent.m
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import "NSEvent.h"

@implementation NSEvent

static NSMutableArray<NSDictionary *> *localMonitors = nil;
static NSMutableSet<NSNumber *> *keysDown = nil;
static NSInteger monitorIdCounter = 0;

+ (void)initialize {
    if (self == [NSEvent class]) {
        localMonitors = [NSMutableArray array];
        keysDown = [NSMutableSet set];
    }
}


+ (instancetype)eventWithType:(NSEventType)type
                     location:(CGPoint)location
                modifierFlags:(NSEventModifierFlags)flags
                    timestamp:(NSTimeInterval)timestamp {
    NSEvent *event = [[NSEvent alloc] init];
    event->_type = type;
    event->_locationInWindow = location;
    event->_modifierFlags = flags;
    event->_timestamp = timestamp;
    return event;
}

+ (instancetype)keyEventWithType:(NSEventType)type
                        location:(CGPoint)location
                   modifierFlags:(NSEventModifierFlags)flags
                       timestamp:(NSTimeInterval)timestamp
                      characters:(NSString *)characters
     charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers
                         keyCode:(unsigned short)keyCode {
    NSEvent *event = [self eventWithType:type location:location modifierFlags:flags timestamp:timestamp];
    event->_characters = [characters copy];
    event->_charactersIgnoringModifiers = [charactersIgnoringModifiers copy];
    event->_keyCode = keyCode;
    return event;
}


+ (void)sendEvent:(NSEvent *)event {
    if (!event) return;


    switch (event.type) {
        case NSEventTypeKeyDown:
            [keysDown addObject:@(event.keyCode)];
            break;
        case NSEventTypeKeyUp:
            [keysDown removeObject:@(event.keyCode)];
            break;
        default:
            break;
    }

    NSEvent *processedEvent = [self dispatchEventToMonitors:event];
    if (processedEvent) {
        [self handleProcessedEvent:processedEvent];
    }
}

+ (NSEvent *)dispatchEventToMonitors:(NSEvent *)event {
    if (!event) return nil;

    NSEvent *result = event;

    @synchronized(localMonitors) {
        for (NSDictionary *monitor in [localMonitors copy]) {
            NSEventMask mask = [monitor[@"mask"] unsignedIntegerValue];
            NSEventMonitorHandler handler = monitor[@"handler"];

            BOOL matchesEventType = NO;

            switch (event.type) {
                case NSEventTypeKeyDown:
                    matchesEventType = (mask & NSEventMaskKeyDown) != 0;
                    break;
                case NSEventTypeKeyUp:
                    matchesEventType = (mask & NSEventMaskKeyUp) != 0;
                    break;
                default:
                    matchesEventType = (mask & NSEventMaskAny) != 0;
                    break;
            }

            if (matchesEventType) {
                NSEvent *handlerResult = handler(result);
                if (!handlerResult) return nil;
                result = handlerResult;
            }
        }
    }

    return result;
}

+ (void)handleProcessedEvent:(NSEvent *)event {
    NSLog(@"Handling %@ event: keyCode=%hu, chars=%@",
          event.type == NSEventTypeKeyDown ? @"KeyDown" : @"KeyUp",
          event.keyCode,
          event.characters);
}


+ (nullable id)addLocalMonitorForEventsMatchingMask:(NSEventMask)mask
                                            handler:(NSEventMonitorHandler)block {
    if (!block) return nil;
    @synchronized(localMonitors) {
        NSInteger monitorId = ++monitorIdCounter;
        NSDictionary *monitor = @{
            @"id": @(monitorId),
            @"mask": @(mask),
            @"handler": [block copy]
        };
        [localMonitors addObject:monitor];
        return @(monitorId);
    }
}

+ (void)removeMonitor:(id)eventMonitor {
    if (!eventMonitor) return;
    @synchronized(localMonitors) {
        [localMonitors removeObjectsInArray:[localMonitors filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *monitor, NSDictionary *bindings) {
                return [monitor[@"id"] isEqual:eventMonitor];
            }]]];
    }
}


- (CGPoint)locationInWindow { return _locationInWindow; }
- (NSEventModifierFlags)modifierFlags { return _modifierFlags; }
- (NSEventType)type { return _type; }
- (NSTimeInterval)timestamp { return _timestamp; }
- (NSString *)characters { return _characters; }
- (NSString *)charactersIgnoringModifiers { return _charactersIgnoringModifiers; }
- (unsigned short)keyCode { return _keyCode; }

@end