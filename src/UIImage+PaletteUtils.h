#import <UIKit/UIKit.h>

@interface UIImage (PaletteUtils)

- (nonnull NSArray<UIColor *> *)palette_medianCutMaxColors:(NSInteger)maxColors;
- (nonnull UIImage *)palette_remapColors:(nonnull NSArray<UIColor *> *)colors;

@end
