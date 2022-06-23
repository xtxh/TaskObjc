//
//  Task.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "Task.h"
#import "TaskObserver.h"
#import "TaskCondition.h"

typedef enum : NSInteger {
    /// The initial, default state of the task.
    initialized,
    
    /// The task has been added to the queue and can start evaluating conditions.
    pending,
    
    /// The task is evaluating conditions.
    evaluatingConditions,
    
    /// The task’s conditions have all passed. Entering this state informs the queue the task is ready to execute.
    ready,
    
    /// The task is executing.
    executing,
    
    /// The task has stopped executing but hasn't notified the queue yet.
    finishing,
    
    /// The task has finished.
    finished,
} _TaskState;

/// Whether the state is allowed to transition to a target state.
static BOOL canTransitionToTargetState(_TaskState state, _TaskState targetState){
    switch (state) {
        case initialized:
            return targetState == pending;
        case pending:
            return targetState == evaluatingConditions || targetState == finishing;
        case evaluatingConditions:
            return targetState == ready;
        case ready:
            return targetState == executing || targetState == finishing;
        case executing:
            return targetState == finishing;
        case finishing:
            return targetState == finished;
        default: return NO;
    }
}

@interface Task () {
    dispatch_queue_t _evaluatedConditionsQueue;
    _TaskState _state;
    NSMutableArray *_errors;
}

@property (nonatomic, assign, readwrite) BOOL didFinishSuccessfully;
@property (nonatomic, strong, readwrite) NSMutableArray* conditions;
@property (nonatomic, strong, readwrite) NSMutableArray* observers;

@property (nonatomic, assign) BOOL hasEvaluatedConditions;
/// The array that backs the `errors` property.
@property (nonatomic, strong, readonly) NSMutableArray *errors;
/// Internal state var that backs the `state` property.
@property (nonatomic, assign, readonly) _TaskState state;
/// A lock to guard reading and writing the private `_state` property.
@property (nonatomic, strong) NSLock *stateLock;
/// A lock to guard reading and writing the `_errors` property.
@property (nonatomic, strong) NSLock *errorsLock;

@end

@implementation Task

-(instancetype)init {
    self = [super init];
    if (self) {
        self.didFinishSuccessfully = NO;
        self.conditions = [NSMutableArray arrayWithCapacity:0];
        self.observers = [NSMutableArray arrayWithCapacity:0];
        _errors = [NSMutableArray arrayWithCapacity:0];
        _state = initialized;
        self.errorsLock = [NSLock new];
        self.stateLock = [NSLock new];
        self.hasEvaluatedConditions = NO;
        _evaluatedConditionsQueue = dispatch_queue_create("task.evaluateCondition.privateQueue", NULL);
    }
    return self;
}

-(NSMutableArray *)errors {
    [self.errorsLock lock];
    NSMutableArray *errs = _errors;
    [self.errorsLock unlock];
    return errs;
}

-(void)setErrors:(NSMutableArray *)errors {
    [self.errorsLock lock];
    _errors = errors;
    [self.errorsLock unlock];
}

- (void) addError:(NSError *)error {
    [self addErrors:@[error]];
}

- (void) addErrors:(NSArray *)errors {
    [self.errorsLock lock];
    [_errors addObjectsFromArray:errors];
    [self.errorsLock unlock];
}

- (void)addCondition:(id<TaskCondition>)condition {
    NSAssert(self.state < evaluatingConditions, @"Cannot add conditions after condition evaluation has started.");
    [self.conditions addObject:condition];
}

-(void)addObserver:(id<TaskObserverProtocol>)observer {
    NSAssert(self.state < executing, @"Cannot add observers after starting execution.");
    [self.observers addObject:observer];
}


- (void) willEnqueue {
    self.state = pending;
}

- (void)start {
    [super start];
    
    if (self.isCancelled) {
        [self finishTaskWithErrors:nil];
    }
}

-(void)main {
    NSParameterAssert(self.state == ready);
    
    if (self.errors.count == 0 && !self.isCancelled) {
        self.state = executing;
        
        for (id<TaskObserverProtocol> observer in self.observers) {
            [observer taskDidStart:self];
        }
        
        [self execute];
    } else {
        [self finishTaskWithErrors:nil];
    }
    
}

- (void) execute {
    [self finishTaskWithErrors:nil];
}

- (void) spawnTask:(BaseTask *)task {
    for (id<TaskObserverProtocol> observer in self.observers) {
        [observer task:self didSpawnTask:task];
    }
}

- (void) cancelWithError:(NSError *)error {
    [self addError:error];
    [self cancel];
}

- (void) finishTaskWithErrors:(nullable NSArray<NSError *> *)errors {
    if (self.state >= finishing) return;
    self.state = finishing;
    
    NSMutableArray *allErrors = [NSMutableArray arrayWithArray:self.errors];
    if (errors && errors.count > 0) {
        [allErrors addObjectsFromArray:errors];
    }
    
    self.didFinishSuccessfully = allErrors.count == 0 && !self.isCancelled;
    
    for (id<TaskObserverProtocol> observer in self.observers) {
        [observer task:self didFinishWithErrors:allErrors];
    }
    
    [self finishedWithErrors:allErrors];
    
    self.state = finished;
}

- (void) finishedWithErrors:(NSArray<NSError *> *)errors {
    //subclass implement
}

- (nullable BaseTask *)typedDependency {
    NSArray *dependencies = self.dependencies;
    if (dependencies.count == 1) {
        return [dependencies firstObject];
    }
    return nil;
}

- (nullable Task *)successfulDependency {
    BaseTask *task = [self typedDependency];
    if (!task) return nil;
    if ([task isKindOfClass:Task.class]) {
        Task *fileListOperation = (Task *)task;
        if (fileListOperation.errors.count > 0) {
            return nil;
        } else {
            return fileListOperation;
        }
    }
    return nil;
}

- (void)evaluateConditions {
    dispatch_sync(_evaluatedConditionsQueue, ^{
        if (self.hasEvaluatedConditions) return;
        self.hasEvaluatedConditions = YES;
        NSParameterAssert(self.state == pending && !self.isCancelled);
        
        self.state = evaluatingConditions;
        __weak typeof(self) weakSelf = self;
        [TaskConditionEvaluator evaluateConditions:self.conditions forTask:self completion:^(NSArray * _Nonnull errors) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf addErrors:errors];
            strongSelf.state = ready;
        }];
    });
}

// Thread safe state property.
-(void)setState:(_TaskState)state {
    [self willChangeValueForKey:@"state"];
    
    [self.stateLock lock];
    if (_state == finished) {
        [self.stateLock unlock];
        return;
    }
    
    NSAssert(canTransitionToTargetState(_state, state), @"[Task] Invalid state transition");
    _state = state;
    [self.stateLock unlock];
    
    [self didChangeValueForKey:@"state"];
}

// Thread safe state property.
-(_TaskState)state {
    _TaskState value;
    [self.stateLock lock];
    value = _state;
    [self.stateLock unlock];
    return value;
}

// Changes to this property inform the queue the operation can be executed.
-(BOOL)isReady {
    // `isReady` signals to an operation queue that it is ready to be run. Once it returns true
    // the queue can execute the operation at any time. If an operation is cancelled it is
    // considered ready because there is nothing for the operation to do but progress through its
    // states and complete.
    switch (self.state) {
        case initialized:
            return self.isCancelled;
        case pending: {
            if (self.isCancelled) {
                return YES;
            }
            if ([super isReady]) {
                [self evaluateConditions];
            }
            return NO;
        }
        case ready:
            return [super isReady] || self.isCancelled;
        default: return NO;
    }
}

// Changes to this property inform the queue the operation is executing.
-(BOOL)isExecuting {
    return self.state == executing;
}

// Changes to this property inform the queue the operation is finished.
-(BOOL)isFinished {
    return self.state == finished;
}

// This tells any key-value observers for `isReady`, `isExecuting` or `isFinished`
// (i.e. the queue) that changes to the state property indicate changes to these properties.
+(NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"isReady"] || [key isEqualToString:@"isExecuting"] || [key isEqualToString:@"isFinished"]) {
        return [NSSet setWithObject:@"state"];
    }
    return [NSSet set];
}

@end
