//
//  TasksTests.m
//  TasksTests
//
//  Created by keping on 2022/6/20.
//

#import <XCTest/XCTest.h>
#import "SimpleTask.h"
#import <TaskObjc/TaskObjc.h>

@interface TasksTests : XCTestCase

@end

@implementation TasksTests

- (void)testSimpleOperation {
    
    XCTestExpectation *expectation = [XCTestExpectation new];
    
    SimpleTask *t1 = [SimpleTask new];
    __weak SimpleTask *weakT1 = t1;
    t1.completionBlock = ^{
        __strong SimpleTask *strongT1 = weakT1;
        XCTAssertTrue(strongT1.taskComplete);
        [expectation fulfill];
    };
    XCTAssertFalse(t1.taskComplete);
    
    TaskQueue *queue = [TaskQueue new];
    [queue addOperation:t1];
    
    [self waitForExpectations:@[expectation] timeout:1];
    
}


-(void)testObservers {
    XCTestExpectation *startExpectation = [[XCTestExpectation alloc] initWithDescription:@"start task"];
    XCTestExpectation *finishExpectation = [[XCTestExpectation alloc] initWithDescription:@"end task"];
    
    SimpleTask *t1 = [SimpleTask new];
    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:^(Task * _Nonnull task) {
        XCTAssertFalse(t1.taskComplete);
        [startExpectation fulfill];
    } spawnHandler:^(Task * _Nonnull task, BaseTask * _Nonnull newTask) {
        XCTAssertFalse(t1.taskComplete);
        [finishExpectation fulfill];
    } finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        XCTAssertTrue(t1.taskComplete);
        [finishExpectation fulfill];
    }];
    [t1 addObserver:observer];
    
    TaskQueue *queue = [TaskQueue new];
    [queue addOperation:t1];
    
    [self waitForExpectations:@[startExpectation, finishExpectation] timeout:1];
    
}

-(void)testFailingCondition {
    PassFailCondition *condition = [[PassFailCondition alloc] initWithDependency:nil shouldPass:false];
    XCTestExpectation *finishExpectation = [[XCTestExpectation alloc] initWithDescription:@"task end"];
    
    SimpleTask *t1 = [SimpleTask new];
    __weak SimpleTask *weakT1 = t1;
    t1.completionBlock = ^{
        __strong SimpleTask *strongT1 = weakT1;
        XCTAssertFalse(strongT1.taskComplete, @"Condition failure should prevent task from executing.");
        [finishExpectation fulfill];
    };
    [t1 addCondition:condition];
    
    XCTAssertFalse(t1.taskComplete);
    
    TaskQueue *queue = [TaskQueue new];
    [queue addOperation:t1];
    
    [self waitForExpectations:@[finishExpectation] timeout:1];
}


-(void)testPassingCondition {
    PassFailCondition *condition = [[PassFailCondition alloc] initWithDependency:nil shouldPass:true];
    XCTestExpectation *finishExpectation = [[XCTestExpectation alloc] initWithDescription:@"task end"];
    
    SimpleTask *t1 = [SimpleTask new];
    __weak SimpleTask *weakT1 = t1;
    t1.completionBlock = ^{
        __strong SimpleTask *strongT1 = weakT1;
        XCTAssertTrue(strongT1.taskComplete, @"Condition failure should not prevent task from executing.");
        [finishExpectation fulfill];
    };
    [t1 addCondition:condition];
    
    XCTAssertFalse(t1.taskComplete);
    
    TaskQueue *queue = [TaskQueue new];
    [queue addOperation:t1];
    
    [self waitForExpectations:@[finishExpectation] timeout:1];
    
}

-(void)testConditionWithDependency {
    XCTestExpectation *finishExpectation = [[XCTestExpectation alloc] initWithDescription:@"Main operation finished"];
    XCTestExpectation *dependencyFinishExpectation = [[XCTestExpectation alloc] initWithDescription:@"Dependent operation finished"];
    
    SimpleTask *t1 = [SimpleTask new];
    SimpleTask *dependentOperation = [SimpleTask new];
    
    PassFailCondition *condition = [[PassFailCondition alloc] initWithDependency:dependentOperation shouldPass:true];
    [t1 addCondition:condition];
    
    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        if ([task isEqual:t1]) {
            XCTAssertTrue(dependentOperation.taskComplete,@"Dependent operation should already be complete.");
            XCTAssertTrue(t1.taskComplete);
            [finishExpectation fulfill];
        } else if ([task isEqual:dependentOperation]) {
            XCTAssertTrue(dependentOperation.taskComplete, @"Dependent operation should execute.");
            XCTAssertFalse(t1.taskComplete, @"Main condition has not executed yet.");
            [dependencyFinishExpectation fulfill];
        }
    }];
    
    [t1 addObserver:observer];
    [dependentOperation addObserver:observer];
    
    XCTAssertFalse(t1.taskComplete);
    XCTAssertFalse(dependentOperation.taskComplete);
    
    TaskQueue *queue = [TaskQueue new];
    [queue addOperation:t1];
    
    [self waitForExpectations:@[finishExpectation, dependencyFinishExpectation] timeout:1];
}

-(void)testCancelWithError {
    XCTestExpectation *expectation = [XCTestExpectation new];
    SimpleTask *t1 = [SimpleTask new];
    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        XCTAssertEqual(1, errors.count);
        XCTAssertEqual(TaskErrorCodeCancel, errors[0].code);
        [expectation fulfill];
    }];
    [t1 addObserver:observer];
    
    TaskQueue *queue = [TaskQueue new];
    [queue addOperation:t1];
    
    [t1 cancelWithError:[[NSError alloc] initWithDomain:@"Task.Error" code:TaskErrorCodeCancel userInfo:@{NSLocalizedFailureReasonErrorKey: @"task error cancel!"}]];
    
    [self waitForExpectations:@[expectation] timeout:1];
}


-(void)testSpawnedOperation {
    XCTestExpectation *spawnedExpectation = [[XCTestExpectation alloc] initWithDescription:@"Spawned operation finished."];
    XCTestExpectation *originalExpectation = [[XCTestExpectation alloc] initWithDescription:@"Original operation finished."];
    
    SimpleTask *spawnTask = [SimpleTask new];
    SpawningTask *originalTask = [[SpawningTask alloc] initWithSpawnTask:spawnTask];
    
    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        if ([task isEqual:originalTask]) {
            XCTAssertTrue(originalTask.taskComplete);
            XCTAssertFalse(spawnTask.taskComplete);
            [originalExpectation fulfill];
        } else if ([task isEqual:spawnTask]) {
            XCTAssertTrue(originalTask.taskComplete);
            XCTAssertTrue(spawnTask.taskComplete);
            [spawnedExpectation fulfill];
        }
    }];
    [originalTask addObserver:observer];
    [spawnTask addObserver:observer];
    
    TaskQueue *queue = [TaskQueue new];
    [queue addTask:originalTask];
    
    [self waitForExpectations:@[spawnedExpectation, originalExpectation] timeout:1];
}

-(void)testFinishedSuccessfullyNoErrors {
    SimpleTask *t1 = [SimpleTask new];
    
    XCTAssertFalse(t1.didFinishSuccessfully);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"operation finished"];
    
    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        XCTAssertTrue(task.didFinishSuccessfully);
        [expectation fulfill];
    }];
    [t1 addObserver:observer];
    
    TaskQueue *queue = [TaskQueue new];
    [queue addTask:t1];
    
    [self waitForExpectations:@[expectation] timeout:1];
}

-(void)testFinishedSuccessfullyCancelled {
    SimpleTask *t = [SimpleTask new];
    
    XCTAssertFalse(t.didFinishSuccessfully);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"operation finished"];
    [t addObserver:[[TaskObserver alloc] initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        XCTAssertFalse(task.didFinishSuccessfully);
        [expectation fulfill];
    }]];
    
    TaskQueue *queue = [TaskQueue new];
    queue.suspended = YES;
    [queue addTask:t];
    [t cancel];
    queue.suspended = NO;
    
    [self waitForExpectations:@[expectation] timeout:1];
}

-(void)testFinishedSuccessfullyWithErrors {
    SimpleTask *t = [SimpleTask new];
    
    XCTAssertFalse(t.didFinishSuccessfully);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"operation finished"];
    [t addObserver:[[TaskObserver alloc]initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        XCTAssertFalse(t.didFinishSuccessfully);
        [expectation fulfill];
    }]];
    
    TaskQueue *queue = [TaskQueue new];
    queue.suspended = YES;
    [queue addTask:t];
    [t addError:[[NSError alloc]initWithDomain:@"Task.error" code:TaskErrorCodeConditionFailed userInfo:@{NSLocalizedFailureReasonErrorKey:@"task.condition.failed"}]];
    queue.suspended = NO;
    
    [self waitForExpectations:@[expectation] timeout:1];
}


- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
