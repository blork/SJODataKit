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

+ (void) insertOrUpdate:(NSArray*)dictArray
           forUniqueKey:(NSString*)key
              withBlock:(void (^) (NSDictionary* dictionary, NSManagedObject* object))block
                inStore:(Store *) store
                  error:(NSError*)error
{
    NSManagedObjectContext* context = [store privateContext];
    __block NSError *localError = nil;
    
    [context performBlockAndWait:^{
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
        NSArray* sortedResponse = [dictArray sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        NSArray* fetchedValues = [sortedResponse valueForKeyPath:key];
        
        // Create the fetch request to get all objects matching the unique key.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[self entityWithContext:context]];
        [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(%K IN %@)", key, fetchedValues]];
        
        [fetchRequest setSortDescriptors: @[sortDescriptor]];
        
        NSArray *objectsMatchingKey = [context executeFetchRequest:fetchRequest error:&localError];
        if (localError) {
            return;
        }
        
        NSEnumerator* objectEnumerator = [objectsMatchingKey objectEnumerator];
        NSEnumerator* dictionaryEnumerator = [sortedResponse objectEnumerator];
        
        NSDictionary* dictionary;
        id object = [objectEnumerator nextObject];

        while (dictionary = [dictionaryEnumerator nextObject]) {
            if (object != nil && [[object valueForKey:key] isEqualToString:dictionary[key]]) {
                if (block) {
                    block(dictionary, object);
                }
                object = [objectEnumerator nextObject];
            } else {
                id newObject = [object insertInContext:context];
                if (block) {
                    block(dictionary, newObject);
                }
            }
            
        }
        [context save:nil];
    }];
}


@end
