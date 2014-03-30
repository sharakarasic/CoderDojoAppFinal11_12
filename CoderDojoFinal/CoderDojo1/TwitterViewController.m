//
//  TwitterViewController.m
//  CoderDojo1
//
//  Created by Scott Parris on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterViewController.h"
#import "TweetViewController.h"

@implementation TwitterViewController

@synthesize twitter, activityIndicator;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"Twitter", @"Twitter");
        self.tabBarItem.image = [UIImage imageNamed:@"twitter"];
        [self.tableView setRowHeight:110];
        [self getTweets];
        CGRect frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        [self.activityIndicator sizeToFit];
        self.activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | 
                                                   UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
        UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        loadingView.target = self;
        UIBarButtonItem *tweeter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeTweet:)];
        self.navigationItem.rightBarButtonItem = tweeter;
        UIBarButtonItem *refresh =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects: refresh, loadingView, nil];
        UILabel *label = [[UILabel alloc] init];
        self.navigationItem.titleView = label;
        label.text = @"";
        twitter = [[TWTweetComposeViewController alloc] init];
    }
    return self;
}

- (IBAction)refresh:(id)sender
{
    [self.activityIndicator startAnimating];
    NSLog(@"activityView=%@ isMainThread=%d", activityIndicator, [NSThread isMainThread]);
    [self getTweets];
    [self.tableView reloadData];
}

- (void)composeTweet:(id)sender
{
    // [twitter addImage:[UIImage imageNamed:@"coderdojo.png"]];
    // [twitter addURL:[NSURL URLWithString:[NSString stringWithString:@"http://coderdojo.com/"]]];
    [twitter setInitialText:@"#coderdojo"];
    __weak TWTweetComposeViewController *alertDelegate = twitter.self; 
    [self presentModalViewController:twitter animated:YES];
    twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) 
    {
        NSString *title = @"Tweet Status";
        NSString *msg; 
        
        if (result == TWTweetComposeViewControllerResultCancelled)
            msg = @"Tweet compostion was canceled.";
        else if (result == TWTweetComposeViewControllerResultDone)
            msg = @"Tweet composition completed.";
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:alertDelegate cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alertView show];
        
        // Dismiss the controller
        [alertDelegate dismissModalViewControllerAnimated:YES];
    };
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)getTweets
{
    TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://search.twitter.com/search.json?q=%23coderdojo"] parameters:nil requestMethod:TWRequestMethodGET];
    
    // Perform the request created above and create a handler block to handle the response.
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSString *output;
        if ([urlResponse statusCode] == 200) {
            // Parse the responseData, which we asked to be in JSON format for this request, into an NSDictionary using NSJSONSerialization.
            NSError *jsonParsingError = nil;
            NSDictionary *results = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonParsingError];
            NSArray *resultKeys = [results allKeys];
            tweets = [[NSMutableArray alloc] init];
            for (NSString *key in resultKeys) {
                if ([key isEqualToString:@"results"]) {
                    tweets = [results objectForKey:key];
                }
               // NSLog(@"meta key is %@ and obj %@", key, [results objectForKey:key]);            
            }
        } else {
            output = [NSString stringWithFormat:@"HTTP response status: %i\n", [urlResponse statusCode]];
        }
        [self.activityIndicator stopAnimating];
    }];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [tweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSDictionary *tweet = [tweets objectAtIndex:indexPath.row];
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[tweet objectForKey:@"profile_image_url"]]];
    cell.imageView.image = [UIImage imageWithData:imageData];
    cell.textLabel.text = [tweet objectForKey:@"from_user_name"];
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    cell.detailTextLabel.text = [tweet objectForKey:@"text"];
    [cell.detailTextLabel setNumberOfLines:6];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];        
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetViewController *tweetView = [[TweetViewController alloc] init];
    tweetView.tweet = [tweets objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:tweetView animated:YES];
}

@end
