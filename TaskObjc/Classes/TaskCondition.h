//
//  TaskCondition.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import <Foundation/Foundation.h>
#import "Task.h"


NS_ASSUME_NONNULL_BEGIN

@protocol TaskCondition <NSObject>

/// A string key used to enforce mutual exclusivity, if necessary.
- (nullable NSString *)exclusivityKey;

/// A dependency required by the condition. This should be a task to attempts to
/// make the condition pass, such as requesting permission.
- (BaseTask *)dependencyForTask:(Task *)task;

/// A method called to evaluate the condition. The method will call the completion with either passed or failed.
- (void)evaluateForTask:(Task *)task completion:(void (^)(NSError * _Nullable error))completion;

@end

@interface TaskConditionEvaluator : NSObject

/// Evaluates conditions for a task.
+ (void)evaluateConditions:(NSArray *)conditions forTask:(Task *)task completion:(void (^)(NSArray *errors))completion;

@end

NS_ASSUME_NONNULL_END
