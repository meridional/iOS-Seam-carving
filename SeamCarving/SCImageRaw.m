//
//  SCImageRaw.m
//  
//
//  Created by Ye Ji on 9/28/13.
//
//

#import "SCImageRaw.h"

@interface SCPixelValue ()
@property (nonatomic) UInt8 r;
@property (nonatomic) UInt8 g;
@property (nonatomic) UInt8 b;
@end

CFDataRef CopyImagePixels(CGImageRef inImage) {
    return CGDataProviderCopyData(CGImageGetDataProvider(inImage));
}
@implementation SCPixelValue

@end

@interface SCImageRaw ()
@property (strong, nonatomic) UIImage *image;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic) const UInt8 *pointer;
@property (nonatomic) double *grayscale;
@property (nonatomic) double *gradient;
@property (nonatomic) CFDataRef data;
@end

typedef struct {
    double sofar;
    int direction;
}CarveCache;

@implementation SCImageRaw
- (id)initWithImage:(UIImage *)image {
    self = [super init];
    self.image = image;
    self.width = image.size.width;
    self.height = image.size.height;
    CGImageRef imgRef = [image CGImage];
    CFDataRef data = CopyImagePixels(imgRef);
    //printf("bitmap: %d\n", CGImageGetBitmapInfo(imgRef));
    printf("%ld\n", CFDataGetLength(data));
    self.pointer = CFDataGetBytePtr(data);
    self.data = data;
    [self buildGrayScale];
    [self buildGradient];
    return self;
}

- (void)buildGrayScale {
    self.grayscale = malloc(sizeof(double) * self.width * self.height);
    int i;
    int j;
    for (i = 0; i < self.height; i++) {
        for (j = 0; j < self.width; j++) {
            double *this = self.grayscale + i * self.width + j;
            const UInt8 *rgb = [self rgbPointerAtRow:i column:j];
            *this = 0.33 * rgb[0] + 0.59 * rgb[1] + 0.11 * rgb[2];
        }
    }
}

- (void)buildGradient {
    self.gradient =malloc(sizeof(double) * self.width * self.height);
    int i;
    int j;
    for (i = 1; i < self.height - 1; i++) {
        for (j = 1; j < self.width - 1; j++) {
            double *this = self.gradient + i * self.width + j;
            *this = abs([self grayAtRow:(i - 1) column:j] - [self grayAtRow:(i+1) column:j])
                + abs([self grayAtRow:i column:j-1] - [self grayAtRow:i column:j+1]);
        }
    }
    i = 0;
    for (j = 1; j < self.width - 1; j++) {
        double *this = self.gradient + i * self.width + j;
        *this = abs([self grayAtRow:i column:j] - [self grayAtRow:(i+1) column:j]) * 0.5
        + abs([self grayAtRow:i column:j-1] - [self grayAtRow:i column:j+1]);
    }
    i = self.height - 1;
    for (j = 1; j < self.width - 1; j++) {
        double *this = self.gradient + i * self.width + j;
        *this = abs([self grayAtRow:i column:j] - [self grayAtRow:(i-1) column:j]) * 0.5
        + abs([self grayAtRow:i column:j-1] - [self grayAtRow:i column:j+1]);
    }
    j = 0;
    for (i = 1; i < self.height - 1; i++) {
        double *this = self.gradient + i * self.width + j;
        *this = abs([self grayAtRow:i+1 column:j] - [self grayAtRow:(i-1) column:j])
        + abs([self grayAtRow:i column:j] - [self grayAtRow:i column:j+1]) * 0.5;
    }
    j = self.width - 1;
    for (i = 1; i < self.height - 1; i++) {
        double *this = self.gradient + i * self.width + j;
        *this = abs([self grayAtRow:i+1 column:j] - [self grayAtRow:(i-1) column:j])
        + abs([self grayAtRow:i column:j-1] - [self grayAtRow:i column:j]) * 0.5;
    }
    
    // corner cases
    
    i = 0; j = 0;
    double *this = self.gradient + i * self.width + j;
    *this = abs([self grayAtRow:i+1 column:j] - [self grayAtRow:(i) column:j]) * 0.5
        + abs([self grayAtRow:i column:j+1] - [self grayAtRow:i column:j]) * 0.5;
    
    i = 0; j = self.width - 1;
    this = self.gradient + i * self.width + j;
    *this = abs([self grayAtRow:i+1 column:j] - [self grayAtRow:(i) column:j]) * 0.5
        + abs([self grayAtRow:i column:j-1] - [self grayAtRow:i column:j]) * 0.5;
    
    i = self.height - 1; j = 0;
    this = self.gradient + i * self.width + j;
    *this = abs([self grayAtRow:i-1 column:j] - [self grayAtRow:(i) column:j]) * 0.5
        + abs([self grayAtRow:i column:j+1] - [self grayAtRow:i column:j]) * 0.5;
    
    i = self.height - 1; j = self.width - 1;
    this = self.gradient + i * self.width + j;
    *this = abs([self grayAtRow:i-1 column:j] - [self grayAtRow:(i) column:j]) * 0.5
        + abs([self grayAtRow:i column:j-1] - [self grayAtRow:i column:j]) * 0.5;
}

- (double)gradientAtRow:(NSInteger)i column:(NSInteger)j {
    return *(self.gradient + i * self.width + j);

}

- (double)grayAtRow:(NSInteger)i column:(NSInteger)j {
    return *(self.grayscale + i * self.width + j);
}

- (const UInt8 *)rgbPointerAtRow:(NSInteger)i column:(NSInteger)j {
    return self.pointer + 4 * i * self.width + 4 * j;
}

- (SCPixelValue *)pixelAtRow:(NSInteger)row
                      column:(NSInteger)column {
    SCPixelValue *pixel = [[SCPixelValue alloc] init];
    const UInt8 *ptr = self.pointer + 4 * row * self.width + 4 * column;
    pixel.r = ptr[0];
    pixel.g = ptr[1];
    pixel.b = ptr[2];
    return pixel;
}

- (UIImage *)carve {
    CarveCache *cache[2000];
    for (int i = 0; i < 2000; i++) {
        cache[i] = malloc(sizeof(CarveCache) * 2000);
        //assert(cache[i]);
    }
//    return nil;
    int i;
    int j;
    for (j = 0; j < self.width; j++) {
        cache[0][j].sofar = [self gradientAtRow:0 column:j];
    }
    for (i = 1; i < self.height; i++) {
        for (j = 1; j < self.width - 1; j++) {
            int d = 0;
            int ii;
            double thisG =[self gradientAtRow:i column:j];
            double best = cache[i - 1][j].sofar + [self gradientAtRow:i column:j];
            for (ii = -1; ii <= 1; ii += 2) {
                double t =cache[i-1][j+ii].sofar  + thisG;
                if (t < best) {
                    best = t;
                    d = ii;
                }
            }
            cache[i][j].sofar = best;
            cache[i][j].direction = d;
        }
        {
            j = 0;
            int ii;
            int d = 0;
            double thisG =[self gradientAtRow:i column:j];
            double best = cache[i - 1][j].sofar + [self gradientAtRow:i column:j];
            for (ii = 1; ii <= 1; ii += 2) {
                double t =cache[i-1][j+ii].sofar  + thisG;
                if (t < best) {
                    best = t;
                    d = ii;
                }
            }
            cache[i][j].sofar = best;
            cache[i][j].direction = d;
        }
        {
            int d = 0;
            j = self.width - 1;
            double thisG =[self gradientAtRow:i column:j];
            double best = cache[i - 1][j].sofar + [self gradientAtRow:i column:j];
            int ii;
            for (ii = -1; ii <= -1; ii += 2) {
                double t =cache[i-1][j+ii].sofar  + thisG;
                if (t < best) {
                    best = t;
                    d = ii;
                }
            }
            cache[i][j].sofar = best;
            cache[i][j].direction = d;
        }
    }
    int *carved = malloc(sizeof(int) * 2000);
    i = self.height - 1;
    double best = cache[i][0].sofar;
    carved[i] = 0;
    for (j = 0; j < self.width; j++) {
        if (cache[i][j].sofar < best) {
            best = cache[i][j].sofar;
            carved[i] = j;
        }
    }
    for (i = self.height - 2; i >= 0; i--) {
        carved[i] = cache[i+1][carved[i + 1]].direction + carved[i+1];
    }
    UInt8 *rawBytes;
    rawBytes = malloc(sizeof(UInt8) * 2000 * 2000 * 4);
    UInt8 *inputPtr = rawBytes;
    const UInt8 *originPtr = self.pointer;
    for (i = 0; i < self.height; i++) {
        for (j = 0; j < self.width; j++, originPtr += 4) {
            if (carved[i] == j) {
               // printf("%d\n", j);
                continue;
            }
            inputPtr[0] = originPtr[0];
            inputPtr[1] = originPtr[1];
            inputPtr[2] = originPtr[2];
            inputPtr[3] = originPtr[3];
            inputPtr += 4;
        }
    }
    CFDataRef rawData = CFDataCreate(NULL, rawBytes, (self.width - 1) * 4 * (self.height));
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rawData);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(self.width - 1, self.height,
                                        8, 32, (self.width - 1) * 4, colorSpace, 5,
                                        provider, NULL, NO,
                                        kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *carvedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    free(carved);
    for (i = 0; i < 2000; i++) {
        free(cache[i]);
    }
    free(rawBytes);
    CFRelease(rawData);
    CGDataProviderRelease(provider);
    printf("done\n");
    return carvedImage;
}

- (void)dealloc {
    if (self.gradient) {
        free(self.gradient);
    }
    if (self.grayscale) {
        free(self.grayscale);
    }
    CFRelease(self.data);
}

@end
