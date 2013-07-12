//
//  NSManagedObject+Additions.h
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Additions)
+ (NSString *)entityName;
+ (NSEntityDescription *)entityWithContext:(NSManagedObjectContext *)context;
+ (instancetype) insertInContext:(NSManagedObjectContext*) context;
@end
