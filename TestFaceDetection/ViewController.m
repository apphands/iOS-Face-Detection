//
//  ViewController.m
//  TestFaceDetection
//
//  Created by Randy on 9/9/13.
//  Copyright (c) 2013 Randy Edmonds, AppHands.com. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property(nonatomic,strong) IBOutlet UIImageView *theImageView;
@property(nonatomic,strong) UIView *theFaceFeaturesView;
@end

@implementation ViewController

-(IBAction)chooseImage
{
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imgPicker.delegate = self;
    [self presentViewController:imgPicker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage* photo = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.theImageView.image = photo;
    
    // Scale and Crop the image so that it is same resolution as the UIImageView
    // This keeps us from having to deal with coordinate system differences. 
    self.theImageView.image = [self imageByScalingAndCroppingForSize:self.theImageView.frame.size];
    
    // Add UIView that will contain the facial features,
    // this makes it easier to deal with the Core Image coordinate system,
    // as we can simply flip the view.
    [self.theFaceFeaturesView removeFromSuperview];
    self.theFaceFeaturesView = [[UIView alloc] initWithFrame:self.theImageView.frame];
    [self.view addSubview:self.theFaceFeaturesView];
    self.theFaceFeaturesView.transform = CGAffineTransformMakeScale(1, -1);
    
    [self performSelector:@selector(findFaces) withObject:nil afterDelay:0];
}


-(void)findFaces
{
    CIImage* image = [CIImage imageWithCGImage:self.theImageView.image.CGImage];
    
    // Create a face detector, use the high accuracy detector
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    
    
    
    // Create an array containing all the detected faces.
    // Take in account the image's orientation.
    NSArray* faces = [detector featuresInImage:image
                                       options:@{CIDetectorImageOrientation:[self getEXIFOrientation]}];
    

    // Loop though each detected face
    for(CIFaceFeature* faceFeature in faces)
    {
        // Create a red box around the face
        UIView* faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        [self.theFaceFeaturesView addSubview:faceView];
        
        // Get the width of the face, to be used for scaling eye and mouth boxes
        float faceWidth = faceFeature.bounds.size.width;
        
        if(faceFeature.hasLeftEyePosition)
        {
            UIView* leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.leftEyePosition.x-faceWidth*0.15,
                                                                           faceFeature.leftEyePosition.y-faceWidth*0.15,
                                                                           faceWidth*0.3,
                                                                           faceWidth*0.3)];
            [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
            [leftEyeView setCenter:faceFeature.leftEyePosition];
            leftEyeView.layer.cornerRadius = faceWidth*0.15; // makes it round
            [self.theFaceFeaturesView addSubview:leftEyeView];
        }
        
        if(faceFeature.hasRightEyePosition)
        {
            UIView* leftEye = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.rightEyePosition.x-faceWidth*0.15,
                                                                       faceFeature.rightEyePosition.y-faceWidth*0.15,
                                                                       faceWidth*0.3,
                                                                       faceWidth*0.3)];
            [leftEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
            [leftEye setCenter:faceFeature.rightEyePosition];
            leftEye.layer.cornerRadius = faceWidth*0.15; // makes it round
            [self.theFaceFeaturesView addSubview:leftEye];
        }
        
        if(faceFeature.hasMouthPosition)
        {
            UIView* mouth = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.mouthPosition.x-faceWidth*0.2,
                                                                     faceFeature.mouthPosition.y-faceWidth*0.2,
                                                                     faceWidth*0.4,
                                                                     faceWidth*0.4)];
            [mouth setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.3]];
            [mouth setCenter:faceFeature.mouthPosition];
            mouth.layer.cornerRadius = faceWidth*0.2; // makes it round
            [self.theFaceFeaturesView addSubview:mouth];
        }
    }
}


#pragma mark - Utilities

-(NSNumber*)getEXIFOrientation
{
    int exifOrientation;
    switch (self.theImageView.image.imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }
    return [NSNumber numberWithInt:exifOrientation];
}

-(UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = self.theImageView.image;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
	{
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
		{
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
		}
        else
            if (widthFactor < heightFactor)
			{
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
			}
	}
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) 
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

@end
