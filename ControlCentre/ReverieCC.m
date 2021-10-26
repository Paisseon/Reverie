#import "ReverieCC.h"

@implementation ReverieCC
- (UIImage *) iconGlyph {return [UIImage systemImageNamed:@"moon.zzz.fill"];}

- (UIColor *) selectedColor {return [UIColor clearColor];}

- (bool) isSelected {return selected;}

- (void) setSelected: (bool) arg0 {
  selected = arg0;
  [super refreshState];
  if (selected) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reverieSleepNoti" object:nil];
    [self setSelected:false];
  }
}
@end