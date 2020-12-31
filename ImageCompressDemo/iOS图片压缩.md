---
title: iOS图片压缩
date: 2019-06-24 14:46:22
categories:
- 山竹
tags:
- iOS
- 效率
---

#### 一般图片压缩的需求

1. 压缩到指定宽高（例如：微信图片压缩，宽或者高不超过 1280 ）
2. 压缩到指定大小（例如：微信小程序分享，图片不超过 32kb）

#### 常规的图片压缩方法

##### 一、质量压缩

```Objective-C
UIImageJPEGRepresentation(image, compression);
```
这是苹果爸爸提供的质量压缩API：第一个参数是 目标image，第二个参数 compression 取值 0.0 ~ 1.0，理论上值越小表示图片质量越低，图片文件自然越小。

但这里有个注意点，并不是 compression 取 0，就是0b大小，取 1 就是原图：

    a.首先：图片的大小是根据（图片的宽 * 图片的高 * 每一个色彩的深度）来获取的，
    图片只会按照你的手机像素的分辨率 [UIScreen mainScreen].scale 来读取值。

    b.其次：对于大图片来说，即使你的 compression 选的很小很小，
    比如：0.0000000（n个0）001，无论多小都没有用，因为达到
    一定阈值之后，就再也压不下去了，但是得到的结果还是很大，
    DEMO中例子：一张13M左右的图片，处理后极限大小为551kb左右。

###### 循环压缩的方法：

```Objective-C
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
```

**以下是压缩数据：**

图片的原始大小：**13362 kb**

压缩次数 | 压缩比例 | 压缩后的图片大小
--------- | ------------- | -------------
1 | 0.990000 | 5984.280000 kb
2 | 0.980000 | 5818.233000 kb
3 | 0.970000 | 5663.514000 kb
... | ... | ...
37 | 0.630000 | 2726.441000 kb
38 | 0.620000 | 2659.856000 kb
39 | 0.610000 | 2594.750000 kb
... | ... | ...
67 | 0.330000 | 925.446000 kb
68 | 0.320000 | 886.675000 kb
69 | 0.310000 | 867.404000 kb
... | ... | ...
90 | 0.100000 | 562.138000 kb
91 | 0.090000 | 561.355000 kb
92 | 0.080000 | 553.827000 kb
93 | 0.070000 | 553.236000 kb
94 | 0.060000 | **551.402000 kb**
95 | 0.050000 | **551.402000 kb**
96 | 0.040000 | **551.402000 kb**
97 | 0.030000 | **551.402000 kb**
98 | 0.020000 | **551.402000 kb**
99 | 0.010000 | **551.402000 kb**
100 | -0.000000 | **551.402000 kb**

###### 换句话来说，如果要实现压缩到指定大小（比如 32k），如果是小图倒是不会有什么问题，多试几次应该能得到想要的结果，如果大图（比如 13M）只用压缩质量的方式，是办不到的，达到一定阈值之后(压缩比例：小于0.060000)，就再也压不下去了。

当然，这个方法是有问题的，总共压缩了 100 次，循环次数过多，*效率低，耗时长*。

如果你得到的图片压缩的需求，是保证尺寸不变的情况下，尽可能压到最小，自然只需要循环压缩就好，不过有更好的实现方式，那就是 **二分法**。

```Objective-C
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
```
二分最大10次即可，既可以达到压缩到`阈值`的效果，又能节约性能，区间范围精度最大可达`0.00097657`；第6次，精度可达`0.015625`，10次，`0.000977`

使用二分法进行处理，比for循环依次递减**“高效”**很多，而且也**合理**很多，第10次就达到了单纯的for循环的99次的效果。

次数 | 压缩比例
--------- | -------------
1 | 0.500000
2 | 0.250000
3 | 0.125000
4 | 0.062500
5 | 0.031250
6 | 0.015625
7 | 0.007812
8 | 0.003906
9 | 0.001953
10 | 0.000977
     
二分法也同样存在压缩到一定的阈值，压不下去的问题，如果需求是指定压缩到某个大小，但二分法压缩到最后一次后，还是大于指定的大小，然后该怎么处理呢？

图片的大小是根据`（图片的宽 * 图片的高 * 每一个色彩的深度）`来获取的，当质量压缩到极限的时候，就只能进行尺寸压缩了。

##### 二、尺寸压缩

###### 一、常规操作：使用 UIGraphics 按指定大小重新绘图

```Objective-C
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}
```

######方案一是存在问题的：

> 1. 绘制是非常耗内存性能的，[UIImage drawInRect:] 在绘制时，先解码图片，再生成原始分辨率大小的bitmap，这是很耗内存的，并且还有位数对齐等耗时操作；
> 
    > **bitmap是什么？**
    参考：<https://www.jianshu.com/p/362c2f03d378>，这里就不拓展了。

> 2. 如果在一个方法中循环压缩比例进行代码的比例压缩，那么这种使用UIKit类进行图片绘制的话是需要先把图片读入内存然后在进行绘制，那么势必会给内存中占用大量的临时内存bitmap，而这个如果再加上循环，那么内存占有将是不可估量的，尤其是大图片的压缩尤其明显。(*针对这个问题，自然会想使用@autoreleasepool来解决，实际上并不行，首先这个自动释放池@autoreleasepool不要放在循环的外面，包着这个循环，循环中产生的不再被使用的实例需要在整个for循环结束后才会被释放，所以并没有解决问题。然后放在for循环内部包着这个绘制的方法，你的内存并不是画完就得到了释放，内存占有的情况可以得到缓解，但是还是不能解决内存突然暴增的问题。*)

###### 二、更为底层的操作： ImageIO 的处理方式

```Objective-C
+ (UIImage *)compressByImgIOWithData:(NSData*)data withMaxPixelSize:(CGFloat)maxPixelSize
{
    UIImage *imgResult = nil;
    if(data == nil)         { return imgResult; }
    if(data.length <= 0)    { return imgResult; }
    if(maxPixelSize <= 0)   { return imgResult; }
    
    const float scale = [UIScreen mainScreen].scale;
    const int sizeTo = maxPixelSize * scale;
    CFDataRef dataRef = (__bridge CFDataRef)data;
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
```

使用`ImageIO`的方式，即可避免在改变图片大小的过程中产生临时的`bitmap`，就能够在很大程度上减少内存暴增，从而避免由此导致的app闪退问题。

需要注意的是， 使用`Image IO` 时，设置`kCGImageSourceThumbnailMaxPixelSize` 的最大高/宽值时，如果设置值超过了图片文件原本的高/宽值，那么`CGImageSourceCreateThumbnailAtIndex`获取的图片尺寸将是原始图片文件的尺寸。比如，设置 `kCGImageSourceThumbnailMaxPixelSize` 为600，而如果图片文件尺寸为580*212，那么最终获取到的图片尺寸是580 * 212。

#### 两种方式的性能

**使用循环压缩测试两种尺寸压缩方法的性能：**

```Objective-C
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
//            @autoreleasepool {
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
//            }
        }
        NSTimeInterval timeEnd = [[NSDate date] timeIntervalSince1970];
        // 打印 耗费时间
        NSLog(@"耗费时间：%f", timeEnd - timeBegin);
    });
}
```

测试的机型和系统：**iPhone6，12.3.1(可靠一些)，模拟器 XR，12.3.1（仅供参考）**

机型 | 系统 | 方式 | 是否循环内autoreleasepool | 最高内存 | 耗费时间 
--------- | ------------- | ------------- | ------------- | ------------- | -------------
iPhone6 | 12.3.1 | CGGraphics | 是 | 61.6M | 23.735421 s
iPhone6 | 12.3.1 | ImageIO | 是 | 57.4M | 18.259976 s
iPhone6 | 12.3.1 | CGGraphics | 否 | **闪退** | **闪退**
iPhone6 | 12.3.1 | ImageIO | 否 | 56.3M | 17.751459 s
模拟器 XR | 12.3.1 | CGGraphics | 是 | 134.3M | 18.541668 s
模拟器 XR | 12.3.1 | ImageIO | 是 | 134.1M | 12.305965 s
模拟器 XR | 12.3.1 | CGGraphics | 否 | **1.39G** | 18.846126 s
模拟器 XR | 12.3.1 | ImageIO | 否 | 130.9M | 11.920672 s

**从以上的表格中分析：**

> 1. 从时间看，两种方法的效率其实是差不多的，用哪种方式都是差不多的。
> 2. 如果循环内 不使用 `autoreleasepool` 的话，在真机上由于内存暴增，
>   超出手机的可用内存，直接导致闪退；在模拟器上，最高内存达到了惊人的`1.39G`。
> 
> ![avatar](http://chuantu.xyz/t6/702/1561360518x2890174227.png)
> 
> 3. 综上，如果循环内使用了`autoreleasepool`的话，`ImageIO`的方式比`CGGraphics`的效率更高；如果循环内不使用`autoreleasepool`的话，`CGGraphics`根本不能用，`ImageIO`不受影响，因为是手动调用内存释放的方法。
> 
> **所以推荐 `ImageIO` 方式来进行尺寸压缩。**

**在不加`autoreleasepool`的时，为什么会内存占用会到达惊人的数字，我们通过`Time Profiler`来分析：**

![avatar](http://chuantu.xyz/t6/702/1561360575x1709417317.png)

从堆栈中可以看到，`drawInRect`的底层最终调用的也是`ImageIO`的API对图片进行处理，`ImageIO`会创建一个图片数据对象（其实就是一张画布），但 drawInRect 还会先解码图片，生成原始分辨率大小的bitmap，而调用完`UIGraphicsBeginImageContext`，我们会成对调用 `UIGraphicsEndImageContext()`来释放占用的资源，接下来看看`UIGraphicsEndImageContext()` 做了什么：

![avatar](http://chuantu.xyz/t6/702/1561360641x1709417317.png)

从堆栈中可以看到，`UIGraphicsEndImageContext()`调用之后，会做两件事情，一件是 `CGBitmapContextInfoRelease` 来释放图片的bitmap，一件是释放 `CGContext` (画布)，看堆栈底层是把该做的事情都做了。

但实际测试结果却不是这样的，原因是什么呢？

释放资源的代码是调用了，但实际执行的时机却在循环内加与不加`autoreleasepool` 是完全不同的：

>  1.循环内不加 `autoreleasepool` 时，`CGBitmapContextInfoRelease`会加到dispatch_async自动添加的`autoreleasepool`中，也就意味着所有的`CGBitmapContextInfoRelease` 需要等子线程运行结束才会被释放，这也是下图中内存到1.39G之后直线下降的原因。

> ![avatar](http://chuantu.xyz/t6/702/1561360518x2890174227.png)

>  2.循环内加 `autoreleasepool` 时，`CGBitmapContextInfoRelease` 则是加入离自己最近的 `autoreleasepool` ，也就是一次循环创建的 `autoreleasepool`，一次循环结束后，`CGContext` (画布) 和 图片的bitmap资源就都释放了，所以不会造成内存的持续累计的暴增。
> 
> ![avatar](http://chuantu.xyz/t6/702/1561360673x1709417317.png)

**以上分析为个人理解，如果有什么不对的地方，烦请不吝赐教~**

#### 总结

##### 一、解决第一个需求（压缩到指定宽高）的方案

说到压缩图片到指定宽高，还需要提UIImage转NSData的另外一个API，`UIImagePNGRepresentation()`，如果是做图片压缩，一般不会用这个，网上资料说这个读取图片的大小会比较大，因为是png格式，读取的内容会有多图层的的问题导致读取的会显示比较大，而且比较耗时间。

> 网上有人做过测试：同样是读取摄像头拍摄的同样景色的照片，`UIImagePNGRepresentation()` 返回的数据量大小为199K，而 `UIImageJPEGRepresentation(UIImage* image, 1.0)` 返回的数据量大小只为 140KB，比前者少了50多KB。

但 `UIImagePNGRepresentation()` 也有个优点，那就是更高的清晰度，用这个API转换得到的图片清晰度比较高，如果对图片的清晰度要求不高，还可以通过设置 `UIImageJPEGRepresentation` 的第二个参数，大幅度降低图片数据量。

方法如下：

```Objective-C
/**
 压缩图片的宽或高到指定值（使用 ImageIO 绘图） -- 推荐 --
 
 @param image 目标图片
 @param compressibilityFactor 指定最大宽高
 @param isNeedCompressQuality 是否需要压缩质量
 @param compressionQuality    需要压缩比例的时候才生效，压缩比例（0 ~ 1）取值
 @return 压缩后的图片
 */
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
    
    UIImage *resultImage = [self compressByImageIOFromData:dJpeg maxPixelSize:MAX(oldImg_WID, oldImg_HEI)];
    
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
```

###### 这个方法提供一个选择：
> 1. 如果仅仅只是需要压缩尺寸，需要更高的清晰度，那么`isNeedCompressQuality`传`NO`；
> 2. 如果需要压缩尺寸的同时，也需要压缩一定的质量，那么`isNeedCompressQuality`传`YES`，并传入压缩系数（**注意：上文提过了压缩系数使用1并不是原图**），以达到需求的兼容。

**使用UIImagePNGRepresentation的数据：**

原始尺寸 | 原始大小 | 压缩后尺寸 | 压缩后的大小
--------- | ------------- | ------------- | -------------
w：4270.00 h：2847.00 | 13362 kb | w：400.00 h：267.00 | **29281 kb**

**使用UIImageJPEGRepresentation，压缩系数1 的数据：**

原始尺寸 | 原始大小 | 压缩后尺寸 | 压缩后的大小
--------- | ------------- | ------------- | -------------
w：4270.00 h：2847.00 | 13362 kb | w：400.00 h：267.00 | **18627 kb**

**使用UIImageJPEGRepresentation，压缩系数0.5 的数据：**

原始尺寸 | 原始大小 | 压缩后尺寸 | 压缩后的大小
--------- | ------------- | ------------- | -------------
w：4270.00 h：2847.00 | 13362 kb | w：400.00 h：267.00 | **1734 kb**

##### 二、解决第二个需求（压缩到指定大小）的方案

###### 具体步骤如下：

> 1. 首先使用二分法UIImageJPEGRepresentation压缩，如果能压缩到指定大小内，则return；

> 2. 然后对处理后的图片信息，保留最大压缩比（即上面的最小二分法的最后一次的结果），之后再进行和最终目标的大小比值，求根，然后对图像的宽和高等比压缩处理。之后再次根据最小二分法的scale以UIImageJPEGRepresentation读取结果再和目标大小比对，以此循环，直到大小小于目标大小。

###### 代码：

```Objective-C
/**
 压缩图片到指定大小（先压缩质量，如果还是达不到，再压缩宽高） -- 推荐 --

 @param image 目标图片
 @param maxLength 需要压缩到的byte值
 @return 压缩后的图片
 */
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
                resultImage = [self compressByImageIOFromData:data maxPixelSize:MAX(size.width, size.height)];
                data = UIImageJPEGRepresentation(resultImage, compression);
            }
        }
    }
    
    UIImage *resultImage = [UIImage imageWithData:data];
    
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
```

**13M的图片压缩到指定大小（32k）的打印数据：**

图片的原始尺寸：**w：4270.00 h：2847.00**
图片的原始大小：**13362 kb**

###### 二分法压缩（13362 kb --> 32 kb）数据

压缩精度 | 二分法压缩后的大小
--------- | -------------
0.500000 | 1734.263000 kb
0.250000 | 713.207000 kb
0.125000 | 572.926000 kb
0.062500 | 552.155000 kb
0.031250 | **551.402000 kb**
0.015625 | **551.402000 kb**
0.007812 | **551.402000 kb**
0.003906 | **551.402000 kb**
0.001953 | **551.402000 kb**
0.000977 | **551.402000 kb**

二分法压缩到最后一次的大小为： 551.402000 kb m，未达到目标，接下来走尺寸压缩：

压缩后尺寸 | 压缩后的大小
--------- | -------------
w：1040.00 h：694.00 | 38.302000 kb
w：961.00 h：640.00 | **32.485000 kb**

**这样得到的图片几乎就能够在你设定的大小以内的附近，而且图片的信息肉眼几乎看不出来多大的区别，而且压缩出来的图片*清晰度很高*。**

**Tips：**我们看到最后的大小是 32.485000 kb，所以压缩到指定大小的时候，需要设置的小 1 kb，避免程序中的小误差，比如微信小程序分享对图片的要求是 32kb，如果是设置 32kb，那么出现浮点的 32.485000 就会导致分享成功。

**最后附上DEMO：**

http://ytgit.hipac.cn/Wireless/iosimagecompressdemo

***

**参考：**

<https://www.cnblogs.com/silence-cnblogs/p/6346729.html>
<https://blog.csdn.net/BUG_delete/article/details/84636899>
<https://www.jianshu.com/p/de7b6aede888>
<https://www.jianshu.com/p/362c2f03d378>
<https://www.jianshu.com/p/ba45f5539e4e>
<https://www.jianshu.com/p/362c2f03d378>







