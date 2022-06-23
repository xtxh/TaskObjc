//
//  BlockTask.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "Task.h"

NS_ASSUME_NONNULL_BEGIN

// A block type that takes a function as a parameter.
typedef void(^TaskBlock)(void (^)(void));

/// An task that manages the execution of a block.
@interface BlockTask : Task

-(instancetype)initWithBlock:(TaskBlock)block;

/// Convenience initializer that ensures the block is run on the main queue. The function
/// parameter must be called when the block.
/// @param mainQueueblock  A block to run on the main queue.
-(instancetype)initWithMainQueueBlock:(TaskBlock)mainQueueblock;

@end

NS_ASSUME_NONNULL_END
