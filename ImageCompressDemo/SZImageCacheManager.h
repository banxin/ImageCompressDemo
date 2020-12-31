//
//  SZImageCacheManager.h
//  ImageCompressDemo
//
//  Created by 山竹 on 2019/6/20.
//  Copyright © 2019 SHANZHU. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SZImageCacheManager : NSObject

/**
 是否缓存了该 url 的图片
 
 @param urlString 图片 url
 @return 是否
 */
- (BOOL)isCacheWithImageDataUrlString:(NSString *)urlString;

/**
 缓存图片
 
 @param imageData 图片
 @param urlString 图片 url
 */
- (void)cacheImageWithImageData:(NSData *)imageData andUrlString:(NSString *)urlString;

/**
 根据 图片 url 获取图片
 
 @param urlString 图片 url
 @return 缓存了的 image
 */
- (NSData *)getImageDataFromCacheWithUrlString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
