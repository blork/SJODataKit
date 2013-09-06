//
//  Store.m
//
//  Created by Sam Oakley on 10/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import "SJODataStore.h"

@interface SJODataStore ()
@property (nonatomic,strong,readwrite) NSManagedObjectContext* mainContext;
@property (nonatomic,strong) NSManagedObjectModel* managedObjectModel;
@property (nonatomic,strong) NSPersistentStoreCoordinator* persistentStoreCoordinator;

-(void)initialiseStackWithBlock:(void (^)(BOOL))block;
@end

@implementation SJODataStore

- (id)initWithInitialisationBlock:(void (^)(BOOL))block
{
    self = [super init];
    if (self) {
        [self initialiseStackWithBlock:block];
        
        SJODataStore* weakSelf = self;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             [weakSelf.mainContext mergeChangesFromContextDidSaveNotification:note];
         }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             [weakSelf.mainContext mergeChangesFromContextDidSaveNotification:note];
//             block(YES);
         }];
        
    }
    return self;
}


- (void)save
{
    NSError *error = nil;
    if (_mainContext != nil) {
        if ([_mainContext hasChanges] && ![_mainContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSManagedObjectContext*)privateContext
{
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [self persistentStoreCoordinator];
    return context;
}


//// Returns the managed object context for the application.
//// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
//- (NSManagedObjectContext *)mainContext
//{
//    if (_mainContext != nil) {
//        return _mainContext;
//    }
//
//    _mainContext = [[NSManagedObjectContext alloc] init];
//    _mainContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
//    return _mainContext;
//}


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




//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
//{
//    if (_persistentStoreCoordinator != nil) {
//        return _persistentStoreCoordinator;
//    }
//
//    NSDictionary *applicationInfo = [[NSBundle mainBundle] infoDictionary];
//#if TARGET_OS_IPHONE
//    NSString *applicationName = [applicationInfo objectForKey:@"CFBundleDisplayName"];
//    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
//#else
//    NSString *applicationName = [applicationInfo objectForKey:@"CFBundleName"];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
//    applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:applicationName];
//
//    NSDictionary *properties = [applicationSupportURL resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:nil];
//    if (!properties) {
//        [fileManager createDirectoryAtPath:[applicationSupportURL path] withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//
//    NSURL *storeURL = [applicationSupportURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
//#endif
//
//    NSError *error = nil;
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
//                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
//
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
//
//    return _persistentStoreCoordinator;
//}




-(void)initialiseStackWithBlock:(void (^)(BOOL))block
{
    NSManagedObjectModel *mom = [self managedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
    [moc setPersistentStoreCoordinator:psc];
    
    self.mainContext = moc;
    
    
    dispatch_queue_t queue;
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSDictionary *applicationInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *applicationName = [applicationInfo objectForKey:@"CFBundleName"];
        
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        [options setValue:[NSNumber numberWithBool:YES]
                   forKey:NSMigratePersistentStoresAutomaticallyOption];
        [options setValue:[NSNumber numberWithBool:YES]
                   forKey:NSInferMappingModelAutomaticallyOption];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
        if (cloudURL) {
            NSLog(@"iCloud enabled: %@", cloudURL);
            cloudURL = [cloudURL URLByAppendingPathComponent:applicationName];
            [options setValue:applicationName forKey:NSPersistentStoreUbiquitousContentNameKey];
            [options setValue:cloudURL forKey:NSPersistentStoreUbiquitousContentURLKey];
        } else {
            NSLog(@"iCloud is not enabled");
        }
        
        
        NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
        applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:applicationName];
        
        NSDictionary *properties = [applicationSupportURL resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:nil];
        if (!properties) {
            [fileManager createDirectoryAtPath:[applicationSupportURL path] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSURL *storeURL = [applicationSupportURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
        
        NSError *error = nil;
        NSPersistentStoreCoordinator *coordinator = self.mainContext.persistentStoreCoordinator;
        NSPersistentStore *store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                             configuration:nil
                                                                       URL:storeURL
                                                                   options:options
                                                                     error:&error];
        if (!store) {
            NSLog(@"Error adding persistent store to coordinator %@\n%@",
                  [error localizedDescription], [error userInfo]);
            abort();
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) block(YES);
        });
    });
    
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end

