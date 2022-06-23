//
//  BlockTask.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "BlockTask.h"

@interface BlockTask ()

@property (nonatomic, copy)TaskBlock block;

@end

@implementation BlockTask

-(instancetype)initWithBlock:(TaskBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

-(instancetype)initWithMainQueueBlock:(TaskBlock)mainQueueblock {
    self = [self initWithBlock:^(void (^continuation)(void)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            mainQueueblock(continuation);
        });
    }];
    return self;
}

-(void)execute {
    __weak typeof(self) weakSelf = self;
    self.block(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf finishTaskWithErrors:nil];
    });
}


@end
