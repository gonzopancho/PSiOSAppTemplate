//
//  PSAppTemplateAppDelegate.m
//  PSAppTemplate
//
//  Created by Peter Steinberger on 12.12.10.
//  Template by Peter Steinberger
//

#import "AppDelegate.h"
#import "RootViewController.h"

#if !defined (APPSTORE)
#import "BWHockeyController.h"
#endif

#ifdef kUseFlurryStatistics
#import "FlurryAPI.h"
#endif

@implementation AppDelegate

@synthesize window = window_;
@synthesize navigationController = navigationController_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

- (void)configureLogger {
  PSDDFormatter *psLogger = [[[PSDDFormatter alloc] init] autorelease];
  [[DDTTYLogger sharedInstance] setLogFormatter:psLogger];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
#ifndef APPSTORE
  // log to file
  DDFileLogger *fileLogger = [[[DDFileLogger alloc] init] autorelease];
  fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
  fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
  [DDLog addLogger:fileLogger];
  
#ifndef DISTRIBUTION
  // log to network (disabled for now, as it breaks clang 1.7)
  // [DDLog addLogger:[DDNSLoggerLogger sharedInstance]];
#endif
  
#endif
}

- (void)appplicationWillSuspend:(UIApplication *)application {
  DDLogInfo(@"detected application termination.");
  
  // post notification to all listeners
  [[NSNotificationCenter defaultCenter] postNotificationName:kAppplicationWillSuspend object:application];
}

// launched via post selector to speed up launch time
- (void)postFinishLaunch {
#ifdef kUseFlurryStatistics
  [FlurryAPI startSession:kFlurryStatisticsKey];
#endif
}

- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  [splashView_ removeFromSuperview];
  MCReleaseNil(splashView_);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (void)dealloc {
  MCRelease(splashView_);
  MCRelease(window_);
  MCRelease(navigationController_);
  
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [self configureLogger];
  DDLogInfo(LocalizedString(@"PSTemplateWelcomeMessage"));
  
#ifdef kUseCrashReporter
  [[CrashReportSender sharedCrashReportSender] sendCrashReportToURL:[NSURL URLWithString:kCrashReporterUrl] delegate:self activateFeedback:kCrashReporterFeedbackEnabled];
#endif
  
  // check for NSZombie (memory leak if enabled, but very useful!)
  if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
    DDLogWarn(@"NSZombieEnabled / NSAutoreleaseFreedObjectCheckEnabled enabled! Disable for release.");
  }
  
  // Add the navigation controller's view to the window and display.
  RootViewController *rootController = [[[RootViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
  navigationController_ = [[UINavigationController alloc] initWithRootViewController:rootController];
  window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [window_ addSubview:self.navigationController.view];
  [window_ makeKeyAndVisible];
  
  // fade animation!
#ifdef kIntroFadeAnimation
  splashView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, 320, 480)];
  splashView_.image = [UIImage imageNamed:@"Default"];
  splashView_.frame = CGRectMake(0, -45, 320, 480);
  [rootController.view addSubview:splashView_];
  [rootController.view bringSubviewToFront:splashView_];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.3];
  [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:rootController.view cache:YES];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(startupAnimationDone:finished:context:)];
  splashView_.alpha = 0.0;
  [UIView commitAnimations];
#endif
  
#if !defined (APPSTORE)
  DDLogInfo(@"Autoupdate is enabled.");
  [[BWHockeyController sharedHockeyController] setBetaURL:kBetaDistributionUrl];
#endif
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
  [self appplicationWillSuspend:application];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
}


- (void)applicationWillTerminate:(UIApplication *)application {
  [self appplicationWillSuspend:application];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark CrashReportSenderDelegate

#ifdef kUseCrashReporter
- (void)connectionOpened {
  [[IKNetworkActivityManager sharedInstance] addNetworkUser:self];
}

- (void)connectionClosed {
  [[IKNetworkActivityManager sharedInstance] removeNetworkUser:self];
}

- (NSString *)crashReportDescription {
  NSString *deviceInfo = [UIDevice debugInfo];
  DDLogInfo(deviceInfo);
  return deviceInfo;
}
#endif

@end

