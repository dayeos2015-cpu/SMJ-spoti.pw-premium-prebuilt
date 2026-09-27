#import "SGLog.h"
#import <os/lock.h>

static const NSUInteger kLogBufferLimit = 256 * 1024;
static os_unfair_lock sg_logLock = OS_UNFAIR_LOCK_INIT;
static NSMutableArray<NSString *> *sg_logEntries;
static NSUInteger sg_logBytes;

void SGLogMessage(NSString *message) {
    if (message.length > 32768) message = [@"...(truncated)...\n" stringByAppendingString:[message substringFromIndex:message.length - 32768]];
    NSString *line = [@"[spotifyglass] " stringByAppendingString:message ?: @"(null)"];
    NSUInteger size = [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;

    os_unfair_lock_lock(&sg_logLock);
    if (!sg_logEntries) sg_logEntries = [NSMutableArray array];
    [sg_logEntries addObject:line];
    sg_logBytes += size;
    while (sg_logBytes > kLogBufferLimit && sg_logEntries.count > 1) {
        sg_logBytes -= [sg_logEntries.firstObject lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
        [sg_logEntries removeObjectAtIndex:0];
    }
    os_unfair_lock_unlock(&sg_logLock);

    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEFAULT, "[spotifyglass] %{public}s", (message ?: @"(null)").UTF8String);
}

NSString *SGLogSnapshot(void) {
    os_unfair_lock_lock(&sg_logLock);
    NSString *snapshot = [sg_logEntries componentsJoinedByString:@"\n"] ?: @"";
    os_unfair_lock_unlock(&sg_logLock);
    return snapshot;
}

void SGLogClear(void) {
    os_unfair_lock_lock(&sg_logLock);
    [sg_logEntries removeAllObjects];
    sg_logBytes = 0;
    os_unfair_lock_unlock(&sg_logLock);
}

// The unified log cuts a message at about 1 KB, so long dumps go out as numbered parts.
void SGLogLong(NSString *tag, NSString *text) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSMutableString *current = [NSMutableString string];
    for (NSString *line in [text componentsSeparatedByString:@"\n"]) {
        if (current.length && [current lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > 900) {
            [parts addObject:[current copy]];
            [current setString:@""];
        }
        [current appendFormat:@"%@\n", line];
    }
    if (current.length) [parts addObject:current];
    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger i, BOOL *stop) {
        SGLog(@"%@ %lu/%lu\n%@", tag, (unsigned long)i + 1, (unsigned long)parts.count, part);
    }];
}

void SGRequireClasses(NSArray<NSString *> *names) {
    for (NSString *name in names) {
        if (!NSClassFromString(name)) SGLog(@"class %@ not found, its hooks are inactive", name);
    }
}
