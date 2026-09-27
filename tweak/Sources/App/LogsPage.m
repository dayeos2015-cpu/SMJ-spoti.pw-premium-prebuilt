#import "Core/SGCore.h"
#import "Diagnostics/Diagnostics.h"
#import "Settings/SGPage.h"
#import "Settings/SGPageStyle.h"

@interface SGLogViewer : SGPage
@end

@implementation SGLogViewer {
    UITextView *_textView;
    NSString *_shownText;
    NSTimer *_refreshTimer;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStylePlain])) return nil;
    self.title = @"Logs";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _textView = [UITextView new];
    _textView.backgroundColor = SGPageBackground();
    _textView.textColor = UIColor.whiteColor;
    _textView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    _textView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    _textView.editable = NO;
    _textView.selectable = YES;
    self.tableView.backgroundView = _textView;

    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"]
        style:UIBarButtonItemStylePlain target:self action:@selector(shareLogs)];
    share.accessibilityLabel = @"Share logs";
    UIBarButtonItem *clear = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"]
        style:UIBarButtonItemStylePlain target:self action:@selector(confirmClear)];
    clear.accessibilityLabel = @"Clear in-app logs";
    self.navigationItem.rightBarButtonItems = @[share, clear];
    [self refreshLogs];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshLogs) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_refreshTimer invalidate];
    _refreshTimer = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    SGInsetForBars(self.tableView);
}

- (void)refreshLogs {
    NSString *text = SGLogSnapshot();
    if (!text.length) text = @"No logs yet.";
    if ([_shownText isEqualToString:text]) return;

    BOOL follow = !_shownText.length || _textView.contentOffset.y + _textView.bounds.size.height >= _textView.contentSize.height - 24;
    _shownText = text;
    _textView.text = text;
    if (follow) [_textView scrollRangeToVisible:NSMakeRange(text.length, 0)];
}

- (void)shareLogs {
    NSString *text = SGLogSnapshot();
    if (!text.length) text = @"No logs yet.";
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"spotifyglass.log"]];
    NSError *error = nil;
    if (![text writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Could not export logs"
            message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    UIActivityViewController *sheet = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetWidth(self.view.bounds) - 44, 0, 44, 44);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)confirmClear {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear in-app logs?"
        message:@"This clears the recent logs shown here. It does not erase iOS device logs." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        SGLogClear();
        self->_shownText = nil;
        [self refreshLogs];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

UIViewController *SGLogViewerPage(void) {
    return [SGLogViewer new];
}