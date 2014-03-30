//
//  TwitterViewController.h
//  CoderDojo1
//
//  Created by Scott Parris on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Twitter/Twitter.h>

@interface TwitterViewController : UITableViewController  <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *tweets;
}

@property (nonatomic, strong) TWTweetComposeViewController *twitter;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (void)composeTweet:(id)sender;
- (IBAction)refresh:(id)sender;
- (void)getTweets;

@end
