//
//  Store.m
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import "Store.h"

@interface Store ()
@property (nonatomic,strong,readwrite) NSManagedObjectContext* mainManagedObjectContext;
@property (nonatomic,strong) NSManagedObjectModel* managedObjectModel;
@property (nonatomic,strong) NSPersistentStoreCoordinator* persistentStoreCoordinator;

@end

@implementation Store

+ (Store *)sharedInstance {
    static dispatch_once_t pred;
    static Store *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[Store alloc] init];
    });
    return shared;
}


+ (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [[Store sharedInstance] mainManagedObjectContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             [self.mainManagedObjectContext mergeChangesFromContextDidSaveNotification:note];
         }];
    }
    return self;
}


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)mainManagedObjectContext
{
    if (_mainManagedObjectContext != nil) {
        return _mainManagedObjectContext;
    }
    
    _mainManagedObjectContext = [[NSManagedObjectContext alloc] init];
    _mainManagedObjectContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    return _mainManagedObjectContext;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    // Default model
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    // Ensure a model is loaded
    if (!model) {
        [[NSException exceptionWithName:@"SJODataKitMissingModel" reason:@"You must provide a managed model." userInfo:nil] raise];
        return nil;
    }
    
	_managedObjectModel = model;
	return _managedObjectModel;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSDictionary *applicationInfo = [[NSBundle mainBundle] infoDictionary];
#if TARGET_OS_IPHONE
    NSString *applicationName = [applicationInfo objectForKey:@"CFBundleDisplayName"];
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
#else
    NSString *applicationName = [applicationInfo objectForKey:@"CFBundleName"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:applicationName];
    
    NSDictionary *properties = [applicationSupportURL resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:nil];
    if (!properties) {
        [fileManager createDirectoryAtPath:[applicationSupportURL path] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSURL *storeURL = [applicationSupportURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
#endif

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}



#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSManagedObjectContext*)privateContext
{
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[Store sharedInstance] persistentStoreCoordinator];
    return context;
}

@end

