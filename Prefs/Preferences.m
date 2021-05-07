#import "Preferences.h"

@implementation REVPrefsListController
- (instancetype) init {
    self = [super init];
    return self;
}

- (id) specifiers {
    if(_specifiers == nil) _specifiers = [[self loadSpecifiersFromPlistName: @"ReveriePrefs" target: self] retain];
    return _specifiers;
}

- (void) viewWillAppear: (bool) animated {
	[super viewWillAppear: animated];
    CGRect frame = self.table.bounds;
    frame.origin.y = -frame.size.height;
    [self.navigationController.navigationController.navigationBar setShadowImage: [UIImage new]];
    self.navigationController.navigationController.navigationBar.translucent = 1;
}

- (void) reverieSleep: (id) sender {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"ai.paisseon.reverie/PrefsSleep", nil, nil, true);
}
@end
