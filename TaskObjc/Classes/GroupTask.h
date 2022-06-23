//
//  GroupTask.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "Task.h"
#import "TaskQueue.h"

NS_ASSUME_NONNULL_BEGIN

/// A group task is a way of grouping dependent tasks into a single task.
@interface GroupTask : Task <TaskQueueDelegate>

/// The max concurrent tasks of the internal queue. The default value is NSOperationQueueDefaultMaxConcurrentOperationCount.
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

-(instancetype)initWithTasks:(NSArray<BaseTask *> *)tasks;

/// Subclasses can override this method to configure tasks before group is executed.
/// This allows configuration based on runtime conditions and dependencies that isn’t possible during initialization.
-(void)configureTasksBeforeExecution;

/// Adds a task to the group task.
-(void)addTask:(BaseTask *)task;
/// Adds an array of tasks to the group task.
-(void)addTasks:(NSArray<BaseTask *> *)tasks;

/// This method can be overridden by subclasses that need a hook when tasks finish.
/// @param task The finished task.
/// @param erros An array of errors the task finished with.
-(void)taskDidFinish:(BaseTask *)task withErrors:(NSArray<NSError*> *)erros;

@end

NS_ASSUME_NONNULL_END
