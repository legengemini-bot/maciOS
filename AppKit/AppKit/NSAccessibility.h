//
//  NSAccessibility.h
//  AppKit-iOS
//
//  Created by Stossy11 on 28/08/2025.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const NSAccessibilityFocusedUIElementChangedNotification;
extern NSString * const NSAccessibilityValueChangedNotification;
extern NSString * const NSAccessibilityCreatedNotification;
extern NSString * const NSAccessibilityUIElementDestroyedNotification;
extern NSString * const NSAccessibilityTitleChangedNotification;
extern NSString * const NSAccessibilityWindowCreatedNotification;
extern NSString * const NSAccessibilityLayoutChangedNotification;
extern NSString * const NSAccessibilityAnnouncementRequestedNotification;

extern NSString * const NSAccessibilityButtonRole;
extern NSString * const NSAccessibilityCheckBoxRole;
extern NSString * const NSAccessibilityRadioButtonRole;
extern NSString * const NSAccessibilityTextFieldRole;
extern NSString * const NSAccessibilityStaticTextRole;
extern NSString * const NSAccessibilityWindowRole;
extern NSString * const NSAccessibilityImageRole;
extern NSString * const NSAccessibilityGroupRole;

extern NSString * const NSAccessibilityRoleAttribute;
extern NSString * const NSAccessibilitySubroleAttribute;
extern NSString * const NSAccessibilityTitleAttribute;
extern NSString * const NSAccessibilityValueAttribute;
extern NSString * const NSAccessibilityEnabledAttribute;
extern NSString * const NSAccessibilityFocusedAttribute;
extern NSString * const NSAccessibilityParentAttribute;
extern NSString * const NSAccessibilityChildrenAttribute;
extern NSString * const NSAccessibilityWindowAttribute;
extern NSString * const NSAccessibilityFrameAttribute;

extern NSString * const NSAccessibilityPressAction;
extern NSString * const NSAccessibilityIncrementAction;
extern NSString * const NSAccessibilityDecrementAction;
extern NSString * const NSAccessibilityConfirmAction;
extern NSString * const NSAccessibilityCancelAction;

FOUNDATION_EXPORT void NSAccessibilityPostNotification(id element, NSString *notification);

NS_ASSUME_NONNULL_END
