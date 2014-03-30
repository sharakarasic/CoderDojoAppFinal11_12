//
//  TweetViewController.m
//  CoderDojo1
//
//  Created by Scott Parris on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TweetViewController.h"
#import <Accounts/Accounts.h>
#import "TweetWebViewController.h"


@implementation TweetViewController

@synthesize tweet, tweetLinks, name, address, created, tweetText, tweetImage, tweetBar, twitter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        twitter = [[TWTweetComposeViewController alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)composeTweet:(id)sender
{
    
    //  [twitter addImage:[UIImage imageNamed:@"coderdojo.png"]];
    //  [twitter addURL:[NSURL URLWithString:[NSString stringWithString:@"http://coderdojo.com/"]]];
    [twitter setInitialText:[NSString stringWithFormat:@"@%@", [tweet objectForKey:@"from_user"]]];
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





- (void)retweetMessage:(id)sender;
{
    if ([TWTweetComposeViewController canSendTweet]) 
    {
        ACAccountStore *account = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [account requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
             if (granted == YES) {
                 // Populate array with all available Twitter accounts
                 NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
                 
                 // Sanity check
                 if ([arrayOfAccounts count] > 0) {
                     
                     // Keep it simple, use the first account available
                    ACAccount *acct = [arrayOfAccounts objectAtIndex:0];
                     
                     // Build a twitter request
                    NSString *retweetString = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/retweet/%@.json", [self.tweet objectForKey:@"id"]];
                    NSURL *retweetURL = [NSURL URLWithString:retweetString];
                    TWRequest *request = [[TWRequest alloc] initWithURL:retweetURL parameters:nil requestMethod:TWRequestMethodPOST];
                     // Post the request
                     [request setAccount:acct];
                     
                     // Block handler to manage the response
                     [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) 
                      {
                          NSString *resultMessage = [[NSMutableString alloc] initWithString:@"Retweet sent."];
                          if (responseData)
                          {
                              NSError *parseError = nil;
                              id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];
                              if (!json) {
                                  resultMessage = @"Retweet faild to return a valid response.";
                                  NSLog(@"Parse Error: %@", parseError);
                              } else {
                                  NSLog(@"%@", json);
                              }
                          } else {
                              resultMessage = @"Retweet faild: %@", [error localizedDescription];        
                              NSLog(@"Request Error: %@", [error localizedDescription]);
                          }
                          NSString *title = @"Tweet Status";
                          UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:resultMessage delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                          [alertView show];        

                      }];
                 }
             }
         }];
    }        
}


-(void)linkTapped:(UIGestureRecognizer *)gestureRecognizer {
    UILabel *hitLabel = (UILabel*)gestureRecognizer.view;
    NSString *tweetAttr = [self.tweetLinks objectAtIndex:hitLabel.tag];
    NSURL *twitterURL = [[NSURL alloc] init]; 
    NSArray *punctuation = [NSArray arrayWithObjects:@".", @"!", @":", @"?", nil];
    for (int i=0; i< [punctuation count]; i++) {
        if ([tweetAttr hasSuffix:[punctuation objectAtIndex:i]]) {
            tweetAttr = [tweetAttr substringToIndex:[tweetAttr length]-1];
        }
    }

    if ([tweetAttr caseInsensitiveCompare:@"#coderdojo"] == NSOrderedSame) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSRange rangAt = [tweetAttr rangeOfString:@"@" options:NSCaseInsensitiveSearch];
        NSRange rangHash = [tweetAttr rangeOfString:@"#" options:NSCaseInsensitiveSearch];
        NSRange ranglink = [tweetAttr rangeOfString:@"http" options:NSCaseInsensitiveSearch];    

        if (rangAt.location != NSNotFound) {
            twitterURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/%@", [tweetAttr stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
        } else if (rangHash.location != NSNotFound) {
            twitterURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/search?q=%@&src=hash", [tweetAttr stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
        } else if (ranglink.location != NSNotFound) {
            twitterURL = [NSURL URLWithString:tweetAttr];   
        }

        TweetWebViewController *webView = [[TweetWebViewController alloc]  initWithURL:twitterURL];
        [(UIActivityIndicatorView *)[self navigationItem].rightBarButtonItem.customView startAnimating];
        [self.navigationController pushViewController:webView animated:YES];
    }
}



#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)viewDidLoad
{
    self.tweetLinks =[[NSMutableArray alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect imageFrame = CGRectMake(10.0, 10.0, 90.0, 90.0);
    self.tweetImage = [[UIImageView alloc] initWithFrame:imageFrame];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[self.tweet objectForKey:@"profile_image_url"]]];
    self.tweetImage.image = [UIImage imageWithData:imageData];
    
    CGRect nameFrame = CGRectMake(110.0, 5.0, 195.0, 20.0);
    self.name = [[UILabel alloc] initWithFrame:nameFrame];
    self.name.textColor = [UIColor blackColor];
    self.name.text = [tweet objectForKey:@"from_user_name"];
    self.name.font = [UIFont systemFontOfSize:14];
    
    CGRect addressFrame = CGRectMake(110.0, 30.0, 195.0, 15.0);
    self.address = [[UILabel alloc] initWithFrame:addressFrame];
    self.address.textColor = [UIColor blueColor];
    self.address.text = [NSString stringWithFormat:@"@%@", [tweet objectForKey:@"from_user"]];
    self.address.font = [UIFont systemFontOfSize:14];
    self.address.tag = 0;
    self.address.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkTapped:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.address addGestureRecognizer:tapGestureRecognizer];
    [self.tweetLinks addObject:self.address.text]; 
    
    CGRect createdFrame = CGRectMake(110.0, 45.0, 195.0, 15.0);
    self.created = [[UILabel alloc] initWithFrame:createdFrame];
    self.created.textColor = [UIColor blackColor];
    self.created.text = [tweet objectForKey:@"created_at"];
    self.created.font = [UIFont systemFontOfSize:12];
    
    NSArray *array = [[tweet objectForKey:@"text"] componentsSeparatedByString:@" "];
    int tag = 1;
    CGFloat rMargin = 5.0;
    CGFloat xx = rMargin;  
    CGFloat yy = 110.0;
    CGFloat lineHeight = 18.0;
    CGFloat lineWidth = 305.0;
    CGFloat fontSize = 14.0;
    
    NSString *currentLabel = @"";
    NSString *currentLine = @"";
    for(int i=0; i<[array count]; i++) {
        NSString *word = [NSString stringWithFormat:@"%@", [array objectAtIndex:i]]; 
        currentLine = [currentLine stringByAppendingFormat:@"%@ ", word];
        CGSize lineSize = [currentLine sizeWithFont:[UIFont systemFontOfSize:fontSize]];
        CGSize wordSize = [word sizeWithFont:[UIFont systemFontOfSize:fontSize]];
        CGSize currentSize = [currentLabel sizeWithFont:[UIFont systemFontOfSize:fontSize]];

        NSRange rangAt = [word rangeOfString:@"@" options:NSCaseInsensitiveSearch];
        NSRange rangHash = [word rangeOfString:@"#" options:NSCaseInsensitiveSearch];
        NSRange ranglink = [word rangeOfString:@"http" options:NSCaseInsensitiveSearch];
        
     //  NSLog(@"word %@ , width: %f", word, wordSize.width);
     //  NSLog(@"currentLabel: %@ , width: %f", currentLabel, currentSize.width);        
     //  NSLog(@"currentLine: %@ , width: %f", currentLine, lineSize.width);
        
        if (rangAt.location != NSNotFound || rangHash.location != NSNotFound || ranglink.location != NSNotFound) {
            if (currentSize.width > 0) {
                xx += 5.0;
                CGRect textFrame = CGRectMake(xx, yy, currentSize.width, lineHeight);
                UILabel *textLabel = [[UILabel alloc] initWithFrame:textFrame];
                textLabel.textColor = [UIColor blackColor];
                textLabel.font = [UIFont systemFontOfSize:fontSize];  
                textLabel.text = currentLabel;
                [self.view addSubview:textLabel];
                currentLabel = @"";
                xx = lineSize.width - wordSize.width + 5; 
            }
            if ((lineSize.width) > lineWidth) {
                currentLine = [NSString stringWithFormat:@"%@ ", word];
                yy = yy + lineHeight;
                xx = rMargin;
            } 
            xx += 5.0;
            CGRect frame = CGRectMake(xx, yy, wordSize.width, lineHeight);
            UILabel *label = [[UILabel alloc] initWithFrame:frame];
            label.text = word;
            label.textColor = [UIColor blueColor];
            label.font = [UIFont systemFontOfSize:fontSize];
            label.tag = tag;
            label.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkTapped:)];
            tapGestureRecognizer.numberOfTapsRequired = 1;
            [label addGestureRecognizer:tapGestureRecognizer];
            [self.tweetLinks addObject: word];
            [self.view addSubview:label];
            tag += 1;
            xx += wordSize.width;
        } else {    
            if (lineSize.width > lineWidth) {
                xx += 5.0;
                CGRect textFrame = CGRectMake(xx, yy, currentSize.width, lineHeight);
                UILabel *textLabel = [[UILabel alloc] initWithFrame:textFrame];
                textLabel.textColor = [UIColor blackColor];
                textLabel.font = [UIFont systemFontOfSize:fontSize];
                textLabel.text = currentLabel;
                [self.view addSubview:textLabel];
                currentLabel = @"";  
                currentLine = [NSString stringWithFormat:@"%@ ", word];
                yy = yy + lineHeight;
                xx = rMargin;
            } else if (i == ([array count] - 1)) {
                if (xx == rMargin) {
                    xx += 5;
                }
                currentLabel = [currentLabel stringByAppendingFormat:@"%@ ", word];
                currentSize = [currentLabel sizeWithFont:[UIFont systemFontOfSize:fontSize]];
                CGRect textFrame = CGRectMake(xx, yy, currentSize.width, lineHeight);
                UILabel *textLabel = [[UILabel alloc] initWithFrame:textFrame];
                textLabel.textColor = [UIColor blackColor];
                textLabel.font = [UIFont systemFontOfSize:fontSize];
                textLabel.text = currentLabel;
                [self.view addSubview:textLabel];
            }
            currentLabel = [currentLabel stringByAppendingFormat:@"%@ ", word];
        }
    }
    
    CGRect toolFrame = CGRectMake(0.0, 215.0, 320.0, 40.0);
    self.tweetBar = [[UIToolbar alloc] initWithFrame:toolFrame];
    self.tweetBar.tintColor = [UIColor lightGrayColor];
    
    UIBarButtonItem *reply = [[UIBarButtonItem  alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(composeTweet:)];
    UIBarButtonItem *retweet = [[UIBarButtonItem  alloc] initWithImage:[UIImage imageNamed:@"retweet.png"] style:UIBarButtonItemStylePlain target:self action:@selector(retweetMessage:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.tweetBar.items = [NSArray arrayWithObjects: flexibleSpace, reply, flexibleSpace, retweet, flexibleSpace, nil];

    [self.view addSubview:self.tweetImage];
    [self.view addSubview:self.name];
    [self.view addSubview:self.address];    
    [self.view addSubview:self.created];    
    [self.view addSubview:self.tweetText]; 
    [self.view addSubview:self.tweetBar]; 
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
