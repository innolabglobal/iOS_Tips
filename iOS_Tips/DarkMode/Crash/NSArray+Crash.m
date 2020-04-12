//
//  NSArray+Crash.m
//  DarkMode
//
//  Created by wsl on 2020/4/11.
//  Copyright © 2020 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "NSArray+Crash.h"
#import <objc/runtime.h>

@implementation NSArray (Crash)

+ (void)load {
    [super load];
    
    // 不可变数组
    // 越界保护
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndex:), NSClassFromString(@"__NSArrayI"), @selector(sl_objectAtIndex:));
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayI"), @selector(objectAtIndexedSubscript:), NSClassFromString(@"__NSArrayI"), @selector(sl_objectAtIndexedSubscript:));
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSSingleObjectArrayI"), @selector(objectAtIndex:), NSClassFromString(@"__NSSingleObjectArrayI"), @selector(sl_singleObjectAtIndex:));
    // nil值保护
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSPlaceholderArray"), @selector(initWithObjects:count:), NSClassFromString(@"__NSPlaceholderArray"), @selector(sl_initWithObjects:count:));
    
    
    // 不可变数组
    // 越界保护
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndex:), NSClassFromString(@"__NSArrayM"), @selector(sl_mObjectAtIndex:));
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndexedSubscript:), NSClassFromString(@"__NSArrayM"), @selector(sl_mObjectAtIndexedSubscript:));
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObject:atIndex:), NSClassFromString(@"__NSArrayM"), @selector(sl_insertObject:atIndex:));
    SL_ExchangeInstanceMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectsInRange:), NSClassFromString(@"__NSArrayM"), @selector(sl_removeObjectsInRange:));
    
    
    
}

#pragma mark - Help Methods
/*交换实例方法*/
void SL_ExchangeInstanceMethod(Class _originalClass ,SEL _originalSel, Class _targetClass, SEL _targetSel){
    Method methodOriginal = class_getInstanceMethod(_originalClass, _originalSel);
    Method methodNew = class_getInstanceMethod(_targetClass, _targetSel);
    BOOL didAddMethod = class_addMethod(_originalClass, _originalSel, method_getImplementation(methodNew), method_getTypeEncoding(methodNew));
    if (didAddMethod) {
        class_replaceMethod(_originalClass, _targetSel, method_getImplementation(methodOriginal), method_getTypeEncoding(methodOriginal));
    }else{
        method_exchangeImplementations(methodOriginal, methodNew);
    }
}
/*交换类方法*/
void SL_ExchangeClassMethod(Class _class ,SEL _originalSel,SEL _exchangeSel){
    Method methodOriginal = class_getClassMethod(_class, _originalSel);
    Method methodNew = class_getClassMethod(_class, _exchangeSel);
    method_exchangeImplementations(methodOriginal, methodNew);
}


#pragma mark - Array Safe Methods
//[array objectAtIndex:0] 越界
- (id)sl_objectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //可能抛出异常的代码
        @try {
            return [self sl_objectAtIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:数组越界 %@", exception.reason);
            return nil;
        }
    }else {
        return [self sl_objectAtIndex:index];
    }
}
// 越界
- (id)sl_singleObjectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //可能抛出异常的代码
        @try {
            return [self sl_singleObjectAtIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:数组越界 %@", exception.reason);
            return nil;
        }
    }else {
        return [self sl_singleObjectAtIndex:index];
    }
}
//array[0] 越界
- (id)sl_objectAtIndexedSubscript:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //记录错误
        //NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSArrayI objectAtIndexedSubscript:]: index %ld beyond bounds [0 .. %ld]'",(unsigned long)index,(unsigned long)self.count];
        @try {
            return [self sl_objectAtIndexedSubscript:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:数组越界 %@", exception.reason);
            return nil;
        }
    }
    return [self sl_objectAtIndexedSubscript:index];
}
// nil值
- (id)sl_initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt{
    NSUInteger index = 0;
    id _Nonnull objectsNew[cnt];
    for (int i = 0; i<cnt; i++) {
        if (objects[i]) {
            objectsNew[index] = objects[i];
            index++;
        }else{
            //记录错误
            NSString *errorInfo = [NSString stringWithFormat:@"异常:数组nil值 *** -[__NSPlaceholderArray initWithObjects:count:]: attempt to insert nil object from objects[%d]",i];
            NSLog(@"%@",errorInfo);
        }
    }
    return [self sl_initWithObjects:objectsNew count:index];
}

#pragma mark - MutableArray Safe Methods
//越界
- (id)sl_mObjectAtIndex:(NSInteger)index {
    if (index >= self.count || !self.count) {
        @try {
            return [self sl_mObjectAtIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:数组越界 %@", exception.reason);
            return nil;
        }
    }else {
        return [self sl_mObjectAtIndex:index];
    }
}
//越界
- (id)sl_mObjectAtIndexedSubscript:(NSInteger)index {
    if (index >= self.count || !self.count) {
        //记录错误
        //NSString *errorInfo = [NSString stringWithFormat:@"*** -[__NSArrayI objectAtIndexedSubscript:]: index %ld beyond bounds [0 .. %ld]'",(unsigned long)index,(unsigned long)self.count];
        @try {
            return [self sl_mObjectAtIndexedSubscript:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:数组越界 %@", exception.reason);
            return nil;
        }
    }
    return [self sl_mObjectAtIndexedSubscript:index];
}
//越界
- (void)sl_removeObjectsInRange:(NSRange)range {
    if (range.location+range.length>self.count) {
        NSString *errorInfo = [NSString stringWithFormat:@"异常:数组越界 *** -[__NSArrayM removeObjectsInRange:]: range {%ld, %ld} extends beyond bounds [0 .. %ld]",(unsigned long)range.location,(unsigned long)range.length,(unsigned long)self.count];
        NSLog(@"%@",errorInfo);
        return;
    }
    [self sl_removeObjectsInRange:range];
}
//越界 nil值
- (void)sl_insertObject:(id)object atIndex:(NSInteger)index {
    if (object == nil) {
        NSLog(@"异常:数组nil值 ***  -[__NSArrayM insertObject:atIndex:]: object cannot be nil");
        return;
    }
    if (index > self.count) {
        @try {
            return [self sl_insertObject:object atIndex:index];
        }
        @catch (NSException *exception) {
            NSLog(@"异常:数组越界 %@", exception.reason);
        }
    }else {
        [self sl_insertObject:object atIndex:index];;
    }
}

@end