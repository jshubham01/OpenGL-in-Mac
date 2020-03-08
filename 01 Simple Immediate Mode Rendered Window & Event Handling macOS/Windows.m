/*
Module Name:
    Window.cpp demostrates the use of Objective C for Windowing in macOS

Abstract:
    This Module creates empty window with events

Revision History:
    Date:	Nov 24, 2019.
    Desc:	Started

    Date:	Nov 24, 2019.
    Desc:	Done
*/

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

/////////////////////////////////////////////////////
// Global Variables declarations and initializations
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////
//	I N T E R F A C E  D E C L A R A T I O N S
/////////////////////////////////////////////////////////////////////

// interface declarations
@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@end

@interface MyView : NSView
@end

// Entry-Point Function
int
main(int argc , const char *argv[])
{
    // Code
    NSAutoreleasePool *pPool = [[NSAutoreleasePool alloc]init];
    NSApp = [NSApplication sharedApplication];
    [NSApp setDelegate:[[AppDelegate alloc]init]];
    [NSApp run];
    [pPool release];
    return (0);
}

int main(int argc, char * argv[]) {
    int ret;
	
	NSString * appDelegateClassName;
	
    NSAutoreleasePool *pPool = [[NSAutoreleasePool alloc]init];
	
	appDelegateClassName = NSStringFromClass([AppDelegate class]);
	ret = UIApplicationMain(argc, argv, nil, appDelegateClassName);
	
	[pPool release];
	return ret;
    
    //NSApp = [UIApplication sharedApplication];
    
    [NSApp setDelegate:[[AppDelegate alloc]init]];
    
    //[pPool release];
    
    
    //@autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
      //}    
}

// interface implementations
@implementation AppDelegate
{
@private
    NSWindow *window;
    MyView *view;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // code
    // window
    NSRect win_rect;
    win_rect = NSMakeRect(0.0, 0.0, 800.0, 600.0);

    // create simple window
    window = [[NSWindow alloc] initWithContentRect:win_rect
                        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                        backing:NSBackingStoreBuffered
                        defer:NO];

    [window setTitle:@"macOS Window"];
    [window center];

    view=[[MyView alloc]initWithFrame:win_rect];
    [window setContentView:view];
    [window setDelegate:self];
    [window makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate: (NSNotification *)Notification
{
    // code
}

- (void)windowWillClose:(NSNotification *)notification;
{
    // code
    [NSApp terminate:self];
}

- (void)dealloc
{
    // code
    [view release];

    [window release];

    [super dealloc];
}
@end

@implementation MyView
{
    NSString *centralText;
}

-(id)initWithFrame:(NSRect)frame;
{
    // code
    self = [super initWithFrame:frame];
    if(self)
    {
        [[self window]setContentView:self];

        centralText=@"Hello World !!!";
    }

    return(self);
}

- (void)drawRect:(NSRect)dirtyRect
{
    // code
    // black background
    NSColor *fillColor = [NSColor blackColor];
    [fillColor set];
    NSRectFill(dirtyRect);

    // dictionary with kvc
    NSDictionary *dictionaryForTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSFont fontWithName:@"Helvetica" size:32],
                                                    NSFontAttributeName, [NSColor greenColor],
                                                    NSForegroundColorAttributeName,
                                                nil];

    NSSize textSize=[centralText sizeWithAttributes:dictionaryForTextAttributes];

    NSPoint point;
    point.x = (dirtyRect.size.width/2) - (textSize.width/2);
    point.y = (dirtyRect.size.height/2) - (textSize.height/2) + 12;

    [centralText drawAtPoint:point withAttributes:dictionaryForTextAttributes];
}

- (BOOL)acceptsFirstResponder
{
    // code
    [[self window]makeFirstResponder:self];
    return(YES);
}

-(void)keyDown: (NSEvent *)theEvent
{
    // code
    int key = (int)[[theEvent characters]charactersAtIndex:0];
    switch(key)
    {
        case 27: // Esc Key
            [self release];
            [NSApp terminate:self];
            break;

        case 'F':
        case 'f':
            centralText = @"'F' or 'f' Key Is Pressed";
            [[self window]toggleFullScreen:self]; // repainting occurs
            break;

        default:
            break;
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    // code
    centralText = @"Left Mouse Button Is Clicked";
    [self setNeedsDisplay:YES];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    // code
}

-(void)rightMouseDown:(NSEvent *)theEvent
{
    // code
    centralText = @"Right Button Key Is pressed";
    [self setNeedsDisplay:YES]; // repainting
}

-(void) dealloc
{
    // code
    [super dealloc];
}

@end
