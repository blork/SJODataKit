//
//  Store.h
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJODataStore : NSObject

- (void) save;
- (NSManagedObjectContext*) privateContext;
- (NSManagedObjectContext*) mainContext;

@end
