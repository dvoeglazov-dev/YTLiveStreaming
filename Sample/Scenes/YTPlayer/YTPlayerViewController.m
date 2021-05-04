//
//  YTPlayerViewController.m
//  LiveEvents
//
//  Created by Сергей Кротких on 04.05.2021.
//  Copyright © 2021 Sergey Krotkih. All rights reserved.
//

#import "YTPlayerViewController.h"

@interface YTPlayerViewController ()
    @property(nonatomic, strong) NSString *videoId;
@end

@implementation YTPlayerViewController

- (id) initWithYouTubeId: (NSString*) videoId
{
    if (self = [super init])
    {
        self.videoId = videoId;
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // For a full list of player parameters, see the documentation for the HTML5 player
    // at: https://developers.google.com/youtube/player_parameters?playerVersion=HTML5
    NSDictionary *playerVars = @{
        @"controls": @0,
        @"playsinline": @1,
        @"autohide": @1,
        @"showinfo": @0,
        @"modestbranding": @1
    };
    self.playerView.delegate = self;
    [self.playerView loadWithVideoId: self.videoId
                          playerVars: playerVars];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(receivedPlaybackStartedNotification:)
                                                 name: @"Playback started"
                                               object: nil];
}

- (void)playerView: (YTPlayerView *) ytPlayerView
  didChangeToState: (YTPlayerState) state {
    NSString *message = [NSString stringWithFormat: @"Player state changed: %ld\n", (long) state];
    [self appendStatusText:message];
}

- (void)playerView: (YTPlayerView *) playerView
       didPlayTime: (float)playTime {
    [self.playerView duration: ^(double result, NSError * _Nullable error) {
        float progress = playTime/result;
        [self.slider setValue: progress];
    }];
}

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
    [self.statusTextView setText:[self.statusTextView.text stringByAppendingString:status]];
    NSRange range = NSMakeRange(self.statusTextView.text.length - 1, 1);
    
    // To avoid dizzying scrolling on appending latest status.
    self.statusTextView.scrollEnabled = NO;
    [self.statusTextView scrollRangeToVisible: range];
    self.statusTextView.scrollEnabled = YES;
}

@end