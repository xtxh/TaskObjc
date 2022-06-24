//
//  TaskCondition.m
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import "TaskCondition.h"

@implementation TaskConditionEvaluator

+(void)evaluateConditions:(NSArray *)conditions forTask:(Task *)task completion:(void (^)(NSArray * _Nonnull))completion {
    if (conditions.count == 0) {
        completion(@[]);
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
    for (id<TaskCondition> condition in conditions) {
        dispatch_group_enter(group);
        [condition evaluateForTask:task completion:^(NSError * _Nullable error) {
            if (error) {
                [results addObject:error];
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        completion(results);
    });
}

@end
