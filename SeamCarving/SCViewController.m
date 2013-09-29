//
//  SCViewController.m
//  SeamCarving
//
//  Created by Ye Ji on 9/28/13.
//  Copyright (c) 2013 hackNY. All rights reserved.
//

#import "SCViewController.h"
#import "SCImageRaw.h"

@interface SCViewController ()
@property (nonatomic, strong) SCImageRaw *imgRaw;
@property (nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation SCViewController
- (IBAction)carve:(id)sender {
    int i;
    UIImage *s;
    for (i = 0; i < 100; i++) {
        s = [self.imgRaw carve];
        self.image = s;
    }
}

- (void)setImage:(UIImage *)image {
    _image = image;
    self.imgRaw = [[SCImageRaw alloc] initWithImage:image];
    self.imageView.image = image;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.image = [UIImage imageNamed:@"castle"];
    //self.imgRaw = [[SCImageRaw alloc] initWithImage:self.image];
    [self printVal];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)printVal {
   // SCPixelValue *pixel = [self.imgRaw pixelAtRow:1 column:1];
   // printf("%u %u %u\n", pixel.r, pixel.g, pixel.b);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
