//
//  SJOSearchableFetchedResultsController.h
//
//  Created by Sam Oakley on 15/07/2013.
//  Copyright (c) 2013 Sam Oakley. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SJODataStore;

@interface SJOSearchableFetchedResultsController : UITableViewController<UISearchBarDelegate, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) SJODataStore *store;
@property (strong, nonatomic) UISearchDisplayController *searchController;

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (NSFetchRequest *)fetchRequestForSearch:(NSString *)searchString;
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView;

@end
