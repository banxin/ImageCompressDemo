//
//  UIImage+SZ.h
//  ImageCompressDemo
//
//  Created by 山竹 on 2019/6/20.
//  Copyright © 2019 SHANZHU. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SZ)

#pragma mark - 压缩图片的宽或高到指定值的方法 传入 image

/**
 压缩图片的宽或高到指定值（使用 UIGraphics 绘图）

 @param image 目标图片
 @param compressibilityFactor 指定最大宽高
 @param compressionQuality    压缩比例（0 ~ 1）取值
 @return 压缩后的图片
 */
+ (UIImage *)compressImage:(UIImage *)image compressibilityFactor:(CGFloat)compressibilityFactor compressionQuality:(CGFloat)compressionQuality;

/**
 压缩图片的宽或高到指定值（使用 ImageIO 绘图） -- 推荐 --
 
 @param image 目标图片
 @param compressibilityFactor 指定最大宽高
 @param isNeedCompressQuality 是否需要压缩质量
 @param compressionQuality    需要压缩比例的时候才生效，压缩比例（0 ~ 1）取值
 @return 压缩后的图片
 */
+ (UIImage *)compressImage:(UIImage *)image compressibilityFactor:(CGFloat)compressibilityFactor isNeedCompressQuality:(BOOL)isNeedCompressQuality compressionQuality:(CGFloat)compressionQuality;

#pragma mark - 传入NSdata ~~~

/**
 压缩图片的宽或高到指定值（使用 UIGraphics 绘图）

 @param data         目标图片Data
 @param maxPixelSize 指定最大宽高
 @return 压缩后的图片
 */
+ (UIImage *)compressByConextWithData:(NSData *)data withMaxPixelSize:(CGFloat)maxPixelSize;

/**
 压缩图片的宽或高到指定值（使用 ImageIO 绘图） -- 推荐 --

 @param data         目标图片Data
 @param maxPixelSize 指定最大宽高
 @return 压缩后的图片
 */
+ (UIImage *)compressByImgIOWithData:(NSData *)data withMaxPixelSize:(CGFloat)maxPixelSize;

#pragma mark - 压缩图片到指定大小的方法

/**
 压缩图片到指定大小（先压缩质量，如果还是达不到，再压缩宽高） -- 推荐 --

 @param image 目标图片
 @param maxLength 需要压缩到的byte值
 @return 压缩后的图片
 */
+ (UIImage *)compressImageQuality:(UIImage *)image toByte:(NSInteger)maxLength;

#pragma mark - 仅压缩质量的方法

/**
 单纯循环压缩质量

 @param image 目标图片
 @param maxLength 需要压缩到的byte值
 @return 压缩后的图片
 */
+ (UIImage *)compressImageQualityNormal:(UIImage *)image toByte:(NSInteger)maxLength;

/**
 二分法压缩图片质量  -- 推荐 --

 @param image 目标图片
 @param maxLength 需要压缩到的byte值
 @return 压缩后的图片
 */
+ (UIImage *)compressImageQualityDichotomy:(UIImage *)image toByte:(NSInteger)maxLength;

@end

NS_ASSUME_NONNULL_END
