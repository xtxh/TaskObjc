# TaskObjc

[![Version](https://img.shields.io/cocoapods/v/TaskObjc.svg?style=flat)](https://cocoapods.org/pods/TaskObjc)
[![License](https://img.shields.io/cocoapods/l/TaskObjc.svg?style=flat)](https://cocoapods.org/pods/TaskObjc)
[![Platform](https://img.shields.io/cocoapods/p/TaskObjc.svg?style=flat)](https://cocoapods.org/pods/TaskObjc)

## Description
基于NSOperation的任务管理工具。通过添加条件（condition）和观察者（observer）来扩展NSOperation，子类只需要调用`- (void) execute;`方法，并且执行`- (void) finishTaskWithErrors:(nullable NSArray<NSError *> *)errors;`，即可自动管理任务状态。


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```

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

```

## Requirements

## Installation

TaskObjc is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TaskObjc'
```

## Usage

```objc

typedef enum : NSUInteger {
    PermissTypePush,
    PermissTypeCamera,
    PermissTypeMicrophone,
    PermissTypePhoto,
    PermissTypeLocation,
    PermissTypeBluetooth,
} PermissType;

@interface PermissTask : Task

@property(nonatomic, assign)PermissType type;

@end

@implementation PermissTask

-(void)execute {
    __weak typeof(self) weakSelf = self;
    switch (self.type) {
        case PermissTypeCamera:
        {
            AVAuthorizationStatus cameraAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (cameraAuthorizationStatus == AVAuthorizationStatusNotDetermined) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        [strongSelf finishTaskWithErrors:nil];
                    });
                }];
            } else {
                [self finishTaskWithErrors:nil];
            }
        }
            break;
        case PermissTypeMicrophone:
        {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf finishTaskWithErrors:nil];
            }];
        }
            break;
        case PermissTypePhoto:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf finishTaskWithErrors:nil];
            }];
        }
            break;
            
        default:
            [self finishTaskWithErrors:nil];
            break;
    }
}

@end

typedef enum : NSInteger {
    BizTypeOne,
    BizTypeTwo,
    BizTypeThree,
} BizType;

@interface BusinessTask : Task

@property(nonatomic, assign)BizType type;

@end

@implementation BusinessTask

-(void)execute {
    __weak typeof(self) weakSelf = self;
    
    void (^bizHandler)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, strongSelf.type * (NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [strongSelf finishTaskWithErrors:nil];
        });
    };
    
    void (^bizHandleError)(NSError *error) = ^(NSError *error){
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, strongSelf.type * (NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [strongSelf finishTaskWithErrors:@[error]];
        });
    };
    
    NSLog(@"BizType = %@", @(self.type));
    if (self.type == BizTypeTwo) {
        NSError *error = [[NSError alloc] initWithDomain:@"BizTaskErrorDomain" code:BizTypeTwo userInfo:@{NSLocalizedFailureReasonErrorKey: @"Business handler error"}];
        bizHandleError(error);
    } else {
        bizHandler();
    }
}

@end


@interface KEPViewController ()

@end

@implementation KEPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  TaskObserver *observer = [TaskObserver new];
  observer.finishHandler = ^(Task * _Nonnull task, NSArray<NSError *> * _Nonnull errors) {
      if (task.didFinishSuccessfully) {
          NSLog(@"task finish successfully!");
      } else {
          NSLog(@"task executed with errors: %@!", errors);
      }
  };
  
  NSArray *privacies = @[@(PermissTypePhoto), @(PermissTypeCamera), @(PermissTypeMicrophone)];
  NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:0];
  for (NSNumber *permiss in privacies) {
      PermissTask *task = [PermissTask new];
      task.type = permiss.intValue;
      [task addObserver:observer];
      [tasks addObject:task];
  }
  
  GroupTask *groupTask = [[GroupTask alloc] initWithTasks:tasks];
  
  for (BizType biz = BizTypeOne; biz <= BizTypeThree; biz++) {
      BusinessTask *bizTask = [BusinessTask new];
      bizTask.type = biz;
      [bizTask addObserver:observer];
      [groupTask addTask:bizTask];
  }
  TaskQueue *queue = [TaskQueue new];
  [queue addTask:groupTask];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

```

## Author

xtxh, xtxh@outlook.com

## License

TaskObjc is available under the MIT license. See the LICENSE file for more info.
