//
//  ExampleViewController.m
//  SJODataKitExample
//
//  Created by Sam Oakley on 15/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import "ExampleViewController.h"
#import "Post.h"
#import "SJODataKit.h"

@interface ExampleViewController ()

@end

@implementation ExampleViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"SJODataKit Example";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Insert/Update" style:UIBarButtonItemStylePlain target:self action:@selector(insertUpdateExample)];
    
    
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertExample)],
                                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAllExample)]
                                                ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void) insertExample
{
    // On the main thread. Not recommended.
    NSManagedObjectContext* context = [self.store mainContext];
    Post* post = [Post insertInContext:context];
    post.title = [[NSUUID UUID] UUIDString];
    [context save:nil];
}


-(void) insertUpdateExample
{
    NSArray* data = @[
                      @{@"title": @"All the Mashed Potatoes"},
                      @{@"title": @"Google Versus"},
                      @{@"title": @"Facebook Home and Dogfooding"},
                      @{@"title": @"Web Apps vs. Native Apps Is Still a Thing"},
                      @{@"title": @"If Not for Android, Where Would the iPhone Be?"},
                      @{@"title": @"Pricing and Profit Consistency and the Halo Effect"},
                      @{@"title": @"Everything Else"},
                      @{@"title": @"Ceding the Crown"},
                      @{@"title": @"Open and Shut"}
                      ];
    [Post insertOrUpdate:data
            forUniqueKey:@"title"
               withBlock:^(NSDictionary *dictionary, Post* managedObject) {
                   managedObject.title = dictionary[@"title"];
               }
                 inStore:self.store
                   error:nil];
}


-(void) deleteAllExample
{
    __weak SJODataStore* store = self.store;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext* context = [store privateContext];
        [context performBlock:^{
            NSFetchRequest* fetchRequest = [Post fetchRequest];
            NSArray* allPosts = [context executeFetchRequest:fetchRequest error:nil];
            for (Post* post in allPosts) {
                [context deleteObject:post];
            }
            [context save:nil];
        }];
    });
}


#pragma mark - Table view

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView] configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Post *post = [[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];
        [self.store.mainContext deleteObject:post];
    }

}

#pragma mark - SJOSearchableFetchedResultsController

-(NSFetchRequest *)fetchRequestForSearch:(NSString *)searchString
{
    
    NSFetchRequest* fetchRequest = [Post fetchRequest];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    NSPredicate* filterPredicate = nil;
    if(searchString.length)
    {
        filterPredicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchString];
    }
    
    [fetchRequest setPredicate:filterPredicate];
    return fetchRequest;
}


-(void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = post.title;
}

@end
