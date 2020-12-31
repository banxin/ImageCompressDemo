//
//  ViewController.m
//  ImageCompressDemo
//
//  Created by 山竹 on 2019/6/20.
//  Copyright © 2019 SHANZHU. All rights reserved.
//

#import "ViewController.h"

#import "SZImageCacheManager.h"
#import "UIImage+SZ.h"

#import <sys/sysctl.h>
#import <mach/mach.h>
#import <malloc/malloc.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.image.image = [UIImage imageWithData:[self fetchOriginImageData]];
}

#pragma mark - IBAction

- (IBAction)compressSizeFirst:(id)sender
{
//    [self handleCompressSizeFirst];
    NSLog(@"即将开始压缩~~");
    [self usedMemory];
    NSTimeInterval timeBegin = [[NSDate date] timeIntervalSince1970];
    // 循环压缩测试
    for (int i = 0; i < 10; i++) {

        @autoreleasepool {

            NSLog(@"%@", [NSString stringWithFormat:@"第 %d 次压缩", i]);

            [self handleCompressSizeFirst];

            [self usedMemory];
        }
    }

    NSTimeInterval timeEnd = [[NSDate date] timeIntervalSince1970];
    // 处理耗费时间
    NSLog(@"耗费时间：%f", timeEnd - timeBegin);
    
    [self usedMemory];
}

- (IBAction)compressQualityFirst:(id)sender
{
//    [self handleCompressQualityFirst];
        
    NSTimeInterval timeBegin = [[NSDate date] timeIntervalSince1970];
    // 循环压缩测试
    for (int i = 0; i < 10; i++) {

        @autoreleasepool {

            NSLog(@"%@", [NSString stringWithFormat:@"第 %d 次压缩", i]);
            [self handleCompressQualityFirst];
            [self usedMemory];
        }
    }
    NSTimeInterval timeEnd = [[NSDate date] timeIntervalSince1970];
    // 处理耗费时间
    NSLog(@"耗费时间：%f", timeEnd - timeBegin);
}

- (IBAction)compressQualityOnly:(id)sender
{
    [self handleCompressQualityOnly];
    
    [self usedMemory];
}

- (IBAction)compressSizeByImageIO:(id)sender
{
//    [self handleCompressSizeByImageIO];
    
    NSLog(@"即将开始压缩~~");
    [self usedMemory];
    NSTimeInterval timeBegin = [[NSDate date] timeIntervalSince1970];
    // 循环压缩测试
    for (int i = 0; i < 10; i++) {

        @autoreleasepool {

            NSLog(@"%@", [NSString stringWithFormat:@"第 %d 次压缩", i]);
            [self handleCompressSizeByImageIO];
            [self usedMemory];
        }
    }

    NSTimeInterval timeEnd = [[NSDate date] timeIntervalSince1970];
    // 处理耗费时间
    NSLog(@"耗费时间：%f", timeEnd - timeBegin);

    [self usedMemory];
}

- (IBAction)cycleCompressLocalImages:(id)sender
{
    [self handleCycleCompressLocalImages];
}

#pragma mark - private method

- (void)handleCompressSizeFirst
{
    NSData *imageData = [self fetchOriginImageData];
    
    UIImage *compressAfter = [UIImage compressImage:[UIImage imageWithData:imageData] compressibilityFactor:400 compressionQuality:0.4];
    
    self.image.image = compressAfter;
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@", compressAfter]);
}

- (void)handleCompressSizeByImageIO
{
    NSData *imageData = [self fetchOriginImageData];
    
    // 测试仅压缩尺寸
//    UIImage *compressAfter = [UIImage compressImage:[UIImage imageWithData:imageData] compressibilityFactor:400 isNeedCompressQuality:NO compressionQuality:1];
    
    // 测试压缩尺寸和质量
    UIImage *compressAfter = [UIImage compressImage:[UIImage imageWithData:imageData] compressibilityFactor:400 isNeedCompressQuality:YES compressionQuality:1];
    
    self.image.image = compressAfter;
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@", compressAfter]);
}

- (void)handleCompressQualityFirst
{
    NSData *imageData = [self fetchOriginImageData];
    
    UIImage *compressAfter = [UIImage compressImageQuality:[UIImage imageWithData:imageData] toByte:32.0 * 1024];
    
    self.image.image = compressAfter;
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@", compressAfter]);
}

/**
 单纯压缩质量
 */
- (void)handleCompressQualityOnly
{
    NSData *imageData = [self fetchOriginImageData];
    
    UIImage *compressAfter = [UIImage compressImageQualityNormal:[UIImage imageWithData:imageData] toByte:32.0 * 1024];
    
    self.image.image = compressAfter;
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@", compressAfter]);
}

- (NSData *)fetchOriginImageData
{
    // 13M 图
    NSData *imageData = [self fetchShareImageData:@"https://wireless-hipac.oss-cn-hangzhou.aliyuncs.com/pub_resource/4k_lake.jpg"];
    
    // 10M 图
//    NSData *imageData = [self fetchShareImageData:@"https://yangtuo.oss-cn-hangzhou.aliyuncs.com/mall2c/yasuoceshi1.jpg"];
    
    // M 图
//    NSData *imageData = [self fetchShareImageData:@"https://yangtuo.oss-cn-hangzhou.aliyuncs.com/mall2c/yasuoceshi2.HEIC"];
    
//    397 kb 图
//    NSData *imageData = [self fetchShareImageData:@"http://img.hicdn.cn/201902/item/02271900459366zC5l_750x750.jpg"];
    
    NSLog(@"%@", [NSString stringWithFormat:@"图片的原始尺寸：w：%f h：%f", [UIImage imageWithData:imageData].size.width, [UIImage imageWithData:imageData].size.height]);
    NSLog(@"%@", [NSString stringWithFormat:@"图片的原始大小：%zd kb", imageData.length / 1000]);
    
    return imageData;
}


/**
 循环压缩测试
 */
- (void)handleCycleCompressLocalImages
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray <UIImage *> *muAry = NSMutableArray.new;
        
        NSTimeInterval timeBegin = [[NSDate date] timeIntervalSince1970];
        
        // 超多次循环，例如（200次）
        for(int i = 0; i < 200; i++) {
            
            // 加与不加 autoreleasepool，可以测测看
            /*
             结论：
             
             加与不加 autoreleasepool，对于 imageIO 的方式，并没有什么区别，
             但对于 CGGraphics ，不加 autoreleasepool 内存暴增（UIGraphicsEndImageContext
              释放的仅仅是画布，但图片的内存数据是不会释放的，直到 async执行完才会释放，所以内存占用超高），真机瞬间闪退，
             但加了 autoreleasepool ，底层代码对图片数据对象 添加了 autorelease 标识，那么他就会添加到最近的 autoreleasepool 中，也就是说，一次循环结束后就释放了，比
             imageIO 的方式内存占用稍稍大一点
             */
            @autoreleasepool {
                // 5张用来测试的图片
                int index = i % 5;
                NSString *strName = [NSString stringWithFormat:@"image%i", index + 1];
                NSString *strFilePath = [[NSBundle mainBundle] pathForResource:strName ofType:@"jpg"];
                NSData *data = [NSData dataWithContentsOfFile:strFilePath];
//                UIImage *img = [UIImage compressByImgIOWithData:data withMaxPixelSize:500]; // Image I/O 方法
                UIImage *img = [UIImage compressByConextWithData:data withMaxPixelSize:500]; // ImageContext 方法
                [muAry addObject:img];
                data = nil;
                strFilePath = nil;
            }
        }
        NSTimeInterval timeEnd = [[NSDate date] timeIntervalSince1970];
        // 打印 耗费时间
        NSLog(@"耗费时间：%f", timeEnd - timeBegin);
    });
}

- (NSData *)fetchShareImageData:(id)image
{
    if (image != nil) {
        
        if ([image isKindOfClass:[UIImage class]]) {
            
            UIImage *imageTemp = (UIImage *)image;
            
            return UIImagePNGRepresentation(imageTemp);
            
        } else if ([image isKindOfClass:[NSString class]]) {
            
            NSString *imageUrl = (NSString *)image;
            
            // 不是图片 url 链接形式，兼容不带协议的图片链接
            if (![imageUrl hasPrefix:@"http://"] && ![imageUrl hasPrefix:@"https://"]) {
                
                // 兼容没带协议的链接
                imageUrl = [NSString stringWithFormat:@"%@%@", @"http:", imageUrl];
            }
            
            SZImageCacheManager *imageCacheManager = [SZImageCacheManager new];
            
            // 查看是否存在缓存
            NSData *imageCache = [imageCacheManager getImageDataFromCacheWithUrlString:imageUrl];
            
            if (imageCache != nil) {
                
                return imageCache;
            }
            
            // 此处获取到的 imageCache 的类型实际上是 NSData 的类簇中的 OS_dispatch_data，通过 bytes 拿到的数据是不对的
            imageCache = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl] options:NSDataReadingMappedIfSafe error:nil];
            
            // 正确的数据类型是类簇中的 _NSInlineData 或者 NSConcreteMutableData，所以这里做一个 mutableCopy ，使类型变为 NSConcreteMutableData，才是正确的byte数组
            //            imageCache = [imageCache mutableCopy];
            
            // 从网络获取到图片后，判定是否为有效图片，如果有效，则缓存好，然后返回该图片，否则返回nil
            if (imageCache != nil) {
                
                // 缓存图片
                [imageCacheManager cacheImageWithImageData:imageCache andUrlString:imageUrl];
                
                return imageCache;
            }
        }
    }
    
    return nil;
}

- (double)usedMemory
{
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),
                                         TASK_BASIC_INFO,
                                         (task_info_t)&taskInfo,
                                         &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
    NSLog(@"%@", [NSString stringWithFormat:@"内存占用：%f M", taskInfo.resident_size / 1024.0 / 1024.0]);
    
    return taskInfo.resident_size / 1024.0 / 1024.0;
}

@end
