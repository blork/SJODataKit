//
//  NSManagedObject+Additions.h
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Store.h"

@interface NSManagedObject (Additions)
+ (NSString *)entityName;
+ (NSEntityDescription *)entityWithContext:(NSManagedObjectContext *)context;
+ (instancetype) insertInContext:(NSManagedObjectContext*) context;
+ (void) insertOrUpdate:(NSArray*)dictArray
           forUniqueKey:(NSString*)key
              withBlock:(void (^) (NSDictionary* dictionary, NSManagedObject* object))block
                inStore:(Store *) store
                  error:(NSError*)error;
@end
