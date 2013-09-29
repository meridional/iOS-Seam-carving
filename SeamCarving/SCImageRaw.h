//
//  SCImageRaw.h
//  
//
//  Created by Ye Ji on 9/28/13.
//
//

#import <Foundation/Foundation.h>
@class SCPixelValue;
@interface SCImageRaw : NSObject
- (id)initWithImage:(UIImage *)image;
- (SCPixelValue *)pixelAtRow:(NSInteger)row column:(NSInteger)column;
- (UIImage *)carve;
@end

@interface SCPixelValue : NSObject
@property (readonly,nonatomic) UInt8 r;
@property (readonly,nonatomic) UInt8 g;
@property (readonly,nonatomic) UInt8 b;
@end
