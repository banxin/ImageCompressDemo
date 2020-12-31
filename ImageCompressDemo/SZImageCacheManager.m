//
//  SZImageCacheManager.m
//  ImageCompressDemo
//
//  Created by 山竹 on 2019/6/20.
//  Copyright © 2019 SHANZHU. All rights reserved.
//

#import "SZImageCacheManager.h"
#import <YYKit/YYCache.h>

// 创建 YYCache 的标识
static NSString * const SZImageCacheManagerCacheIdentifier = @"SZImageCacheManagerCacheIdentifier";

@interface SZImageCacheManager ()

@property (nonatomic, strong) YYCache *yyCache;

@end

@implementation SZImageCacheManager

- (BOOL)isCacheWithImageDataUrlString:(NSString *)urlString
{
    return [self.yyCache containsObjectForKey:urlString];
}

- (void)cacheImageWithImageData:(NSData *)imageData andUrlString:(NSString *)urlString
{
    // 根据key写入缓存value
    [self.yyCache setObject:imageData forKey:urlString withBlock:^{
        
        NSLog(@"setObject sucess");
    }];
}

- (NSData *)getImageDataFromCacheWithUrlString:(NSString *)urlString
{
    if (![self isCacheWithImageDataUrlString:urlString]) {
        
        return nil;
    }
    
    return (NSData *)[self.yyCache objectForKey:urlString];
}

@end
