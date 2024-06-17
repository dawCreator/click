#  NotificationCenter (Device Changed)

name = _NSNotificationDevicesChanged, object = nil, userInfo = nil
name = NSTouchDeviceRemovedNotification, object = Optional(<SwiftUI.AppKitApplication: 0x13ce06200>), userInfo = Optional([AnyHashable("NSTouchDevice"): NSTouchDevice(0x600003890720) deviceID:0x40000005f120659 hasActuation:0
 contextMap:(null)])
name = NSTouchDeviceAddedNotification, object = Optional(<SwiftUI.AppKitApplication: 0x13ce06200>), userInfo = Optional([AnyHashable("NSTouchDevice"): NSTouchDevice(0x600003894240) deviceID:0x40000005f120659 hasActuation:0
 contextMap:(null)])
name = _NSNotificationDevicesChanged, object = nil, userInfo = nil

# Trackpad Zoom:

 //#include <IOKit/hid/IOHIDLib.h>

// Define a structure for multitouch events
typedef struct {
    int32_t contactID;
    CGPoint position;
    float pressure;
} TouchPoint;

// Function to create a multitouch event
void createPinchEvent(TouchPoint *touchPoints, size_t count) {
    // Initialize HID Manager
    IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!hidManager) {
        return;
    }

    // Configure HID Manager to include only touch events
    CFMutableDictionaryRef matchingDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (!matchingDict) {
        CFRelease(hidManager);
        return;
    }
    
    // ... Additional setup for matchingDict ...

    IOHIDManagerSetDeviceMatching(hidManager, matchingDict);
    CFRelease(matchingDict);

    // Open HID Manager
    IOReturn result = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
    if (result != kIOReturnSuccess) {
        CFRelease(hidManager);
        return;
    }

    // Create a HID event for multitouch
    // This part involves using private APIs and structures
    // ... Setup code to create and configure IOHIDEventRef ...

    IOHIDEventRef event = IOHIDEventCreate(kCFAllocatorDefault, kIOHIDEventTypeMultiAxisPointer, 0, 0);
    if (!event) {
        IOHIDManagerClose(hidManager, kIOHIDOptionsTypeNone);
        CFRelease(hidManager);
        return;
    }

    // ... Configure the event with touchPoints data ...

    // Post the event
    IOHIDEventSystemClientDispatchEvent(IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault), event);

    // Clean up
    CFRelease(event);
    IOHIDManagerClose(hidManager, kIOHIDOptionsTypeNone);
    CFRelease(hidManager);
}

// Example usage
int main() {
    TouchPoint touchPoints[2] = {
        { .contactID = 1, .position = CGPointMake(100, 100), .pressure = 1.0 },
        { .contactID = 2, .position = CGPointMake(200, 200), .pressure = 1.0 }
    };

    createPinchEvent(touchPoints, 2);
    return 0;
}

