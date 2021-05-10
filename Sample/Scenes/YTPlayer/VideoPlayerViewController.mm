//
//  VideoPlayerViewController.m
//  LiveEvents
//

#import "VideoPlayerViewController.h"

@implementation VideoPlayerViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self configureView];
    [self playVdeo];
}

- (void) configureView {
    self.playerView.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(receivedPlaybackStartedNotification:)
                                                 name: @"Playback started"
                                               object: nil];
}

- (void) playVdeo {
    // For a full list of player parameters, see the documentation for the HTML5 player
    // at: https://developers.google.com/youtube/player_parameters?playerVersion=HTML5
    NSDictionary *playerVars = @{
        @"controls": @0,
        @"playsinline": @1,
        @"autohide": @1,
        @"showinfo": @0,
        @"modestbranding": @1
    };
    [self.playerView loadWithVideoId: self.videoId
                          playerVars: playerVars];
}

// MARK: - YTPlayerViewDelegate protocol implementation

- (void) playerView: (YTPlayerView *) ytPlayerView
   didChangeToState: (YTPlayerState) state {
    NSString *message = [NSString stringWithFormat: @"Player state changed: %ld\n", (long) state];
    [self appendStatusText: message];
}

- (void) playerView: (YTPlayerView *) playerView
        didPlayTime: (float)playTime {
    [self.playerView duration: ^(double result, NSError * _Nullable error) {
        float progress = playTime/result;
        [self.slider setValue: progress];
    }];
}

// MARK: - User actions handlers

- (IBAction) onSliderChange: (id) sender {
    [self.playerView duration: ^(double result, NSError * _Nullable error) {
        float seekToTime = result * self.slider.value;
        [self.playerView seekToSeconds: seekToTime
                        allowSeekAhead: YES];
        [self appendStatusText: [NSString stringWithFormat: @"Seeking to time: %.0f seconds\n", seekToTime]];
    }];
}

- (IBAction) buttonPressed: (id) sender {
    if (sender == self.playButton) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"Playback started"
                                                            object: self];
        [self.playerView playVideo];
    } else if (sender == self.stopButton) {
        [self.playerView stopVideo];
    } else if (sender == self.pauseButton) {
        [self.playerView pauseVideo];
    } else if (sender == self.reverseButton) {
        [self.playerView currentTime: ^(float result, NSError * _Nullable error) {
            float seekToTime = result - 30.0;
            [self.playerView seekToSeconds: seekToTime
                            allowSeekAhead: YES];
            [self appendStatusText: [NSString stringWithFormat: @"Seeking to time: %.0f seconds\n", seekToTime]];
        }];
    } else if (sender == self.forwardButton) {
        [self.playerView currentTime: ^(float result, NSError * _Nullable error) {
            float seekToTime = result + 30.0;
            [self.playerView seekToSeconds: seekToTime
                            allowSeekAhead: YES];
            [self appendStatusText: [NSString stringWithFormat: @"Seeking to time: %.0f seconds\n", seekToTime]];
        }];
    } else if (sender == self.startButton) {
        [self.playerView seekToSeconds: 0
                        allowSeekAhead: YES];
        [self appendStatusText: @"Seeking to beginning\n"];
    }
}

- (IBAction) closePressed: (id) sender {
    [self dismissViewControllerAnimated: true completion: nil];
}

// MARK: - Private methods

- (void) receivedPlaybackStartedNotification: (NSNotification *) notification {
    if ([notification.name isEqual: @"Playback started"] && notification.object != self) {
        [self.playerView pauseVideo];
    }
}

/**
 * Private helper method to add player status in statusTextView and scroll view automatically.
 *
 * @param status a string describing current player state
 */
- (void) appendStatusText: (NSString *) status {
    [self.statusTextView setText: [self.statusTextView.text stringByAppendingString: status]];
    NSRange range = NSMakeRange(self.statusTextView.text.length - 1, 1);
    
    // To avoid dizzying scrolling on appending latest status.
    self.statusTextView.scrollEnabled = NO;
    [self.statusTextView scrollRangeToVisible: range];
    self.statusTextView.scrollEnabled = YES;
}

@end