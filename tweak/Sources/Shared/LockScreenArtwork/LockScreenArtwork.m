// What the hook, the harness and the settings share: the order of the sources, which key this iOS
// takes a clip under, and putting one there.
#import <MediaPlayer/MediaPlayer.h>
#import <objc/message.h>
#import <dlfcn.h>
#import "LockScreenArtwork.h"

NSString *const SGArtworkSourceSpotify = @"spotify";
NSString *const SGArtworkSourceApple = @"applemusic";

NSArray<NSString *> *SGArtworkOrder(void) {
    id stored = [NSUserDefaults.standardUserDefaults arrayForKey:SGKeyLockScreenArtworkSources];
    NSArray *keys = [stored isKindOfClass:NSArray.class] ? stored : @[SGArtworkSourceSpotify, SGArtworkSourceApple];
    NSMutableArray<NSString *> *order = [NSMutableArray array];
    for (id key in keys) {
        BOOL known = [key isEqual:SGArtworkSourceSpotify] || [key isEqual:SGArtworkSourceApple];
        if (known && ![order containsObject:key]) [order addObject:key];
    }
    return order;
}

void SGArtworkSetOrder(NSArray<NSString *> *order) {
    [NSUserDefaults.standardUserDefaults setObject:order ?: @[] forKey:SGKeyLockScreenArtworkSources];
}

static NSString *SGMediaFrameworkProperty(NSString *propertyName) {
    void *handle = dlopen("/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer", RTLD_LAZY);
    if (handle) {
        NSString **propPtr = (NSString **)dlsym(handle, propertyName.UTF8String);
        if (propPtr) {
            NSString *val = *propPtr;
            dlclose(handle);
            return val;
        }
        dlclose(handle);
    }
    return nil;
}

BOOL SGAnimatedArtworkAvailable(void) {
    return NSClassFromString(@"MPMediaItemAnimatedArtwork") != nil;
}

NSArray<NSString *> *SGAnimatedArtworkKeys(void) {
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    SEL sel = NSSelectorFromString(@"supportedAnimatedArtworkKeys");
    if ([center respondsToSelector:sel]) {
        return ((id (*)(id, SEL))objc_msgSend)(center, sel);
    }
    return nil;
}

NSString *SGAnimatedArtworkKey(CGFloat *aspect) {
    NSArray<NSString *> *supported = SGAnimatedArtworkKeys();
    if (!supported || supported.count == 0) return nil;

    NSString *key3x4 = SGMediaFrameworkProperty(@"MPNowPlayingInfoProperty3x4AnimatedArtwork");
    if (key3x4 && [supported containsObject:key3x4]) {
        if (aspect) *aspect = 3.0 / 4.0;
        return key3x4;
    }

    NSString *key1x1 = SGMediaFrameworkProperty(@"MPNowPlayingInfoProperty1x1AnimatedArtwork");
    if (key1x1 && [supported containsObject:key1x1]) {
        if (aspect) *aspect = 1.0;
        return key1x1;
    }

    return nil;
}

NSDictionary *SGArtworkInInfo(NSDictionary *info, id artwork, NSString *key) {
    if (!info.count || !artwork || !key.length) return info;
    if (info[key] == artwork) return info;
    NSMutableDictionary *shown = [info mutableCopy];
    shown[key] = artwork;
    return shown;
}
