//
//  TaskObjc.h
//  Tasks
//
//  Created by keping on 2022/6/20.
//

#import <Foundation/Foundation.h>

#if __has_include(<TaskObjc/TaskObjc.h>)
FOUNDATION_EXPORT double TaskObjcVersionNumber;
FOUNDATION_EXPORT const unsigned char TaskObjcVersionString[];
#import <TaskObjc/Task.h>
#import <TaskObjc/BlockTask.h>
#import <TaskObjc/GroupTask.h>
#import <TaskObjc/TaskCondition.h>
#import <TaskObjc/TaskObserver.h>
#import <TaskObjc/TaskQueue.h>
#import <TaskObjc/ExclusivityController.h>
#else
#import "Task.h"
#import "BlockTask.h"
#import "GroupTask.h"
#import "TaskCondition.h"
#import "TaskObserver.h"
#import "TaskQueue.h"
#import "ExclusivityController.h"
#endif
