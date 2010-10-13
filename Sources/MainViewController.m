/*
 * Copyright 2010, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MainViewController.h"
#import "InfoViewController.h"
#import "HTTPServer.h"
#import "PacFileResponse.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SocksProxyServer.h"
#import "HTTPProxyServer.h"

@interface MainViewController ()
- (void) ping;
@end

@implementation MainViewController

@synthesize httpSwitch;
@synthesize httpAddressLabel;
@synthesize httpPacLabel;
@synthesize socksSwitch;
@synthesize socksAddressLabel;
@synthesize socksPacLabel;
@synthesize connectView;
@synthesize runningView;
@synthesize proxyHttpRunning;
@synthesize proxySocksRunning;
@synthesize httpRunning;
@synthesize ip;

- (void) viewDidLoad
{
    // connectView.layer.cornerRadius = 15;
    // runningView.layer.cornerRadius = 15;

    proxyHttpRunning = NO;
    proxySocksRunning = NO;

    httpSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey: KEY_HTTP_ON];
    socksSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey: KEY_SOCKS_ON];

    connectView.backgroundColor = [UIColor clearColor];
    runningView.backgroundColor = [UIColor clearColor];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:
        (id)[RGB(241,231,165) CGColor],
        (id)[RGB(208,180,35) CGColor],
        nil];
    [self.view.layer insertSublayer:gradient atIndex:0];

    [NSTimer scheduledTimerWithTimeInterval:1
        target:self
        selector:@selector(ping)
        userInfo:nil 
        repeats:YES];
    [self ping];
}

- (void) ping
{
	self.ip = [[NSProcessInfo processInfo] hostName];
    if (self.ip != nil) {
        
        httpAddressLabel.text = [NSString stringWithFormat:@"%@:%d", self.ip, HTTP_PROXY_PORT];
        httpPacLabel.text = [NSString stringWithFormat:@"http://%@:%d/http.pac", self.ip, [HTTPServer sharedHTTPServer].servicePort];

        socksAddressLabel.text = [NSString stringWithFormat:@"%@:%d", self.ip, SOCKS_PROXY_PORT];
        socksPacLabel.text = [NSString stringWithFormat:@"http://%@:%d/socks.pac", self.ip, [HTTPServer sharedHTTPServer].servicePort];

        if (httpSwitch.on) {
            [[HTTPProxyServer sharedHTTPProxyServer] start];

            httpAddressLabel.alpha = 1.0;
            httpPacLabel.alpha = 1.0;
            httpPacButton.enabled = YES;

        } else {
            [[HTTPProxyServer sharedHTTPProxyServer] stop];

            httpAddressLabel.alpha = 0.1;
            httpPacLabel.alpha = 0.1;
            httpPacButton.enabled = NO;
        }

        if (socksSwitch.on) {
            [[SocksProxyServer sharedSocksProxyServer] start];

            socksAddressLabel.alpha = 1.0;
            socksPacLabel.alpha = 1.0;
            socksPacButton.enabled = YES;

        } else {
            [[SocksProxyServer sharedSocksProxyServer] stop];

            socksAddressLabel.alpha = 0.1;
            socksPacLabel.alpha = 0.1;
            socksPacButton.enabled = NO;
        }
        
        if (httpSwitch.on || socksSwitch.on) {
            [[HTTPServer sharedHTTPServer] start];
        } else {
            [[HTTPServer sharedHTTPServer] stop];
        }

        [self.view addTaggedSubview:runningView];

    } else {

        [[HTTPServer sharedHTTPServer] stop];
        [[HTTPProxyServer sharedHTTPProxyServer] stop];
        [[SocksProxyServer sharedSocksProxyServer] stop];
        
        [self.view addTaggedSubview:connectView];

    }
}

- (IBAction) switchedHttp:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool: httpSwitch.on forKey: KEY_HTTP_ON];
}

- (IBAction) switchedSocks:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool: socksSwitch.on forKey: KEY_SOCKS_ON];
}

- (IBAction) showInfo
{
    InfoViewController *viewController = [[InfoViewController alloc] init];
    UINavigationController *navigationConroller = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentModalViewController:navigationConroller animated:YES];
    [navigationConroller release];
    [viewController release];
}

#pragma mark socks proxy

- (void) httpURLAction:(id)sender
{
    UIActionSheet *test;
    
    test = [[UIActionSheet alloc] initWithTitle:@"HTTP Pac URL Action" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send by Email", @"Copy URL", nil];
	[emailBody release];
	emailBody = [[NSString alloc] initWithFormat:@"http pac URL : %@\n", httpPacLabel.text];
	[emailURL release];
	emailURL = [httpPacLabel.text retain];
    [test showInView:self.view];
    [test release];
}

- (void) socksURLAction:(id)sender
{
    UIActionSheet *test;
    
    test = [[UIActionSheet alloc] initWithTitle:@"SOCKS Pac URL Action" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send by Email", @"Copy URL", nil];
	[emailBody release];
	emailBody = [[NSString alloc] initWithFormat:@"socks pac URL : %@\n", socksPacLabel.text];
	[emailURL release];
	emailURL = [socksPacLabel.text retain];
    [test showInView:self.view];
    [test release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
        case 0:
        	{
                MFMailComposeViewController*	messageController = [[MFMailComposeViewController alloc] init];
                
                if ([messageController respondsToSelector:@selector(setModalPresentationStyle:)])	// XXX not available in 3.1.3
                    messageController.modalPresentationStyle = UIModalPresentationFormSheet;
                    
                messageController.mailComposeDelegate = self;
                [messageController setMessageBody:emailBody isHTML:NO];
                [self presentModalViewController:messageController animated:YES];
                [messageController release];
            }
            break;
        case 1:
        	{
				NSDictionary *items;
                
				items = [NSDictionary dictionaryWithObjectsAndKeys:emailURL, kUTTypePlainText, emailURL, kUTTypeText, emailURL, kUTTypeUTF8PlainText, [NSURL URLWithString:emailURL], kUTTypeURL, nil];
                [UIPasteboard generalPasteboard].items = [NSArray arrayWithObjects:items, nil];
            }
        	break;
        default:
            break;
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
