//
//  TaskObserver.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import <Foundation/Foundation.h>
#import "Task.h"

NS_ASSUME_NONNULL_BEGIN

/// Objects conforming to this protocol can observe a task by receiving
/// calls when the task starts, finishes or spawns a new task.
@protocol TaskObserverProtocol <NSObject>

/// Informs the observer the task started.
-(void)taskDidStart:(Task *)task;

/// Informs the observer the task spawned a new task.
-(void)task:(Task *)task didSpawnTask:(BaseTask *)newTask;

/// Informs the observer the task finished.
-(void)task:(Task *)task didFinishWithErrors:(NSArray *)errors;

@end

/// A task observer that runs arbitrary blocks of code at the various observation points.
@interface TaskObserver : NSObject <TaskObserverProtocol>

/// A closure with a parameter for the task that started.
@property (nonatomic, copy, nullable) void (^startHandler)(Task *task);

/// A closure with parameters for a task and the task it spawned.
@property (nonatomic, copy, nullable) void (^spawnHandler)(Task *task, BaseTask *newTask);

/// A closure with a parameter for the task that finished.
@property (nonatomic, copy, nullable) void (^finishHandler)(Task *task, NSArray<NSError*> *errors);

-(instancetype)initWithStartHandler:(nullable void (^)(Task *task))startHandler
                       spawnHandler:(nullable void(^)(Task *task, BaseTask *newTask))spawnHandler
                      finishHandler:(nullable void(^)(Task *task, NSArray<NSError *> *errors))finishHandler;

@end

/// An task observer that starts a  `background task` when the task begins and ends the `background task` when the task ends.
@interface BackgroundTaskObserver : NSObject <TaskObserverProtocol>

/// Begins a background task for a task.
-(void)beginBackgroundForTask:(Task *)task;

/// Ends a background task for a task.
-(void)endBackgroundForTask:(Task *)task;

@end


FOUNDATION_EXPORT NSString *const TaskBackgroundErrorTimeExpired;

NS_ASSUME_NONNULL_END
