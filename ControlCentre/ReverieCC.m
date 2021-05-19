#import "ReverieCC.h"

@implementation ReverieCC
- (UIImage *) iconGlyph {return [UIImage imageNamed:@"toggleIcon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];}

- (UIColor *) selectedColor {return [UIColor clearColor];}

- (BOOL) isSelected {return selected;}

- (void) setSelected: (BOOL) arg1 {
  selected = arg1;
  [super refreshState];
  if (selected) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reveriePrefsNoti" object:nil];
    [self setSelected:0];
  }
}
@end