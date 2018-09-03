#import "UIImage+PaletteUtils.h"
#import "Palette.h"

#define __CF_SCOPE_CONCATENATE_IMPL(s1, s2) s1##s2
#define __CF_SCOPE_CONCATENATE(s1, s2) __CF_SCOPE_CONCATENATE_IMPL(s1, s2)

inline static void CF_ExecuteCleanup(CFTypeRef *pref) {
    CFTypeRef ref = *pref;
    if (ref) {
        CFRelease(ref);
    }
}

#define CF_SCOPE_RELEASE(ref) \
    CFTypeRef __CF_SCOPE_CONCATENATE(RELEASE, __LINE__) __attribute__((cleanup(CF_ExecuteCleanup), unused)) = ref;

////////////////////////////////////////////////////////////////////////////////////////
static uint32_t *allocRawPixelsFromImage(UIImage *image, size_t *pixelCount) {
    NSInteger width = CGImageGetWidth(image.CGImage);
    NSInteger height = CGImageGetHeight(image.CGImage);
    NSInteger bytesLength = width * height * 4;
    uint32_t *pixels = (uint32_t *)malloc(bytesLength);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CF_SCOPE_RELEASE(colorSpace);

    CGContextRef context =
        CGBitmapContextCreate((void *)pixels, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    *pixelCount = width * height;
    return pixels;
}

static void imageDataReleaseCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

static CGImageRef createRefWithPixels(const uint32_t *pixels, bool needFreePixels, NSInteger width, NSInteger height) {
    void *buffer = (void *)pixels;
    NSInteger bufferLength = width * height * 4;
    CGDataProviderReleaseDataCallback releaseDataCallBack = needFreePixels ? imageDataReleaseCallback : NULL;

    // 设置Bitmap信息
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, releaseDataCallBack);
    CF_SCOPE_RELEASE(provider);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CF_SCOPE_RELEASE(colorSpaceRef);

    // 创建Bitmap图片
    return CGImageCreate(width,
                         height,
                         8,
                         32,
                         4 * (int)width,
                         colorSpaceRef,
                         (CGBitmapInfo)kCGImageAlphaPremultipliedLast,
                         provider,
                         NULL,
                         NO,
                         kCGRenderingIntentDefault);
}

static uint32_t remapColor(uint32_t src, const uint32_t *begin, const uint32_t *end) {
    const int kMaxLen = 256 * 256 * 3;
    int smallLen = kMaxLen;
    uint32_t closestColor = src;
    const uint8_t *srcBytes = (uint8_t *)&src;

    for (const uint32_t *p = begin; p != end; p++) {
        uint8_t *dstBytes = (uint8_t *)p;
        int dr = (int)dstBytes[0] - (int)srcBytes[0];
        int dg = (int)dstBytes[1] - (int)srcBytes[1];
        int db = (int)dstBytes[2] - (int)srcBytes[2];

        int len = dr * dr + dg * dg + db * db;
        if (len == 0) {
            closestColor = *p;
            smallLen = len;
            break;
        }

        if (len < smallLen) {
            closestColor = *p;
            smallLen = len;
        }
    }

    assert(smallLen < kMaxLen);
    ((uint8_t *)&closestColor)[3] = srcBytes[3]; // alpha
    return closestColor;
}

static uint32_t fromColor(UIColor *color) {
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];

    uint32_t ret;
    uint8_t *ptr = (uint8_t *)&ret;
    ptr[0] = r * 255.0;
    ptr[1] = g * 255.0;
    ptr[2] = b * 255.0;
    ptr[3] = a * 255.0;
    return ret;
}

@implementation UIImage (PaletteUtils)

- (nonnull NSArray<UIColor *> *)palette_medianCutMaxColors:(NSInteger)maxColors {
    size_t pixelCount = 0;
    uint32_t *pixels = allocRawPixelsFromImage(self, &pixelCount);

    NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:maxColors];

    palette::Palette palette(pixels, pixelCount);
    palette.medianCut(maxColors, [&](const palette::Cube &cube) {
        uint32_t rgba = cube.getAverageRGBA();
        uint8_t *ptr = (uint8_t *)&rgba;
        UIColor *color = [UIColor colorWithRed:ptr[0] / 255.0 green:ptr[1] / 255.0 blue:ptr[2] / 255.0 alpha:1.0];
        [colors addObject:color];
    });

    free(pixels);
    return colors;
}

- (nonnull UIImage *)palette_remapColors:(nonnull NSArray<UIColor *> *)colors {
    const NSInteger colorCount = colors.count;
    uint32_t table[colorCount];
    for (NSInteger idx = 0; idx < colorCount; idx++) {
        table[idx] = fromColor(colors[idx]);
    }

    size_t pixelCount = 0;
    uint32_t *pixels = allocRawPixelsFromImage(self, &pixelCount);
    uint32_t *tableEnd = table + colors.count;
    for (size_t i = 0; i < pixelCount; i++) {
        pixels[i] = remapColor(pixels[i], table, tableEnd);
    }

    CGImageRef imageRef =
        createRefWithPixels(pixels, YES, CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage));
    CF_SCOPE_RELEASE(imageRef);
    return [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
}

@end
