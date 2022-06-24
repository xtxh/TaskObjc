//
//  GroupTaskTest.m
//  TasksTests
//
//  Created by keping on 2022/6/21.
//

#import <XCTest/XCTest.h>
#import "SimpleTask.h"
#import <TaskObjc/TaskObjc.h>

@interface GroupTaskTest : XCTestCase

@end

@implementation GroupTaskTest

-(void)testGroupOperation {
  XCTestExpectation *expectation1 = [self expectationWithDescription:@"first task finished"];
  XCTestExpectation *expectation2 = [self expectationWithDescription:@"second task finished"];
  XCTestExpectation *expectation3 = [self expectationWithDescription:@"third task finished"];
  
  SimpleTask *t1 = [SimpleTask new];
  __weak SimpleTask *weakT1 = t1;
  t1.completionBlock = ^{
    __strong SimpleTask *strongT1 = weakT1;
    XCTAssertTrue(strongT1.taskComplete);
    [expectation1 fulfill];
  };
  
  __block BOOL t2Completed = NO;
  BaseBlockTask *t2 = [BaseBlockTask blockOperationWithBlock:^{
    t2Completed = YES;
  }];
  t2.completionBlock = ^{
    XCTAssertTrue(t2Completed);
    [expectation2 fulfill];
  };
  
  SimpleTask *t3 = [SimpleTask new];
  __weak SimpleTask *weakT3 = t3;
  t3.completionBlock = ^{
    __strong SimpleTask *strongT3 = weakT3;
    XCTAssertTrue(strongT3.taskComplete);
    [expectation3 fulfill];
  };
  
  //GroupTask *groupTask = [[GroupTask alloc] initWithTasks:@[t1, t2, t3]];
  GroupTask *groupTask = [GroupTask new];
  [groupTask addTasks:@[t1, t2, t3]];
  TaskQueue *queue = [TaskQueue new];
  [queue addTask:groupTask];
  
  [self waitForExpectations:@[expectation1, expectation2, expectation3] timeout:1];
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
