#import "ViewController.h"
#import "UIImage+PaletteUtils.h"

static UIImage *imageFromColor(UIColor *color, CGSize imageSize) {
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static NSInteger kMaxColors[] = {2, 4, 8, 16, 32, 64, 128, 256};
typedef NS_ENUM(NSInteger, ImageMode) {
    ImageModeOriginal,
    ImageModeRemap,
};

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@interface ColorButton : UIButton {
}
@property (nonatomic, strong) UIColor *color;
@end

@implementation ColorButton

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    return self.bounds;
}

@end

@implementation ViewController {
    UIScrollView *_scrollView;
    UIImageView *_imageView;
    UIImage *_originalImage;
    UIImage *_remapedImage;
    NSMutableArray<UIView *> *_colorButtons;
    UIBarButtonItem *_moreColorsButtonItem;
    UIBarButtonItem *_lessColorsButtonItem;
    NSInteger _maxColorIndex;
    ImageMode _imageMode;
}

- (void)loadView {
    UIView *aView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = aView;
    aView.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _imageMode = ImageModeOriginal;
    _scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:_scrollView];

    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_imageView];

    _colorButtons = [[NSMutableArray alloc] init];

    self.title = @"Original Image";
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"Choose"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(chooseAnImageButtonPressed:)];
    self.navigationItem.rightBarButtonItem = buttonItem;

    _moreColorsButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"More Colors"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(moreColorsButtonPressed:)];

    _lessColorsButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Less Colors"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(lessColorsButtonPressed:)];
    self.toolbarItems = @[
        _lessColorsButtonItem,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        _moreColorsButtonItem
    ];

    UITapGestureRecognizer *tapGecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapImageViewHappen:)];
    [_imageView addGestureRecognizer:tapGecognizer];
    _maxColorIndex = 3;

    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.jpeg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    _originalImage = image;
    [self doMedianCutMaxColors:kMaxColors[_maxColorIndex]];
}

- (CGFloat)doLayoutColorImageViews:(CGFloat)yPos {
    const CGSize viewSize = CGSizeMake(44, 44);
    const CGFloat boundsWidth = self.view.bounds.size.width;

    CGFloat xSpace = 20;
    const NSInteger eachInRow = (boundsWidth - xSpace) / (viewSize.width + xSpace);
    xSpace = (boundsWidth - viewSize.width * eachInRow) / (eachInRow + 1);

    CGFloat xPos = xSpace;
    yPos += xSpace;

    for (UIView *aView in _colorButtons) {
        if (xPos + viewSize.width > boundsWidth) {
            xPos = xSpace;
            yPos += (xSpace + viewSize.height);
        }

        aView.frame = CGRectMake(xPos, yPos, viewSize.width, viewSize.height);
        xPos += (xSpace + viewSize.width);
    }
    yPos += xSpace;
    yPos += 44;
    return yPos;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _scrollView.frame = self.view.bounds;
    CGRect rt = self.view.bounds;
    rt.size.height = MIN(rt.size.width, rt.size.height * 0.5);
    _imageView.frame = rt;
    CGFloat yPos = [self doLayoutColorImageViews:CGRectGetMaxY(_imageView.frame)];
    _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yPos);
}

- (void)chooseAnImageButtonPressed:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = false;
    [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)moreColorsButtonPressed:(id)sender {
    NSInteger arraySize = sizeof(kMaxColors) / sizeof(kMaxColors[0]);
    if (_maxColorIndex + 1 < arraySize) {
        _maxColorIndex = _maxColorIndex + 1;
        [self doMedianCutMaxColors:kMaxColors[_maxColorIndex]];
        _lessColorsButtonItem.enabled = YES;
        _moreColorsButtonItem.enabled = !(_maxColorIndex == arraySize - 1);
    }
}

- (void)lessColorsButtonPressed:(id)sender {
    if (_maxColorIndex - 1 >= 0) {
        _maxColorIndex = _maxColorIndex - 1;
        [self doMedianCutMaxColors:kMaxColors[_maxColorIndex]];
        _moreColorsButtonItem.enabled = YES;
        _lessColorsButtonItem.enabled = !(_maxColorIndex == 0);
    }
}

- (void)colorButtonPressed:(ColorButton *)sender {
    CGFloat r, g, b, a;
    [sender.color getRed:&r green:&g blue:&b alpha:&a];

    NSInteger r8 = r * 255.0;
    NSInteger g8 = g * 255.0;
    NSInteger b8 = b * 255.0;
    NSString *title = [NSString stringWithFormat:@"Color: #%02x%02x%02x", (int)r8, (int)g8, (int)b8];

    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:action];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)doUpdateImageViewColorCount:(NSInteger)colorCount {
    if ((_imageMode == ImageModeRemap) && _remapedImage) {
        _imageView.image = _remapedImage;
        self.title = [NSString stringWithFormat:@"Remap Colors(%d)", (int)colorCount];
    } else if ((_imageMode == ImageModeOriginal) && _originalImage) {
        _imageView.image = _originalImage;
        self.title = @"Original Image";
    }
}

- (void)singleTapImageViewHappen:(id)sender {
    _imageMode = (_imageMode == ImageModeRemap) ? ImageModeOriginal : ImageModeRemap;
    [self doUpdateImageViewColorCount:_colorButtons.count];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];

    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (![image isKindOfClass:[UIImage class]]) {
        return;
    }
    _originalImage = image;
    [self doMedianCutMaxColors:kMaxColors[_maxColorIndex]];
}

- (void)doMedianCutMaxColors:(NSInteger)maxColors {
    UIImage *image = _originalImage;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *colors = [image palette_medianCutMaxColors:maxColors];
        colors = [colors sortedArrayUsingComparator:^NSComparisonResult(UIColor *color0, UIColor *color1) {
            CGFloat r0, g0, b0, a0;
            CGFloat r1, g1, b1, a1;
            [color0 getRed:&r0 green:&g0 blue:&b0 alpha:&a0];
            [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];

            return (r0 + g0 + b0) < (r1 + g1 + b1) ? NSOrderedAscending : NSOrderedDescending;
        }];

        NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:colors.count];
        for (UIColor *color in colors) {
            [images addObject:imageFromColor(color, CGSizeMake(8, 8))];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishGotColorImages:images colors:colors];
        });

        UIImage *rempaedImage = [image palette_remapColors:colors];
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_remapedImage = rempaedImage;
            [self doUpdateImageViewColorCount:colors.count];
        });
    });
}

- (void)finishGotColorImages:(NSArray *)images colors:(NSArray *)colors {
    for (UIView *aView in _colorButtons) {
        [aView removeFromSuperview];
    }
    [_colorButtons removeAllObjects];

    NSInteger idx = 0;
    for (UIImage *image in images) {
        ColorButton *button = [[ColorButton alloc] init];
        button.color = colors[idx++];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(colorButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:button];
        [_colorButtons addObject:button];
    }
    CGFloat yPos = [self doLayoutColorImageViews:CGRectGetMaxY(_imageView.frame)];
    _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yPos);
}

@end
