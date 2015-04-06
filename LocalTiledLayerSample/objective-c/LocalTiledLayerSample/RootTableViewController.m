// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import "RootTableViewController.h"
#import "LocalTiledLayerViewController.h"

#define kLocalTiledLayerViewControllerIdentifier @"LocalTiledLayerViewController"

@interface RootTableViewController()

//Array to hold the paths of tile packages in the app bundle
@property(nonatomic, strong) NSMutableArray *tilePackagesFromBundle;

//Array to hold the paths of tile packages, if exists, in the documents directory
@property(nonatomic, strong) NSMutableArray *tilePackagesFromDocuments;

@end

@implementation RootTableViewController
 
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //gets all the paths for the files with extension ".tpk" in the app bundle
    self.tilePackagesFromBundle = [NSMutableArray arrayWithArray:[[NSBundle mainBundle] pathsForResourcesOfType:@"tpk" inDirectory:@"/"]];
    
    //initialize the array
    self.tilePackagesFromDocuments = [[NSMutableArray alloc] init];
    
    //procedure to get all the tile packages from the documents directory, if any
    NSString *extension = @"tpk";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];    
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];  
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {        
        if ([[filename pathExtension] isEqualToString:extension]) {            
            [self.tilePackagesFromDocuments addObject:filename];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    //One section for the app bundle tile packages and the other one for the ones from documents directory
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return @"From App Bundle";
    }
    
    else
    {
        return @"From Documents Directory";
    }
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in each section depending on the respective array counts. 
    if(section == 0)
    {
        if([self.tilePackagesFromBundle count] > 0)
            return [self.tilePackagesFromBundle count];
        else
            return 1;
    }
  
    else
    {
        if([self.tilePackagesFromDocuments count] > 0)
            return [self.tilePackagesFromDocuments count];
        else
            return 1;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if(indexPath.section == 0)
    {
        if([self.tilePackagesFromBundle count] > 0)
        {
            //retrieves the file name from the array object according to the present cell index. 
            //gets only the file name without the extension for display. 
            NSString *fileName = [[[self.tilePackagesFromBundle objectAtIndex:indexPath.row] lastPathComponent] stringByDeletingPathExtension];
            cell.textLabel.text = fileName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }           
        else
            cell.textLabel.text = @"None found";
    }
    
    else
    {
        if([self.tilePackagesFromDocuments count] > 0)
        {
            //retrieves the file name from the array object according to the present cell index. 
            //gets only the file name without the extension for display. 
            NSString *fileName = [[[self.tilePackagesFromDocuments objectAtIndex:indexPath.row] lastPathComponent] stringByDeletingPathExtension];
            cell.textLabel.text = fileName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }   
        else
            cell.textLabel.text = @"None found";
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *tilePackage;
    if(indexPath.section == 0)
    {
        if([self.tilePackagesFromBundle count] > 0)
        {
            tilePackage = [self.tilePackagesFromBundle objectAtIndex:indexPath.row];
        }    
        else
            return;
    }
    
    else
    {
        if([self.tilePackagesFromDocuments count] > 0)
        {
            tilePackage = [self.tilePackagesFromDocuments objectAtIndex:indexPath.row];
        }
        else
            return;
    }

    //initializes the map controller with the appropriate tile package selected.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    LocalTiledLayerViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:kLocalTiledLayerViewControllerIdentifier];
    viewController.tilePackage = [tilePackage lastPathComponent];
    
    //sets the title of the map controller
    viewController.navigationItem.title = [[tilePackage lastPathComponent] stringByDeletingPathExtension];

                
    [self.navigationController pushViewController:viewController animated:YES];
     
}


@end
