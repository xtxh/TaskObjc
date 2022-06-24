# TaskObjc

[![Version](https://img.shields.io/cocoapods/v/TaskObjc.svg?style=flat)](https://cocoapods.org/pods/TaskObjc)
[![License](https://img.shields.io/cocoapods/l/TaskObjc.svg?style=flat)](https://cocoapods.org/pods/TaskObjc)
[![Platform](https://img.shields.io/cocoapods/p/TaskObjc.svg?style=flat)](https://cocoapods.org/pods/TaskObjc)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```
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
