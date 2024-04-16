#include <pthread.h>
#include <stdbool.h>
#include <string.h>
#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>

#define streq(a, b) (strcmp((a), (b)) == 0)

// Helper class implementing the informal KVO protocol, so the rest of the code
// just has to deal with normal callbacks.
@interface KeyValueObserver : NSObject

// Key-Value observion configuration
@property (nonatomic, weak) id observedObject;
@property (nonatomic, copy) NSString* keyPath;

// Will be invoked when observee changes
// Apparently its important to copy blocks??
@property (nonatomic, copy) void (^callback)(NSDictionary *);

// Create a Key-Value Observing helper object.
//
// As long as the returned token object is retained, the KVO notifications of
// the object and keyPath will cause the given selector to be called on target.
// object and target are weak references.
//
// Once the token object gets dealloc'ed, the observer gets removed.
+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath callback:(void(^)(NSDictionary *))callback __attribute__((warn_unused_result));

// Create a key-value-observer with the given KVO options
+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options callback:(void(^)(NSDictionary *))callback __attribute__((warn_unused_result));

@end

@implementation KeyValueObserver

- (id)initWithObject:(id)object keyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options callback:(void(^)(NSDictionary *))callback
{
	if (object == nil) {
		return nil;
	}
	self = [super init];
	if (self) {
		self.callback = callback;
		self.observedObject = object;
		self.keyPath = keyPath;
		[object addObserver:self forKeyPath:keyPath options:options context:(__bridge void *)(self)];
	}
	return self;
}

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath callback:(void(^)(NSDictionary *))callback __attribute__((warn_unused_result))
{
	return [self observeObject:object keyPath:keyPath options:0 callback:callback];
}

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options callback:(void(^)(NSDictionary *))callback __attribute__((warn_unused_result))
{
	return [[self alloc] initWithObject:object keyPath:keyPath options:options callback:callback];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (context == (__bridge void *)(self)) {
		self.callback(change);
	}
}

- (void)dealloc
{
	[self.observedObject removeObserver:self forKeyPath:self.keyPath];
}

@end

void usage() {
	fprintf(stderr, "Usage: dark-notify [--exit / -e] [--only-changes / -o]\n"
	                "  --exit, -e          Exit after the first color has been shown\n"
	                "  --only-changes, -o  Do not show the current value when starting\n");
	exit(1);
}

void *handleQuit(void *arg)
{
	(void) arg;

	char *line = NULL;
	size_t linecap = 0;
	ssize_t linelen;
	while ((linelen = getline(&line, &linecap, stdin)) > 0) {
		if (streq(line, "quit\n")) {
			exit(0);
		}
	}

	return NULL;
}

int main(int argc, char *argv[])
{
	bool shouldExit = false;
	bool onlyChanges = false;
	for (int i = 1; i < argc; ++i) {
		char *arg = argv[i];

		if (streq(arg, "--exit") || streq(arg, "-e")) {
			shouldExit = true;
		} else if (streq(arg, "--only-changes") || streq(arg, "-o")) {
			onlyChanges = true;
		} else if (streq(arg, "--help") || streq(arg, "-h")) {
			usage();
		} else {
			fprintf(stderr, "Unknown flag: %s\n", argv[0]);
			usage();
		}
	}

	// The background thread will exit the process upon the user's request via stdin.
	pthread_t background_thread;
	if (pthread_create(&background_thread, NULL, handleQuit, NULL) < 0) {
		fprintf(stderr, "Failed to spawn background thread: %s\n", strerror(errno));
		exit(1);
	}
	if (pthread_detach(background_thread) < 0) {
		fprintf(stderr, "Failed to detach thread\n");
		exit(1);
	}

	// For the rest of the main function, we set up a minimal application in order to moniter theme changes.
	id app = [NSApplication sharedApplication];

	// We don't want to create a window or appear in the Dock.
	[app setActivationPolicy:NSApplicationActivationPolicyProhibited];

	void (^handleAppearanceChange)(NSAppearance *) = ^(NSAppearance *appearance) {
		NSArray *names = @[NSAppearanceNameAqua, NSAppearanceNameDarkAqua];
		id bestMatch = [appearance bestMatchFromAppearancesWithNames:names];
		bool isDarkMode = bestMatch == NSAppearanceNameDarkAqua;

		if (isDarkMode) {
			printf("dark\n");
		} else {
			printf("light\n");
		}

		if (shouldExit) {
			exit(0);
		}
	};

	if (!onlyChanges) {
		handleAppearanceChange([app effectiveAppearance]);
		[app effectiveAppearance];
	}

	id observerToken = [KeyValueObserver observeObject:app
						   keyPath:@"effectiveAppearance"
						   options:NSKeyValueObservingOptionNew
						   callback:^(NSDictionary *change) {
							   handleAppearanceChange(change[@"new"]);
						   }];

	[app run];

	return 0;
}
