//
//  SimpleTask.m
//  TasksTests
//
//  Created by keping on 2022/6/20.
//

#import "SimpleTask.h"

@implementation SimpleTask

-(instancetype)init {
    self = [super init];
    if (self) {
        self.taskComplete = NO;
        self.finishErrors = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

-(void)execute {
    self.taskComplete = YES;
    [self finishTaskWithErrors:nil];
}

-(void)finishedWithErrors:(NSArray<NSError *> *)errors {
    [self.finishErrors addObjectsFromArray:errors];
}


@end

@implementation PassFailCondition

-(instancetype)initWithDependency:(BaseTask *)dependency shouldPass:(BOOL)shouldPass {
    self = [super init];
    if (self) {
        self.dependency = dependency;
        self.shouldPass = shouldPass;
    }
    return self;
}

-(NSString *)exclusivityKey {
    return nil;
}

-(BaseTask *)dependencyForTask:(Task *)task {
    return self.dependency;
}

-(void)evaluateForTask:(Task *)task completion:(void (^)(NSError * _Nullable))completion {
    if (self.shouldPass) {
        completion(nil);
    } else {
        NSError *error = [[NSError alloc] initWithDomain:@"error" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: @"PassFail.Condition.error"}];
        completion(error);
    }
}

@end

@implementation SpawningTask

-(instancetype)initWithSpawnTask:(BaseTask *)spawnedTask {
    self = [super init];
    if (self) {
        self.spawnedTask = spawnedTask;
    }
    return self;
}

-(void)finishedWithErrors:(NSArray<NSError *> *)errors {
    [self spawnTask:self.spawnedTask];
}

@end
