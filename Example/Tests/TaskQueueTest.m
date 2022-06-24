//
//  TaskQueueTest.m
//  TasksTests
//
//  Created by keping on 2022/6/21.
//

#import <XCTest/XCTest.h>
#import <TaskObjc/TaskObjc.h>

@interface TaskQueueTest : XCTestCase

@property(nonatomic, strong) TaskQueue *taskQueue;

@end

@implementation TaskQueueTest

-(void)testMutualExclusivity {
    BlockTask *t1 = [self blockOperationWithDelay];
    BlockTask *t2 = [self blockOperationWithDelay];
    BlockTask *t3 = [self blockOperationWithDelay];
    
    MutuallyExclusive *mutualExclusivityCondition = [[MutuallyExclusive alloc] initWithPrimaryCategory:@"TEST_CATEGORY" subCategory:@"FOO"];
    [t1 addCondition:mutualExclusivityCondition];
    [t2 addCondition:mutualExclusivityCondition];
    [t3 addCondition:mutualExclusivityCondition];
    
    __block NSTimeInterval t1EndTime = 0;
    __block NSTimeInterval t2StartTime = 0;
    __block NSTimeInterval t2EndTime = 0;
    __block NSTimeInterval t3StartTime = 0;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Last operation finished."];
    
    [t1 addObserver:[[TaskObserver alloc]initWithStartHandler:nil spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        t1EndTime = [NSDate timeIntervalSinceReferenceDate];
    }]];
    [t2 addObserver:[[TaskObserver alloc]initWithStartHandler:^(Task * _Nonnull task) {
        t2StartTime = [NSDate timeIntervalSinceReferenceDate];
    } spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        t2EndTime = [NSDate timeIntervalSinceReferenceDate];
    }]];
    
    [t3 addObserver:[[TaskObserver alloc]initWithStartHandler:^(Task * _Nonnull task) {
        t3StartTime = [NSDate timeIntervalSinceReferenceDate];
    } spawnHandler:nil finishHandler:^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
        [expectation fulfill];
    }]];
    
    [self.taskQueue addTasks:@[t1, t2, t3]];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssertTrue(t2StartTime > t1EndTime);
    XCTAssertTrue(t3StartTime > t2EndTime);
    
    NSLog(@"t1EndTime = %@, t2StartTime = %@, t2EndTime = %@, t3StartTime = %@", @(t1EndTime), @(t2StartTime), @(t2EndTime), @(t3StartTime));
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.taskQueue = [TaskQueue new];
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

-(BlockTask *)blockOperationWithDelay {
    BlockTask *task = [[BlockTask alloc] initWithBlock:^(void (^block)(void)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)0.1 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block();
        });
    }];
    return task;
}

@end
