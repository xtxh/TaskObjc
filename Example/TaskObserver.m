//
//  TaskObserver.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "TaskObserver.h"
#import <UIKit/UIKit.h>

NSString *const TaskBackgroundErrorTimeExpired = @"Task.Background.Error.TimeExpired";

@implementation TaskObserver

-(instancetype)init {
    return [self initWithStartHandler:nil spawnHandler:nil finishHandler:nil];
}

-(instancetype)initWithStartHandler:(void (^)(Task * _Nonnull))startHandler
                       spawnHandler:(nullable void (^)(Task * _Nonnull, BaseTask * _Nonnull))spawnHandler
                      finishHandler:(nullable void (^)(Task * _Nonnull, NSArray<NSError *> * _Nonnull))finishHandler {
    self = [super init];
    if (self) {
        self.startHandler = startHandler;
        self.spawnHandler = spawnHandler;
        self.finishHandler = finishHandler;
    }
    return self;
}

#pragma mark - TaskObserver

-(void)taskDidStart:(Task *)task {
    if (self.startHandler) {
        self.startHandler(task);
    }
}

-(void)task:(Task *)task didSpawnTask:(BaseTask *)newTask {
    if (self.spawnHandler) {
        self.spawnHandler(task, newTask);
    }
}

-(void)task:(Task *)task didFinishWithErrors:(NSArray *)errors {
    if (self.finishHandler) {
        self.finishHandler(task, errors);
    }
}

@end

@interface BackgroundTaskObserver ()

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;

@end

@implementation BackgroundTaskObserver

-(void)beginBackgroundForTask:(Task *)task {
    self.backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSError *error = [[NSError alloc] initWithDomain:TaskBackgroundErrorTimeExpired code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Background Task Error time expired!"}];
        [task cancelWithError:error];
        [self endBackgroundForTask:task];
    }];
}

-(void)endBackgroundForTask:(Task *)task {
    if (self.backgroundTaskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
    }
    self.backgroundTaskID = UIBackgroundTaskInvalid;
}

#pragma mark - TaskObserver

-(void)taskDidStart:(Task *)task {
    [self beginBackgroundForTask:task];
}

-(void)task:(Task *)task didSpawnTask:(BaseTask *)newTask {
    if ([newTask isKindOfClass:Task.class]) {
        Task *spawntask = (Task *)newTask;
        [spawntask addObserver:[BackgroundTaskObserver new]];
    }
}

-(void)task:(Task *)task didFinishWithErrors:(NSArray *)errors {
    [self endBackgroundForTask:task];
}

@end
