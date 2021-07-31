#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

static inline bool equali(NSString *a, NSString *b)
{
	return a && b && [a caseInsensitiveCompare:b] == NSOrderedSame;
}

@interface OBSSparkleUpdateDelegate
	: NSObject <SUUpdaterDelegate, SUVersionComparison> {
}
@end

@implementation OBSSparkleUpdateDelegate {
}

- (NSString *)feedURLStringForUpdater:(SUUpdater *)updater
{
	//URL from Info.plist takes precedence because there may be bundles with
	//differing feed URLs on the system
	NSBundle *bundle = updater.hostBundle;
	return [bundle objectForInfoDictionaryKey:@"SUFeedURL"];
}

- (NSComparisonResult)compareVersion:(NSString *)versionA
			   toVersion:(NSString *)versionB
{
	if (![versionA isEqual:versionB])
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (id<SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)__unused
	updater
{
	return self;
}

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)item
{
	[updater checkForUpdates:nil];
}

@end

static inline bool bundle_matches(NSBundle *bundle)
{
	if (!bundle.executablePath)
		return false;

	NSRange r = [bundle.executablePath rangeOfString:@"Contents/MacOS/"];
	return [bundle.bundleIdentifier isEqual:@"live.telley.viewer"] &&
	       r.location != NSNotFound;
}

static inline NSBundle *find_bundle()
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [fm currentDirectoryPath];
	NSString *prev = path;
	do {
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		if (bundle_matches(bundle))
			return bundle;

		prev = path;
		path = [path stringByDeletingLastPathComponent];
	} while (![prev isEqual:path]);
	return nil;
}

static SUUpdater *updater;

static OBSSparkleUpdateDelegate *delegate;

void init_sparkle_updater()
{
	updater = [SUUpdater updaterForBundle:find_bundle()];
	delegate = [[OBSSparkleUpdateDelegate alloc] init];
	updater.automaticallyDownloadsUpdates = false;
	updater.automaticallyChecksForUpdates = false;
	updater.delegate = delegate;
        [updater resetUpdateCycle];
}

void trigger_sparkle_update()
{
        NSBundle *bundle = updater.hostBundle;
        NSLog(@"Bundle: %@", bundle.bundleIdentifier);
        if (bundle_matches(bundle)) {
		[updater checkForUpdates:nil];
	}
}

void trigger_background_update()
{
        NSBundle *bundle = updater.hostBundle;
	NSLog(@"Bundle: %@", bundle.bundleIdentifier);
        if (bundle_matches(bundle)) {
                [updater checkForUpdatesInBackground];
        }
}
