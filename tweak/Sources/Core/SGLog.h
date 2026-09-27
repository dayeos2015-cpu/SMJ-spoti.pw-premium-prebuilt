#import <Foundation/Foundation.h>
#import <os/log.h>

// Kept in memory for the in-app log viewer as well as the unified log.
void SGLogMessage(NSString *message);
NSString *SGLogSnapshot(void);
void SGLogClear(void);

#define SGLog(fmt, ...) SGLogMessage([NSString stringWithFormat:(fmt), ##__VA_ARGS__])

// Long dumps, split into numbered parts under the unified log's size cap.
void SGLogLong(NSString *tag, NSString *text);
// Logs every class of the list that this Spotify does not have; a feature calls it from its %ctor.
void SGRequireClasses(NSArray<NSString *> *names);
