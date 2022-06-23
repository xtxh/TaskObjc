//
//  GroupTask.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "GroupTask.h"
#import "BlockTask.h"

@interface GroupTask () {
    NSMutableArray<NSError *> *_groupErrors;
}

@property (nonatomic, strong) TaskQueue *internalQueue;
@property (nonatomic, strong) NSBlockOperation *startingTask;
@property (nonatomic, strong) NSBlockOperation *finishingTask;
@property (nonatomic, strong) NSLock *groupErrorsLock;
/// Each member task's errors will aggregate in this array.
@property (nonatomic, strong) NSMutableArray<NSError *> *groupErrors;

@end

@implementation GroupTask

-(instancetype)initWithTasks:(NSArray<BaseTask *> *)tasks {
    self = [super init];
    if (self) {
        [self groupConfigs];
        for (BaseTask *task in tasks) {
            [self.internalQueue addTask:task];
        }
    }
    return self;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self groupConfigs];
    }
    return self;
}

-(void)groupConfigs {
    self.internalQueue = [TaskQueue new];
    self.startingTask = [NSBlockOperation blockOperationWithBlock:^{}];
    self.finishingTask = [NSBlockOperation blockOperationWithBlock:^{}];
    self.groupErrorsLock = [NSLock new];
    _groupErrors = [NSMutableArray arrayWithCapacity:0];
    
    // Suspend the queue initially so we control its execution.
    self.internalQueue.suspended = YES;
    self.internalQueue.delegate = self;
    
    // All added tasks will be dependent on the starting task. This task gives us
    // control over exactly when the other tasks begin.
    [self.internalQueue addTask:self.startingTask];
}

-(void)cancel {
    [self.internalQueue cancelAllOperations];
    [super cancel];
}

-(void)cancelWithError:(NSError *)error {
    [self.internalQueue cancelAllOperations];
    [super cancelWithError:error];
}

-(void)configureTasksBeforeExecution {}

-(void)execute {
    [self configureTasksBeforeExecution];
    self.internalQueue.suspended = false;
    // The group task cannot finish without the finishing task.
    [self.internalQueue addTask:self.finishingTask];
}

-(void)addTask:(BaseTask *)task {
    NSAssert(!self.isFinished, @"Cannot add tasks after the group has finished.");
    [self.internalQueue addOperation:task];
}

-(void)addTasks:(NSArray<BaseTask *> *)tasks {
    NSAssert(!self.isFinished, @"Cannot add tasks after the group has finished.");
    [self.internalQueue addOperations:tasks waitUntilFinished:false];
}

/// Adds an error to the aggregated group errors.
-(void)addError:(NSError *)error {
    [self addErrors:@[error]];
}

/// Adds the errors to the aggregated group errors.
-(void)addErrors:(NSArray *)errors {
    [self.groupErrorsLock lock];
    [_groupErrors addObjectsFromArray:errors];
    [self.groupErrorsLock unlock];
}

-(void)taskDidFinish:(BaseTask *)task withErrors:(NSArray<NSError *> *)erros {}

-(void)setGroupErrors:(NSMutableArray<NSError *> *)groupErrors {
    [self.groupErrorsLock lock];
    _groupErrors = groupErrors;
    [self.groupErrorsLock unlock];
}

-(NSMutableArray<NSError *> *)groupErrors {
    [self.groupErrorsLock lock];
    NSMutableArray *errs = _groupErrors;
    [self.groupErrorsLock unlock];
    return errs;
}

-(void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    self.internalQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

-(NSInteger)maxConcurrentOperationCount {
    return self.internalQueue.maxConcurrentOperationCount;
}

#pragma mark - OperationQueueDelegate

-(void)taskQueue:(TaskQueue *)queue willAddTask:(BaseTask *)task {
    NSAssert(!self.finishingTask.isFinished && !self.finishingTask.isExecuting, @"Cannot add operations to a group after the group has completed.");
    
    // The finishing task can't execute until all other tasks are finished. This includes
    // any tasks spawned by the initial tasks.
    if (![task isEqual:self.finishingTask]) {
        [self.finishingTask addDependency:task];
    }
    
    // All tasks are dependent on `startingtask`. This ensures that no tasks or
    // condition evaluations occur before the group task is executing.
    if (![task isEqual:self.startingTask]) {
        [task addDependency:self.startingTask];
    }
}

-(void)taskQueue:(TaskQueue *)queue didFinishedTask:(BaseTask *)task withErrors:(NSArray<NSError *> *)errors {
    [self addErrors:errors];
    
    if ([task isEqual:self.finishingTask]) {
        // The group of tasks has completed.
        self.internalQueue.suspended = YES;
        [self finishTaskWithErrors:self.groupErrors];
    } else if (![task isEqual:self.startingTask]) {
        // Notify finished tasks for interested subclasses.
        [self taskDidFinish:task withErrors:errors];
    }
}

@end
