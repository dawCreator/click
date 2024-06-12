//
//  MultitouchSupport.h
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

#ifndef MultitouchSupport_h
#define MultitouchSupport_h

#import <Foundation/Foundation.h>

typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

enum {
    MTTouchStateNotTracking = 0,
    MTTouchStateStartInRange = 1,
    MTTouchStateHoverInRange = 2,
    MTTouchStateMakeTouch = 3,
    MTTouchStateTouching = 4,
    MTTouchStateBreakTouch = 5,
    MTTouchStateLingerInRange = 6,
    MTTouchStateOutOfRange = 7
}; typedef uint32_t MTTouchState;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t pathIndex;    // "P" (~transducerIndex)
    MTTouchState state;
    int32_t fingerID;    // "F" (~identity)
    int32_t handID;        // "H" (always 1)
    MTVector normalized;
    float zTotal;        // "ZTot" (~quality, multiple of 1/8 between 0 and 1)
    int32_t field9;        // always 0
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absoluteVector;    // "mm"
    int32_t field14;    // always 0
    int32_t field15;    // always 0
    float zDensity;        // "ZDen" (~density)
} MTTouch;

typedef CFTypeRef MTDevice;

double MTAbsoluteTimeGetCurrent();
bool MTDeviceIsAvailable();        // true if can create default device

CFArrayRef MTDeviceCreateList();        // creates for driver types 0, 1, 4, 2, 3
MTDevice MTDeviceCreateDefault();
MTDevice MTDeviceCreateFromDeviceID(int64_t);
MTDevice MTDeviceCreateFromService(io_service_t);
MTDevice MTDeviceCreateFromGUID(uuid_t);        // GUID's compared by pointer, not value!
void MTDeviceRelease(MTDevice);

CFRunLoopSourceRef MTDeviceCreateMultitouchRunLoopSource(MTDevice);
OSStatus MTDeviceScheduleOnRunLoop(MTDevice, CFRunLoopRef, CFStringRef);

OSStatus MTDeviceStart(MTDevice, int);
OSStatus MTDeviceStop(MTDevice);
bool MTDeviceIsRunning(MTDevice);


bool MTDeviceIsValid(MTDevice);
bool MTDeviceIsBuiltIn(MTDevice) __attribute__ ((weak_import));    // no 10.5
bool MTDeviceIsOpaqueSurface(MTDevice);
io_service_t MTDeviceGetService(MTDevice);
OSStatus MTDeviceGetSensorSurfaceDimensions(MTDevice, int*, int*);
OSStatus MTDeviceGetFamilyID(MTDevice, int*);
OSStatus MTDeviceGetDeviceID(MTDevice, uint64_t*) __attribute__ ((weak_import));    // no 10.5
OSStatus MTDeviceGetDriverType(MTDevice, int*);
OSStatus MTDeviceGetActualType(MTDevice, int*);
OSStatus MTDeviceGetGUID(MTDevice, uuid_t*);

typedef void (*MTFrameCallbackFunction)(MTDevice device,
                                        MTTouch touches[], size_t numTouches,
                                        double timestamp, size_t frame);
void MTRegisterContactFrameCallback(MTDevice, MTFrameCallbackFunction);

typedef void (*MTFrameCallbackRefconFunction)(MTDevice device,
                                        MTTouch touches[], size_t numTouches,
                                        double timestamp, size_t frame, void* refcon);
void MTRegisterContactFrameCallbackWithRefcon(MTDevice, MTFrameCallbackRefconFunction, void* refcon);
void MTUnregisterContactFrameCallback(MTDevice, MTFrameCallbackRefconFunction);


typedef void (*MTPathCallbackFunction)(MTDevice device, long pathID, long state, MTTouch* touch);
MTPathCallbackFunction MTPathPrintCallback;
void MTRegisterPathCallback(MTDevice, MTPathCallbackFunction);

/*
 // callbacks never called (need different flags?)
typedef void (*MTImageCallbackFunction)(MTDeviceRef, void*, void*);
MTImageCallbackFunction MTImagePrintCallback;
void MTRegisterMultitouchImageCallback(MTDeviceRef, MTImageCallbackFunction);
 */

/*
 // these log error
void MTVibratorRunForDuration(MTDeviceRef,long);
void MTVibratorStop(MTDeviceRef);
*/

#endif /* MultitouchSupport_h */
