//
//  BlockObserverTest.m
//  TasksTests
//
//  Created by keping on 2022/6/21.
//

#import <XCTest/XCTest.h>
#import "SimpleTask.h"
#import <TaskObjc/TaskObjc.h>

@interface TestTask : Task

@end

@implementation TestTask

-(void)execute {
    Task *spawnedTask = [Task new];
    spawnedTask.name = @"SpawnedTask";
    [self spawnTask:spawnedTask];
    
    [self finishTaskWithErrors:nil];
}

@end

@interface BlockObserverTest : XCTestCase

@property (nonatomic, strong) TaskQueue *taskQueue;

@end

@implementation BlockObserverTest

-(void)testStartAndFinishHandlersNotCancelled {
    TestTask *t = [TestTask new];
    
    XCTestExpectation *startExpectation = [self expectationWithDescription:@"start"];
    XCTestExpectation *spaenExpectation = [self expectationWithDescription:@"spawn"];
    XCTestExpectation *finishExpectation = [self expectationWithDescription:@"finish"];
    
    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:^(Task * _Nonnull task) {
        [startExpectation fulfill];
    } spawnHandler:^(Task * _Nonnull task, BaseTask * _Nonnull newTask) {
        [spaenExpectation fulfill];
    } finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        [finishExpectation fulfill];
    }];
    
    [t addObserver:observer];
    
    [self.taskQueue addTask:t];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}


-(void)testStartAndFinishHandlersCancelled {
    self.taskQueue.suspended = YES;
    
    TestTask *t = [TestTask new];
    
    XCTestExpectation *startExp = [self expectationWithDescription:@"start"];
    XCTestExpectation *spawnExp = [self expectationWithDescription:@"spawn"];
    XCTestExpectation *finishExp = [self expectationWithDescription:@"finsih"];
    
    startExp.inverted = YES;
    spawnExp.inverted = YES;
    
//    TaskObserver *observer = [[TaskObserver alloc] initWithStartHandler:^(Task * _Nonnull task) {
//        [startExp fulfill];
//    } spawnHandler:^(Task * _Nonnull task, BaseTask * _Nonnull newTask) {
//        [spawnExp fulfill];
//    } finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
//        [finishExp fulfill];
//    }];
//    [t addObserver:observer];
    
    TaskObserver * observer = [TaskObserver new];
    observer.startHandler = ^(Task * _Nonnull task) {
        [startExp fulfill];
    };
    observer.spawnHandler = ^(Task * _Nonnull task, BaseTask * _Nonnull newTask) {
        [spawnExp fulfill];
    };
    observer.finishHandler = ^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        [finishExp fulfill];
    };
    [t addObserver:observer];
    
    [self.taskQueue addTask:t];
    
    [t cancel];
    
    self.taskQueue.suspended = NO;
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
    
}

- (void)setUp {
    self.taskQueue = [TaskQueue new];
    
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
