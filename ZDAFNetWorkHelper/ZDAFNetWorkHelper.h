//
//  ZAFNetWorkService.h
//  RequestNetWork
//
//  Created by Bourne on 14/11/21.
//  Copyright (c) 2014年 Fate.D.Bourne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, HttpMethod) {
	HttpMethod_Get,
	HttpMethod_Post
};

//用于回调请求成功或者失败的信息
typedef void (^ SuccessHandle)(id _Nullable responseObject);
typedef void (^ FailureHandle)(NSError *_Nonnull error);

@interface ZDAFNetWorkHelper : NSObject

@property (nonatomic, copy, nullable) NSString *baseURLString;      ///< baseURL
@property (nonatomic, assign) BOOL hasCertificate;                  ///< 有无证书,default is NO

/**
 *  单例
 *
 *  @return 实例化后的selfClass
 */
+ (instancetype)shareInstance;

/**
 *  @abstract GET && POST请求
 *
 *  @param urlString : 请求地址
 *  @param params : 请求参数
 *  @param httpMethod : GET/POST 请求
 *  @param hasCer : 是否有证书（对于Https请求）
 *  @param successBlock/failureBlock : 回调block
 *
 *  @discussion
 */
- (nullable NSURLSessionDataTask *)requestWithURL:(NSString *)URLString
                                           params:(nullable id)params
                                       httpMethod:(HttpMethod)httpMethod
                                          success:(nullable SuccessHandle)successBlock
                                          failure:(nullable FailureHandle)failureBlock;

@end

NS_ASSUME_NONNULL_END
