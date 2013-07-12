//
//  NSManagedObject+Additions.m
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import "NSManagedObject+Additions.h"
#import "Store.h"

@implementation NSManagedObject (Additions)

+ (NSString *)entityName
{
	return NSStringFromClass(self);
}

+ (NSEntityDescription *)entityWithContext:(NSManagedObjectContext *)context
{
	return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
}

+ (instancetype) insertInContext:(NSManagedObjectContext *) context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                    inManagedObjectContext:context];
}


@end
