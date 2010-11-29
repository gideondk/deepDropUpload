@import <AppKit/CPPanel.j>
@import "DCFileUpload.j"

/*

DCFileUploadManagerDelegate protocol
- (void)fileUploadManagerDidChange:(DCFileUploadManager)theManager;

*/

SharedFileUploadManager = nil;

@implementation DCFileUploadManager : CPObject
{
    CPArray fileUploads @accessors;
    id      delegate @accessors;
    BOOL    concurrent @accessors; // YES to make files upload at the same time.  NO (default) to upload one at a time.
}

+ (DCFileUploadManager)sharedManager
{
    if (!SharedFileUploadManager)
        SharedFileUploadManager = [[DCFileUploadManager alloc] init];

    return SharedFileUploadManager;
}

- (id)init
{
    self = [super init];
    fileUploads = [[CPArray alloc] init];
    return self;
}

- (DCFileUpload)fileUploadWithFile:(id)theFile uploadURL:(CPURL)theURL
{
    var fileUpload = [[DCFileUpload alloc] initWithFile:theFile];
    [fileUpload setDelegate:self];
    [fileUpload setName:theFile.fileName];
    [fileUpload setUploadURL:theURL];
    [fileUploads addObject:fileUpload];
    [self didChange];

    if (concurrent || ![self isUploading])
        [fileUpload begin];

    return fileUpload;
}

- (DCFileUpload)fileUploadWithForm:(id)theForm fileElement:(id)theFileElement uploadURL:(CPURL)theURL
{
    var fileUpload = [[DCFileUpload alloc] initWithForm:theForm fileElement:theFileElement];
    [fileUpload setDelegate:self];
    [fileUpload setName:theFileElement.value];
    [fileUpload setUploadURL:theURL];
    [fileUpload fileUploadDidDrop];
    [fileUploads addObject:fileUpload];
    [self didChange];

    if (concurrent || ![self isUploading])
        [fileUpload begin];

    return fileUpload;
}

- (BOOL)isUploading
{
    for (var i = 0; i < [fileUploads count]; i++)
    {
        var fileUpload = [fileUploads objectAtIndex:i];
        if ([fileUpload isUploading])
            return YES;
    }

    return NO;
}

- (void)removeFileUpload:(DCFileUpload)theFileUpload
{
    [fileUploads removeObject:theFileUpload];
    [self didChange];
}

- (void)fileUploadDidBegin:(DCFileUpload)theFileUpload
{
    [self didChange];
}

- (void)fileUploadProgressDidChange:(DCFileUpload)theFileUpload
{
    [self didChange];
}

- (void)fileUploadDidEnd:(DCFileUpload)theFileUpload
{
    if (!concurrent)
    {
        // start the next one
        var i = [fileUploads indexOfObject:theFileUpload] + 1;
        if (i < [fileUploads count])
            [[fileUploads objectAtIndex:i] begin];
    }
    [self didChange];

    if ([delegate respondsToSelector:@selector(fileUploadDidEnd:)])
        [delegate fileUploadDidEnd:theFileUpload];
    if ([delegate respondsToSelector:@selector(fileUploadManager:uploadDidFinish:)])
        [delegate fileUploadManager:self uploadDidFinish:theFileUpload];
}

- (void)fileUpload:(DCFileUpload)anUpload didReceiveResponse:(CPString)aString
{
    if ([delegate respondsToSelector:@selector(fileUpload:didReceiveResponse:)])
        [delegate fileUpload:self didReceiveResponse:aString];
}

- (void)didChange
{
    if ([delegate respondsToSelector:@selector(fileUploadManagerDidChange:)])
        [delegate fileUploadManagerDidChange:self];
}

- (void)dataForFileUpload:(DCFileUpload)theFileUpload xhr:(id)anXhrObject file:(id)aFile
{
    if ([delegate respondsToSelector:@selector(dataForFileUpload:xhr:file:)])
        return [delegate dataForFileUpload:theFileUpload xhr:anXhrObject file:aFile];
}

- (void)fileUploadWillBegin:(DCFileUploadDelegates)theFileUpload
{
    if ([delegate respondsToSelector:@selector(fileUploadWillBegin:)])
        [delegate fileUploadWillBegin:theFileUpload];
}

@end
