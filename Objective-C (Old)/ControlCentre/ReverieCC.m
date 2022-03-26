#import "ReverieCC.h"

@implementation UIImage (Reverie)
+ (UIImage*) initWithImage: (UIImage*) arg0 withSize: (CGSize) arg1 {
	UIGraphicsImageRenderer* renderer = [[UIGraphicsImageRenderer alloc] initWithSize:arg1];
	UIImage* logo = [renderer imageWithActions:^(UIGraphicsImageRendererContext* _Nonnull context) {
		[arg0 drawInRect:CGRectMake(0, 0, arg1.height, arg1.width)];
	  }];
	renderer = NULL;
	return logo;
}
@end

@implementation ReverieCC
- (UIImage *) iconGlyph {
	return [UIImage initWithImage:[UIImage systemImageNamed:@"moon.zzz.fill"] withSize:CGSizeMake(36, 36)];
}

- (UIColor *) selectedColor {return [UIColor clearColor];}

- (bool) isSelected {return selected;}

- (void) setSelected: (bool) arg0 {
	selected = arg0;
	[super refreshState];
	if (selected) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"reverieSleepNoti" object:NULL];
		[self setSelected:false];
	}
}
@end