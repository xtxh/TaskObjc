//
//  TaskQueue.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import <Foundation/Foundation.h>
#import "Task.h"

NS_ASSUME_NONNULL_BEGIN

@class TaskQueue;
@protocol TaskQueueDelegate <NSObject>

/// Informs the delegate when a task will be added to the queue.
-(void)taskQueue:(TaskQueue *)queue willAddTask:(BaseTask *)task;

/// Informs the delegate when an operation finished.
-(void)taskQueue:(TaskQueue *)queue didFinishedTask:(BaseTask *)task withErrors:(NSArray<NSError *> *)errors;

@end

/// A subclass of NSOperationQueue with additional support for the features added by `Task`.
/// This queue must be used when working with `Task` subclasses.
@interface TaskQueue : NSOperationQueue

/// A delegate which will be notified when tasks are added and finish.
/// This is an alternate way of observing tasks if an observer isn’t a good fit.
@property(nonatomic, weak, nullable) id<TaskQueueDelegate> delegate;

/// Adds the specified task to the receiver.
-(void)addTask:(BaseTask *)task;

/// Adds the specified tasks to the queue.
-(void)addTasks:(NSArray<BaseTask *> *)tasks;

/// Permanently stops the queue, cancelling all existing tasks and preventing new tasks from being added.
-(void)terminate;

@end

NS_ASSUME_NONNULL_END
