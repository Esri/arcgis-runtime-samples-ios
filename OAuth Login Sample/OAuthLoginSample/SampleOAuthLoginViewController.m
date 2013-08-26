/*
 COPYRIGHT 2013 ESRI
 
 TRADE SECRETS: ESRI PROPRIETARY AND CONFIDENTIAL
 Unpublished material - all rights reserved under the
 Copyright Laws of the United States and applicable international
 laws, treaties, and conventions.
 
 For additional information, contact:
 Environmental Systems Research Institute, Inc.
 Attn: Contracts and Legal Services Department
 380 New York Street
 Redlands, California, 92373
 USA
 
 email: contracts@esri.com
 */

#import "SampleOAuthLoginViewController.h"
#import <ArcGIS/ArcGIS.h>

@interface SampleOAuthLoginViewController ()<UIWebViewDelegate> {
    int _hits;
}
@property (nonatomic, strong) UIViewController *contentVC;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, assign, readwrite) NSString* refreshToken;
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, assign) NSString* appID ;
@property (nonatomic, strong) AGSCredential *credential;




@end

@implementation SampleOAuthLoginViewController

- (void)dealloc {
    NSOperationQueue* queue = [AGSRequestOperation sharedOperationQueue];
    for (NSOperation *nsOp in [queue operations]){
		if (![nsOp isKindOfClass:[AGSRequestOperation class]]){
			continue;
		}
		AGSRequestOperation *op = (AGSRequestOperation*)nsOp;
		if (op.target == self){
            op.target = nil;
            [op cancel];
		}
	}
}

- (id)initWithURL:(NSURL*)url appID:(NSString*)appID; {
    if (self = [super init]) {
        self.url = url;
        self.appID = appID;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.contentVC = [[UIViewController alloc] init];
    self.contentVC.title = @"Login";
    self.navigationBar.tintColor = [UIColor blackColor];
    
    self.backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(loginCancelled)];
    self.contentVC.navigationItem.leftBarButtonItem = self.backButton;

    [self pushViewController:self.contentVC animated:NO];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.contentVC.view.bounds];
    self.webView.delegate = self;
    [self.contentVC.view addSubview:self.webView];

}
- (void) viewWillAppear:(BOOL)animated {
    
    self.webView.hidden = NO;
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    [queryParams setValue:self.appID forKey:@"client_id"];
    [queryParams setValue:@"code" forKey:@"response_type"];
    [queryParams setValue:@"urn:ietf:wg:oauth:2.0:oob" forKey:@"redirect_uri"];
    
    NSMutableString* urlPrefix = [[self.url absoluteString] mutableCopy];
    [urlPrefix appendString:@"/sharing/rest/oauth2/authorize" ];
    NSURLRequest *request = [AGSRequest requestForURL:[NSURL URLWithString: urlPrefix]
                                           credential:nil
                                             resource:nil
                                      queryParameters:queryParams
                                               doPOST:YES];
    
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if ([title rangeOfString:@"SUCCESS code="].length) {
        NSString *code = [title stringByReplacingOccurrencesOfString:@"SUCCESS code=" withString:@""];

        NSMutableString* urlPrefix = [[self.url absoluteString] mutableCopy];
        [urlPrefix appendString:@"/sharing/rest/oauth2/token" ];
        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
        [queryParams setValue:@"json" forKey:@"f"];
        [queryParams setValue:self.appID forKey:@"client_id"];
        [queryParams setValue:@"urn:ietf:wg:oauth:2.0:oob" forKey:@"redirect_uri"];
        [queryParams setValue:@"authorization_code" forKey:@"grant_type"];
        [queryParams setValue:code forKey:@"code"];
        
        __weak SampleOAuthLoginViewController *weakSelf = self;
        
        AGSJSONRequestOperation *jrop = [[AGSJSONRequestOperation alloc] initWithURL:[NSURL URLWithString:urlPrefix]
                                                                            resource:nil
                                                                     queryParameters:queryParams
                                                                              doPOST:YES];

        // set target so it gets cancelled if this login view controller gets dealloced
        jrop.target = self;
         
        jrop.completionHandler = ^(id obj) {
            self.webView.hidden = YES;
            NSDictionary *json = (NSDictionary*)obj;
            self.refreshToken = [json ags_safeValueForKey:@"refresh_token"];
            
            if(!weakSelf.credential){
                self.credential = [[AGSCredential alloc] init];
                self.credential.authType = AGSAuthenticationTypeToken;
                self.credential.username = [json ags_safeValueForKey:@"username"];
            }
            weakSelf.credential.token = [json ags_safeValueForKey:@"access_token"];
            NSLog(@"Access token: %@", weakSelf.credential.token);
            // this comes back in seconds till expiration not seconds since epoch
            if ([weakSelf.loginDelegate respondsToSelector:@selector(loginViewController:didLoginWithCredential:)]) {
                [weakSelf.loginDelegate loginViewController:weakSelf didLoginWithCredential:weakSelf.credential ];
            }
        };
        jrop.errorHandler = ^(NSError *error) {
            self.webView.hidden = YES;
            if ([weakSelf.loginDelegate respondsToSelector:@selector(loginViewController:didFailToLoginWithCredential:)]) {
                [weakSelf.loginDelegate loginViewController:weakSelf didFailToLoginWithCredential:weakSelf.credential];
            }
        };
        [[AGSRequestOperation sharedOperationQueue] addOperation:jrop];
    }
    else if ([title rangeOfString:@"Denied"].length) { //user hit cancel button
        self.webView.hidden = YES;
        [self loginCancelled];
    }
}



- (void)loginCancelled {
    if ([self.loginDelegate respondsToSelector:@selector(loginViewControllerWasCancelled:)]) {
        [self.loginDelegate loginViewControllerWasCancelled:self];
    }
}

- (void)renewCredential {
    
    __weak SampleOAuthLoginViewController *weakSelf = self;
    
    
    if(!self.credential || !self.refreshToken){
        if ([self.loginDelegate respondsToSelector:@selector(loginViewController:didFailToRenewCredentialWithError:)]) {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Must have a credential before it can be renewed" forKey:NSLocalizedDescriptionKey];
            NSError* error = [[NSError alloc] initWithDomain:@"" code:0 userInfo:details];
            [self.loginDelegate loginViewController:weakSelf didFailToRenewCredentialWithError:error];
        }
    }
        
    NSMutableString* urlPrefix = [[self.url absoluteString] mutableCopy];
    [urlPrefix appendString:@"/sharing/rest/oauth2/token" ];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    [queryParams setValue:@"json" forKey:@"f"];
    [queryParams setValue:@"iUfH0WCrRAzF0zGg" forKey:@"client_id"];
    [queryParams setValue:@"refresh_token" forKey:@"grant_type"];
    [queryParams setValue:self.refreshToken forKey:@"refresh_token"];
    
    
    AGSJSONRequestOperation *jrop = [[AGSJSONRequestOperation alloc] initWithURL:[NSURL URLWithString:urlPrefix]
                                                                        resource:nil
                                                                 queryParameters:queryParams
                                                                          doPOST:YES];
    
    jrop.target = self;
    
   
    jrop.completionHandler = ^(id obj) {
        NSDictionary *json = (NSDictionary*)obj;
        self.refreshToken = [json ags_safeValueForKey:@"refresh_token"];
        weakSelf.credential.token = [json ags_safeValueForKey:@"access_token"];
        NSLog(@"Access token: %@", weakSelf.credential.token);
        // this comes back in seconds till expiration not seconds since epoch
        if ([weakSelf.loginDelegate respondsToSelector:@selector(loginViewController:didRenewCredential:)]) {
            [weakSelf.loginDelegate loginViewController:weakSelf didRenewCredential:weakSelf.credential ];
        }
    };
    jrop.errorHandler = ^(NSError *error) {
        NSLog(@"Error: %@", error);
        if ([weakSelf.loginDelegate respondsToSelector:@selector(loginViewController:didFailToRenewCredentialWithError:)]) {
            [weakSelf.loginDelegate loginViewController:weakSelf didFailToRenewCredentialWithError:error];
        }
    };
    [[AGSRequestOperation sharedOperationQueue] addOperation:jrop];
}

@end

