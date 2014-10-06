//
//  RecentViewController.m
//  OfflineGeocodingSample
//
//  Created by Divesh Goyal on 8/28/13.
//
//

#import "RecentViewController.h"

@interface RecentViewController ()

@property (nonatomic,copy) NSArray* items;

@end

@implementation RecentViewController

- (id)initWithItems:(NSArray*) items 
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.items = items;
    }
    return self;
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Recent Searches";
    
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    UIBarButtonItem* cancelBtn = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
     self.navigationItem.leftBarButtonItem = cancelBtn;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    cell.textLabel.text = self.items[indexPath.row];
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    self.completionBlock(self.items[indexPath.row]);
    
    
}

- (void)cancel : (id) sender{
    self.completionBlock(nil);
}

@end
