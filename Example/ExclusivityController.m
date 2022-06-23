//
//  ExclusivityController.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "ExclusivityController.h"

@interface ExclusivityController () {
    dispatch_queue_t _serialQueue;
    
}
@property (nonatomic, strong) NSMutableDictionary *operations;

@end

@implementation ExclusivityController

-(instancetype)init {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("com.ExclusivityController.queue", NULL);
        self.operations = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

+(instancetype)shared {
    static ExclusivityController *_controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = [[ExclusivityController alloc] init];
    });
    return _controller;
}

-(void)addTask:(Task *)task categories:(NSArray *)categories {
    dispatch_sync(_serialQueue, ^{
        for (NSString *category in categories) {
            NSMutableArray *categoryTasks = self.operations[category];
            if (!categoryTasks) categoryTasks = [NSMutableArray arrayWithCapacity:0];
            Task *lastTask = categoryTasks.lastObject;
            if (lastTask) {
                [task addDependency:lastTask];
            }
            [categoryTasks addObject:task];
            self.operations[category] = categoryTasks;
        }
    });
}

-(void)removeTask:(Task *)task categories:(NSArray *)categories {
    dispatch_sync(_serialQueue, ^{
        for (NSString *category in categories) {
            NSMutableArray *categoryTasks = self.operations[category];
            if (!categoryTasks || categoryTasks.count == 0) continue;
            if ([categoryTasks containsObject:task]) {
                [categoryTasks removeObject:task];
            }
            self.operations[category] = categoryTasks;
        }
    });
}

@end


@interface MutuallyExclusive ()

@property (nonatomic, copy) NSString *primaryCategory;
@property (nonatomic, copy, nullable) NSString *subCategory;

@end

@implementation MutuallyExclusive

-(instancetype)init {
    return [self initWithPrimaryCategory:@"ModalUI" subCategory:nil];
}

-(instancetype)initWithPrimaryCategory:(NSString *)primaryCategory subCategory:(NSString *)subCategory {
    self = [super init];
    if (self) {
        self.primaryCategory = primaryCategory;
        self.subCategory = subCategory;
    }
    return self;
}

-(NSString *)exclusivityKey {
    NSString *subCategory = self.subCategory ?: @"";
    return [NSString stringWithFormat:@"%@%@",self.primaryCategory, subCategory];
}

-(BaseTask *)dependencyForTask:(Task *)task {
    return nil;
}

-(void)evaluateForTask:(Task *)task completion:(void (^)(NSError * _Nullable))completion {
    completion(nil);
}

+(instancetype)modalUI {
    return [[MutuallyExclusive alloc] initWithPrimaryCategory:@"ModalUI" subCategory:nil];
}

@end
