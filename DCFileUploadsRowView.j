@import <AppKit/CPView.j>
@import "DCProgressIndicator.j"

@implementation DCFileUploadsRowView : CPView
{
    CPTextField nameField;
    CPProgressIndicator progressIndicator;
}

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];

    nameField = [[CPTextField alloc] initWithFrame:CGRectMake(
        theFrame.origin.x + 10,
        theFrame.origin.y,
        theFrame.size.width - 40,
        20)];
    [nameField setAutoresizingMask:CPViewWidthSizable | CPViewMaxYMargin];
    [nameField setLineBreakMode:CPLineBreakByTruncatingTail];
    [nameField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [nameField setAlignment:CPLeftTextAlignment];
    [nameField setFont:[CPFont boldSystemFontOfSize:11.0]];
    [nameField setTextColor:[CPColor colorWithCalibratedWhite:1.0 alpha:0.9]];
    [nameField setTextShadowColor:[CPColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    [nameField setTextShadowOffset:CGSizeMake(0,-1)];
    [nameField setBackgroundColor:[CPColor clearColor]];
    [self addSubview:nameField];


    progressIndicator = [[DCProgressIndicator alloc] initWithFrame:CGRectMake(
        theFrame.origin.x + 10,
        theFrame.origin.y + 22,
        theFrame.size.width - 20,
        15)];
    [progressIndicator setAutoresizingMask:CPViewWidthSizable | CPViewMaxYMargin];
    [progressIndicator setControlSize:CPRegularControlSize];
    [progressIndicator setMinValue:0.0];
    [progressIndicator setMaxValue:1.0];
    [self addSubview:progressIndicator];

    return self;
}

- (void)drawRect:(CGRect)rect
{
    var topStripe = CPMakeRect(0,CGRectGetHeight([self bounds])-1,CGRectGetWidth(rect),1);
    [[CPColor colorWithCalibratedWhite:1.0 alpha:0.08] set];
    [[CPBezierPath bezierPathWithRect:topStripe] fill];

    topStripe.origin.y -= 1;

    [[CPColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
    [[CPBezierPath bezierPathWithRect:topStripe] fill];
}


- (void)setObjectValue:(Object)anObject
{
    [nameField setStringValue:[anObject name]];
    [progressIndicator setDoubleValue:[anObject progress]];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    nameField = [aCoder decodeObjectForKey:"nameField"];
    progressIndicator = [aCoder decodeObjectForKey:"progressIndicator"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:nameField forKey:"nameField"];
    [aCoder encodeObject:progressIndicator forKey:"progressIndicator"];
}

@end
