//
//  Task.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSOperation BaseTask;
typedef NSBlockOperation BaseBlockTask;

@protocol TaskObserverProtocol, TaskCondition;

/// Task extends the functionality of NSOperation by adding conditions and observers. Its use is similar but slightly different than NSOperation.
/// Instead of overriding start() and main() subclasses should override execute() and call finish() when the code has finished.
/// `finish() `must be called whether the task completed successfully or in an error state. As long as these methods are called, all other state is managed automatically.
///
/// Conditions are added to a task to establish criteria required in order for the task to successfully run.
/// For example a task that required location data could add a condition that made sure access had been granted to location services.
/// Observers are added to a task and can react to the starting and ending of a task.
/// For example an observer could start and stop an activity indicator while the task is executing.
@interface Task : BaseTask

@property (nonatomic, strong, nullable) NSMutableDictionary *userInfo;

/// True if the task finished without any errors and was not cancelled, otherwise false.
@property (nonatomic, assign, readonly) BOOL didFinishSuccessfully;

/// An array of conditions for the task.
@property (nonatomic, strong, readonly) NSMutableArray *conditions;

/// An array of observers for the task.
@property (nonatomic, strong, readonly) NSMutableArray* observers;

/// Adds an error to collected task errors.
- (void) addError:(NSError *)error;
/// Adds errors to collected task errors.
- (void) addErrors:(NSArray *)errors;

/// Adds a condition to the task.
- (void) addCondition:(id<TaskCondition>)condition;

/// Adds an observer to the task.
- (void) addObserver:(id<TaskObserverProtocol>)observer;

/// Informs the task it will be added to a queue. Must be called for the task to run.
- (void) willEnqueue;

/// Subclasses should override this method and put all code to execute here.
/// finish() must be called when the execution is complete.
- (void) execute;

/// Adds a new task to the queue. This allows tasks to spawn new tasks as a reaction to failure or other events.
- (void) spawnTask:(BaseTask *)task;

/// Cancels the task with an associated error.
- (void) cancelWithError:(NSError *)error;

/// Marks the execution of the task as complete.
/// This must be called when a task's execution is done, regardless of success or failure.
- (void) finishTaskWithErrors:(nullable NSArray<NSError *> *)errors;

/// Subclasses may override this method if they need to do anything in reaction to an error.
- (void) finishedWithErrors:(NSArray<NSError *> *)errors;

/// This method requires there is exactly one dependency of the required type.
- (nullable BaseTask *)typedDependency;

/// The successful dependency if found.
- (nullable Task *)successfulDependency;

@end

NS_ASSUME_NONNULL_END
