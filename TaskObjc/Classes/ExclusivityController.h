//
//  ExclusivityController.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import <Foundation/Foundation.h>
#import "Task.h"
#import "TaskCondition.h"

NS_ASSUME_NONNULL_BEGIN

/// A shared exclusivity controller that ensures mutually exclusive tasks do not execute concurrently.
@interface ExclusivityController : NSObject

+(instancetype)shared;

/// Adds a task to the exclusivity controller. If a task with the same category is known, it will become a depdendency of the task.
/// @param task The task to add.
/// @param categories The exclusivity categories the task belongs to.
-(void)addTask:(Task *)task categories:(NSArray *)categories;

/// Removes a task from the exclusivity controller.
/// @param task The task to remove.
/// @param categories The exclusivity categories the task belongs to.
-(void)removeTask:(Task *)task categories:(NSArray *)categories;

@end

/// A condition that prevents tasks with the same category from running concurrently.
/// The exclusivity key is composed of both the primary and sub category. The sub category
/// is a convenience for easily differentiating tasks. For example if a task was only
/// mutually exclusive if two instances had the same ID you could pass the name of
/// the task for the primaryCategory and the ID as the sub category.
@interface MutuallyExclusive : NSObject <TaskCondition>

@property (nonatomic, strong, readonly)NSString *exclusivityKey;

/// A mutually exclusive task condition for modal UI.
+ (instancetype )modalUI;

-(instancetype)initWithPrimaryCategory:(NSString *)primaryCategory
                           subCategory:(nullable NSString *)subCategory NS_DESIGNATED_INITIALIZER;

@end


NS_ASSUME_NONNULL_END
