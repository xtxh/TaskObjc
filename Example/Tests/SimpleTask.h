//
//  SimpleTask.h
//  TasksTests
//
//  Created by keping on 2022/6/20.
//

#import <TaskObjc/Task.h>
#import <TaskObjc/TaskObjc.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    TaskErrorCodeUnknown = -1,
    TaskErrorCodeCancel = 1,
    TaskErrorCodeConditionFailed,
    TaskErrorCodeExecutionFailed,
} TaskErrorCode;

@interface SimpleTask : Task
@property (nonatomic, assign)BOOL taskComplete;
@property (nonatomic, strong)NSMutableArray *finishErrors;
@end

@interface PassFailCondition : NSObject <TaskCondition>

-(instancetype)initWithDependency:(nullable BaseTask *)dependency shouldPass:(BOOL)shouldPass;

@property (nonatomic, assign) BOOL shouldPass;
@property (nonatomic, strong, nullable) BaseTask *dependency;

@end

@interface SpawningTask : SimpleTask

@property (nonatomic, strong) BaseTask *spawnedTask;

-(instancetype)initWithSpawnTask:(BaseTask *)spawnedTask;

@end


NS_ASSUME_NONNULL_END
