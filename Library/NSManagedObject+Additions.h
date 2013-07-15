//
//  NSManagedObject+Additions.h
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "SJODataStore.h"

@interface NSManagedObject (Additions)
+ (NSString *)entityName;
+ (NSEntityDescription *)entityWithContext:(NSManagedObjectContext *)context;
+ (instancetype) insertInContext:(NSManagedObjectContext*) context;
+ (NSFetchRequest*) fetchRequest;
+ (void) insertOrUpdate:(NSArray*)dictArray
           forUniqueKey:(NSString*)key
              withBlock:(void (^) (NSDictionary* dictionary, id managedObject))block
                inStore:(SJODataStore *) store
                  error:(NSError*)error;
@end
