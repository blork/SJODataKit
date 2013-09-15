//
//  NSManagedObject+Additions.m
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import "NSManagedObject+SJODataKitAdditions.h"
#import "SJODataStore.h"

@implementation NSManagedObject (SJODataKitAdditions)

+ (NSString *)entityName
{
	return NSStringFromClass(self);
}

+ (NSEntityDescription *)entityWithContext:(NSManagedObjectContext *)context
{
	return [NSEntityDescription entityForName:[[self class] entityName] inManagedObjectContext:context];
}

+ (instancetype) insertInContext:(NSManagedObjectContext *) context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[[self class] entityName]
                                         inManagedObjectContext:context];
}

+ (instancetype)findByKey:(NSString *)key value:(id)value inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", key, value];
    NSFetchRequest *request = [[self class] fetchRequest];
    [request setFetchLimit:1];
    [request setPredicate:predicate];
    NSArray *matching = [context executeFetchRequest:request error:nil];
    return [matching lastObject];
}

+ (instancetype)findOrInsertByKey:(NSString *)key value:(id)value inContext:(NSManagedObjectContext *)context
{
    id object = [[self class] findByKey:key value:value inContext:context];
    if (!object) {
        object = [[self class] insertInContext:context];
        [object setValue:value forKey:key];
    }
    return object;
}

+(NSFetchRequest*) fetchRequest
{
    return [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
}

+(NSFetchRequest*) fetchRequestWithPredicate:(NSPredicate*)predicate
{
    NSFetchRequest* fetchRequest = [[self class] fetchRequest];
    [fetchRequest setPredicate:predicate];
    return fetchRequest;
}


+(NSArray*) executeFetchRequestWithPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*) context error:(NSError **)error
{
    NSFetchRequest* fetchRequest = [[self class] fetchRequest];
    [fetchRequest setPredicate:predicate];
    return [context executeFetchRequest:fetchRequest error:error];
}

+ (void) insertOrUpdate:(NSArray*)dictArray
           forUniqueKey:(NSString*)key
              withBlock:(void (^) (NSDictionary* dictionary, id managedObject))block
                inStore:(SJODataStore *) store
                  error:(NSError*)error
{
    NSManagedObjectContext* context = [store newPrivateContext];
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
                id newObject = [[self class] insertInContext:context];
                if (block) {
                    block(dictionary, newObject);
                }
            }
            
        }
        [context save:nil];
    }];
}

-(void)delete
{
    [self.managedObjectContext deleteObject:self];
}


+(void)deleteAllInStore:(SJODataStore*) store error:(NSError*)error
{
    __block NSError *localError = nil;
    NSManagedObjectContext* deletionContext = [store newPrivateContext];
    [deletionContext performBlockAndWait:^{
        NSFetchRequest *fetch = [[self class] fetchRequest];
        [fetch setIncludesPropertyValues:NO];
        NSArray *result = [deletionContext executeFetchRequest:fetch error:nil];
        for (NSManagedObject* object in result) {
            [deletionContext deleteObject:object];
        }
        [deletionContext save:&localError];
    }];
    error = localError;
}

@end
