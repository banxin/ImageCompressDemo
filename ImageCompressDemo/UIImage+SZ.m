//
//  UIImage+SZ.m
//  ImageCompressDemo
//
//  Created by 山竹 on 2019/6/20.
//  Copyright © 2019 SHANZHU. All rights reserved.
//

#import "UIImage+SZ.h"

@implementation UIImage (SZ)

#pragma mark - 压缩一张图片 自定义最大宽高
+ (UIImage *)compressImage:(UIImage *)image compressibilityFactor:(CGFloat)compressibilityFactor compressionQuality:(CGFloat)compressionQuality
{
    // 目标图片的原始宽高
    CGFloat oldImg_WID = image.size.width;
    CGFloat oldImg_HEI = image.size.height;
    
    // 如果 宽 或 高，大于 指定的最大宽高
    if (oldImg_WID > compressibilityFactor || oldImg_HEI > compressibilityFactor) {
        
        // 超过设置的最大宽高 先判断那个边最长
        if (oldImg_WID > oldImg_HEI) {
            
            // 宽度大于高度
            // 等比例压缩
            oldImg_HEI = (compressibilityFactor * oldImg_HEI) / oldImg_WID;
            oldImg_WID = compressibilityFactor;
            
        } else {
            
            // 高度大于宽度
            // 等比例压缩
            oldImg_WID = (compressibilityFactor * oldImg_WID) / oldImg_HEI;
            oldImg_HEI = compressibilityFactor;
        }
    }
    
    // 根据 新的 宽高获取新图片
    UIImage *newImg = [self imageWithImage:image scaledToSize:CGSizeMake(oldImg_WID, oldImg_HEI)];
    
    NSData *dJpeg = dJpeg = UIImageJPEGRepresentation(newImg, compressionQuality);
    
    NSLog(@"%@", [NSString stringWithFormat:@"图片压缩后的大小：%zd kb", dJpeg.length / 1000]);
    
    UIImage *resultImage = [UIImage imageWithData:dJpeg];
    
    NSLog(@"%@", [NSString stringWithFormat:@"图片的压缩后尺寸：w：%f h：%f", resultImage.size.width, resultImage.size.height]);
    
    return resultImage;
}

+ (UIImage *)compressImage:(UIImage *)image compressibilityFactor:(CGFloat)compressibilityFactor isNeedCompressQuality:(BOOL)isNeedCompressQuality compressionQuality:(CGFloat)compressionQuality
{
    // 目标图片的原始宽高
    CGFloat oldImg_WID = image.size.width;
    CGFloat oldImg_HEI = image.size.height;
    
    // 如果 宽 或 高，大于 指定的最大宽高
    if (oldImg_WID > compressibilityFactor || oldImg_HEI > compressibilityFactor) {
        
        // 超过设置的最大宽高 先判断那个边最长
        if (oldImg_WID > oldImg_HEI) {
            
            // 宽度大于高度
            // 等比例压缩
            oldImg_HEI = (compressibilityFactor * oldImg_HEI) / oldImg_WID;
            oldImg_WID = compressibilityFactor;
            
        } else {
            
            // 高度大于宽度
            // 等比例压缩
            oldImg_WID = (compressibilityFactor * oldImg_WID) / oldImg_HEI;
            oldImg_HEI = compressibilityFactor;
        }
    }
    
    NSData *dJpeg = nil;
    
    // 如果需要压缩质量，使用 UIImageJPEGRepresentation
    if (isNeedCompressQuality) {
        
        dJpeg = UIImageJPEGRepresentation(image, compressionQuality);
        
    } else {
        
        // 如果只是需要压缩尺寸，保持高清晰度，则使用 UIImagePNGRepresentation
        dJpeg = UIImagePNGRepresentation(image);
    }
    
    NSLog(@"%@", [NSString stringWithFormat:@"图片压缩后的大小：%zd kb", dJpeg.length / 1000]);
    
    UIImage *resultImage = [self compressByImageIOFromData:dJpeg maxPixelSize:MAX(oldImg_WID, oldImg_HEI)];
    
    NSLog(@"%@", [NSString stringWithFormat:@"图片的压缩后尺寸：w：%f h：%f", resultImage.size.width, resultImage.size.height]);
    
    return resultImage;
}

+ (UIImage *)compressByConextWithData:(NSData *)data withMaxPixelSize:(CGFloat)maxPixelSize
{
    UIImage *imgResult = nil;
    if (data == nil) {
        return imgResult;
    }
    if (data.length <= 0) {
        return imgResult;
    }
    if (maxPixelSize <= 0) {
        return imgResult;
    }
    
    const int sizeTo = maxPixelSize; // 图片最大的宽/高
    CGSize sizeResult;
    UIImage *img = [UIImage imageWithData:data];
    if(img.size.width > img.size.height){ // 根据最大的宽/高 值，等比例计算出最终目标尺寸
        float value = img.size.width/ sizeTo;
        int height = img.size.height / value;
        sizeResult = CGSizeMake(sizeTo, height);
    } else {
        float value = img.size.height/ sizeTo;
        int width = img.size.width / value;
        sizeResult = CGSizeMake(width, sizeTo);
    }
    
    UIGraphicsBeginImageContextWithOptions(sizeResult, NO, 0);
    [img drawInRect:CGRectMake(0, 0, sizeResult.width, sizeResult.height)];
    img = nil;
    imgResult = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return imgResult;
}

+ (UIImage *)compressByImgIOWithData:(NSData*)data withMaxPixelSize:(CGFloat)maxPixelSize
{
    UIImage *imgResult = nil;
    if(data == nil)         { return imgResult; }
    if(data.length <= 0)    { return imgResult; }
    if(maxPixelSize <= 0)   { return imgResult; }
    
    const float scale = [UIScreen mainScreen].scale;
    const int sizeTo = maxPixelSize * scale;
    CFDataRef dataRef = (__bridge CFDataRef)data;
    
    /* CGImageSource的键值说明
     kCGImageSourceCreateThumbnailWithTransform - 设置缩略图是否进行Transfrom变换
     kCGImageSourceCreateThumbnailFromImageAlways - 设置是否创建缩略图，无论原图像有没有包含缩略图，默认kCFBooleanFalse，影响 CGImageSourceCreateThumbnailAtIndex 方法
     kCGImageSourceCreateThumbnailFromImageIfAbsent - 设置是否创建缩略图，如果原图像有没有包含缩略图，则创建缩略图，默认kCFBooleanFalse，影响 CGImageSourceCreateThumbnailAtIndex 方法
     kCGImageSourceThumbnailMaxPixelSize - 设置缩略图的最大宽/高尺寸 需要设置为CFNumber值，设置后图片会根据最大宽/高 来等比例缩放图片
     kCGImageSourceShouldCache - 设置是否以解码的方式读取图片数据 默认为kCFBooleanTrue，如果设置为true，在读取数据时就进行解码 如果为false 则在渲染时才进行解码 */
    CFDictionaryRef dicOptionsRef = (__bridge CFDictionaryRef) @{
                                                                 (id)kCGImageSourceCreateThumbnailFromImageIfAbsent : @(YES),
                                                                 (id)kCGImageSourceThumbnailMaxPixelSize : @(sizeTo),
                                                                 (id)kCGImageSourceShouldCache : @(YES),
                                                                 };
    CGImageSourceRef src = CGImageSourceCreateWithData(dataRef, nil);
    // 注意：如果设置 kCGImageSourceCreateThumbnailFromImageIfAbsent为 NO，那么 CGImageSourceCreateThumbnailAtIndex 会返回nil
    CGImageRef thumImg = CGImageSourceCreateThumbnailAtIndex(src, 0, dicOptionsRef);
    
    // 注意释放对象，否则会产生内存泄露
    CFRelease(src);
    
    imgResult = [UIImage imageWithCGImage:thumImg scale:scale orientation:UIImageOrientationUp];
    
    // 注意释放对象，否则会产生内存泄露
    if (thumImg != nil) {
        CFRelease(thumImg);
    }
    
    return imgResult;
}

#pragma mark - 根据宽高压缩图片

// 根据指定size重新画图片
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - 二分法

// 二分法 压缩图片
+ (UIImage *)compressImageQuality:(UIImage *)image toByte:(NSInteger)maxLength
{
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    if (data.length < maxLength) {
        return image;
    }
    CGFloat max = 1;
    CGFloat min = 0;
    // 二分最大10次，区间范围精度最大可达0.00097657；第6次，精度可达0.015625，10次，0.000977
    for (int i = 0; i < 10; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        NSLog(@"%@", [NSString stringWithFormat:@"压缩精度：%f，二分法压缩后的大小：%f", compression, data.length / 1000.0]);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    
    // 如果二分法之后，还是不符合大小
    if (data.length > maxLength) {
        
        UIImage *resultImage = [UIImage imageWithData:data];
        while (data.length > maxLength) {
            @autoreleasepool {
                CGFloat ratio = (CGFloat)maxLength / data.length;
                // 使用NSUInteger不然由于精度问题，某些图片会有白边
                CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                         (NSUInteger)(resultImage.size.height * sqrtf(ratio)));
                // ImageIO 的方式绘图
                resultImage = [self compressByImageIOFromData:data maxPixelSize:MAX(size.width, size.height)];
                // CoreGraphics 的方式绘图
//                resultImage = [self imageWithImage:resultImage scaledToSize:size];
                data = UIImageJPEGRepresentation(resultImage, compression);
                NSLog(@"%@", [NSString stringWithFormat:@"二分法继续压缩后尺寸：w：%f h：%f，二分法继续压缩后的大小：%f", size.width, size.height, data.length / 1000.0]);
            }
        }
    }
    
    NSLog(@"%@", [NSString stringWithFormat:@"质量优先图片压缩后的大小：%f kb", data.length / 1000.0]);
    
    UIImage *resultImage = [UIImage imageWithData:data];
    
    NSLog(@"%@", [NSString stringWithFormat:@"质量优先图片的压缩后尺寸：w：%f h：%f", resultImage.size.width, resultImage.size.height]);
    
    return resultImage;
}

// 根据指定size 使用 ImageIO 重新绘图
+ (UIImage *)compressByImageIOFromData:(NSData *)data maxPixelSize:(NSUInteger)maxPixelSize
{
    UIImage *imgResult = nil;
    
    if (data == nil) {
        return imgResult;
    }
    if (data.length <= 0) {
        return imgResult;
    }
    if (maxPixelSize <= 0) {
        return imgResult;
    }
    
    const float scale = [UIScreen mainScreen].scale;
    const int sizeTo = maxPixelSize * scale;
    CFDataRef dataRef = (__bridge CFDataRef)data;
    
    /* CGImageSource的键值说明
     kCGImageSourceCreateThumbnailWithTransform - 设置缩略图是否进行Transfrom变换
     kCGImageSourceCreateThumbnailFromImageAlways - 设置是否创建缩略图，无论原图像有没有包含缩略图，默认kCFBooleanFalse，影响 CGImageSourceCreateThumbnailAtIndex 方法
     kCGImageSourceCreateThumbnailFromImageIfAbsent - 设置是否创建缩略图，如果原图像有没有包含缩略图，则创建缩略图，默认kCFBooleanFalse，影响 CGImageSourceCreateThumbnailAtIndex 方法
     kCGImageSourceThumbnailMaxPixelSize - 设置缩略图的最大宽/高尺寸 需要设置为CFNumber值，设置后图片会根据最大宽/高 来等比例缩放图片
     kCGImageSourceShouldCache - 设置是否以解码的方式读取图片数据 默认为kCFBooleanTrue，如果设置为true，在读取数据时就进行解码 如果为false 则在渲染时才进行解码 */
    CFDictionaryRef dicOptionsRef = (__bridge CFDictionaryRef) @{
                                                                 (id)kCGImageSourceCreateThumbnailFromImageIfAbsent : @(YES),
                                                                 (id)kCGImageSourceThumbnailMaxPixelSize : @(sizeTo),
                                                                 (id)kCGImageSourceShouldCache : @(YES),
                                                                 };
    CGImageSourceRef src = CGImageSourceCreateWithData(dataRef, nil);
    // 注意：如果设置 kCGImageSourceCreateThumbnailFromImageIfAbsent为 NO，那么 CGImageSourceCreateThumbnailAtIndex 会返回nil
    CGImageRef thumImg = CGImageSourceCreateThumbnailAtIndex(src, 0, dicOptionsRef);
    
    CFRelease(src); // 注意释放对象，否则会产生内存泄露
    
    imgResult = [UIImage imageWithCGImage:thumImg scale:scale orientation:UIImageOrientationUp];
    
    if (thumImg != nil) {
        // 注意释放对象，否则会产生内存泄露
        CFRelease(thumImg);
    }
    
    return imgResult;
}

//extension UIImage {
//
//    //ImageIO
//    func resizeIO(size:CGSize) -> UIImage? {
//
//        guard let data = UIImagePNGRepresentation(self) else { return nil }
//
//        let maxPixelSize = max(size.width, size.height)
//
//        //let imageSource = CGImageSourceCreateWithURL(url, nil)
//        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
//
//        //kCGImageSourceThumbnailMaxPixelSize为生成缩略图的大小。当设置为800，如果图片本身大于800*600，则生成后图片大小为800*600，如果源图片为700*500，则生成图片为800*500
//        let options: [NSString: Any] = [
//                                        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
//                                        kCGImageSourceCreateThumbnailFromImageAlways: true
//                                        ]
//
//        let resizedImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary).flatMap{
//            UIImage(cgImage: $0)
//        }
//        return resizedImage
//    }
//}


+ (UIImage *)compressImageQualityNormal:(UIImage *)image toByte:(NSInteger)maxLength
{
    CGFloat compression = 1;
    NSUInteger count = 0;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    while (data.length > maxLength && compression > 0) {
        compression -= 0.01;
        count++;
        // 当压缩到某个阈值的时候，这句代码就没有效果了
        data = UIImageJPEGRepresentation(image, compression);
        NSLog(@"%@", [NSString stringWithFormat:@"压缩次数：%zd，压缩比例：%f，压缩后的图片大小：%f kb", count, compression, data.length / 1000.0]);
    }
    
    UIImage *resultImage = [UIImage imageWithData:data];
    return resultImage;
}

+ (UIImage *)compressImageQualityDichotomy:(UIImage *)image toByte:(NSInteger)maxLength
{
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    if (data.length < maxLength) return image;
    CGFloat max = 1;
    CGFloat min = 0;
    // 二分最大10次，区间范围精度最大可达0.00097657；第6次，精度可达0.015625，10次，0.000977
    for (int i = 0; i < 10; ++i) {
        compression = (max + min) / 2;
        NSLog(@"%@", [NSString stringWithFormat:@"压缩精度：%f", compression]);
        data = UIImageJPEGRepresentation(image, compression);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    UIImage *resultImage = [UIImage imageWithData:data];
    return resultImage;
}

@end
