#import "FFFastImageViewManager.h"
#import "FFFastImageView.h"

#import <SDWebImage/SDWebImagePrefetcher.h>
#import <SDImageCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>

@implementation FFFastImageViewManager

RCT_EXPORT_MODULE(FastImageView)

- (FFFastImageView*)view {
  return [[FFFastImageView alloc] init];
}

+ (void) initialize
{
    NSUInteger maxCacheSize = (NSUInteger) 250000000;
    SDImageCache.sharedImageCache.config.maxDiskAge = -1;
    SDImageCache.sharedImageCache.config.maxDiskSize = maxCacheSize; // 250MB as Android Glide
    SDImageCache.sharedImageCache.config.diskCacheExpireType = SDImageCacheConfigExpireTypeAccessDate;
}

RCT_EXPORT_VIEW_PROPERTY(source, FFFastImageSource)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, RCTResizeMode)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageProgress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoadEnd, RCTDirectEventBlock)
RCT_REMAP_VIEW_PROPERTY(tintColor, imageColor, UIColor)

RCT_EXPORT_METHOD(preload:(nonnull NSArray<FFFastImageSource *> *)sources)
{
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:sources.count];

    [sources enumerateObjectsUsingBlock:^(FFFastImageSource * _Nonnull source, NSUInteger idx, BOOL * _Nonnull stop) {
        [source.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString* header, BOOL *stop) {
            [[SDWebImageDownloader sharedDownloader] setValue:header forHTTPHeaderField:key];
        }];
        [urls setObject:source.url atIndexedSubscript:idx];
    }];

    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:urls];
}

RCT_EXPORT_METHOD(replaceImageInCache:(nonnull NSString *)originalURL : (nonnull NSString *)newURL)
{

    if ([originalURL.pathExtension.lowercaseString isEqualToString:@"gif"]) {

        dispatch_async(dispatch_get_main_queue(), ^{

                SDAnimatedImageView * imageView = [SDAnimatedImageView new];
                [imageView sd_setImageWithURL:[NSURL fileURLWithPath:originalURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {

                    if (image) {
                        [SDImageCache.sharedImageCache storeImage:image forKey:newURL completion:^{}];
                    }

                }];

            });

    }
    else {

        NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: originalURL]];
        UIImage * image = [UIImage imageWithData: imageData];

        if (image) {
            [SDImageCache.sharedImageCache storeImage:image forKey:newURL completion:^{}];
        }

    }

}

@end