//
//  TaskQueue.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "TaskQueue.h"
#import "TaskObserver.h"
#import "TaskCondition.h"
#import "ExclusivityController.h"

@interface TaskQueue ()

@property (nonatomic, assign) BOOL isTerminated;

@end

@implementation TaskQueue

-(void)addOperation:(NSOperation *)op {
    if (self.isTerminated) return;
    
    __weak typeof(self) weakSelf = self;
    if ([op isKindOfClass:Task.class]) {
        Task *task = (Task *)op;
        TaskObserver *spawnObserver = [[TaskObserver alloc] initWithStartHandler:nil spawnHandler:^(Task * _Nonnull task, BaseTask * _Nonnull newTask) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf addOperation:newTask];
        } finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate taskQueue:strongSelf didFinishedTask:task withErrors:errors];
        }];
        [task addObserver:spawnObserver];
        
        NSMutableArray *concurrencyCategories = [NSMutableArray arrayWithCapacity:0];
        
        for (id<TaskCondition> condition in task.conditions) {
            
            NSString *exclusivityKey = [condition exclusivityKey];
            if (exclusivityKey.length > 0) {
                [concurrencyCategories addObject:exclusivityKey];
            }
            
            BaseTask *dependency = [condition dependencyForTask:task];
            if (dependency) {
                [task addDependency:dependency];
                [self addOperation:dependency];
            }
        }
        
        if (concurrencyCategories.count > 0) {
            ExclusivityController *exclusivityController = [ExclusivityController shared];
            [exclusivityController addTask:task categories:concurrencyCategories];
            
            TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
                [exclusivityController removeTask:task categories:concurrencyCategories];
            }];
            [task addObserver:observer];
        }
        
        [task willEnqueue];
    } else {
        void (^delegateBlock)(void) = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate taskQueue:strongSelf didFinishedTask:op withErrors:@[]];
        };
        
        void (^existingCompletion)(void) = op.completionBlock;
        if (existingCompletion) {
            op.completionBlock = ^{
                existingCompletion();
                delegateBlock();
            };
        } else {
            op.completionBlock = delegateBlock;
        }
    }
    
    [self.delegate taskQueue:self willAddTask:op];
    [super addOperation:op];
}

-(void)addOperations:(NSArray<NSOperation *> *)ops waitUntilFinished:(BOOL)wait {
    for (NSOperation *op in ops) {
        [self addOperation:op];
    }
    
    if (wait) {
        for (NSOperation *op in ops) {
            [op waitUntilFinished];
        }
    }
}

-(void)addTask:(BaseTask *)task {
    [self addOperation:task];
}

-(void)addTasks:(NSArray<BaseTask *> *)tasks {
    [self addOperations:tasks waitUntilFinished:false];
}


-(void)terminate {
    self.isTerminated = YES;
    self.suspended = YES;
    [self cancelAllOperations];
}

@end
