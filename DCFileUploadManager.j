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
    CPString authorizationHeader @accessors;

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
    concurrent = NO;
    fileUploads = [[CPArray alloc] init];
    return self;
}

- (void)fileUploadIsReady:(id)theFileUpload
{
    [delegate fileUploadManagerDidAddUpload:theFileUpload];
    if (concurrent || ![self isUploading])
         [theFileUpload begin];
}

- (DCFileUpload)fileUploadWithFile:(id)theFile uploadURL:(CPURL)theURL andObjectClass:(class)aObjectClass
{
    var fileUpload = [[DCFileUpload alloc] initWithFile:theFile];
    [fileUpload setAuthorizationHeader:authorizationHeader];
    [fileUpload setUploadManager:self];
    [fileUpload setUploadObjectClass:aObjectClass]
    if (theFile.fileName)
        [fileUpload setName:theFile.fileName];
    else
        [fileUpload setName:theFile.name];
    [fileUpload setUploadURL:theURL];
    [fileUploads addObject:fileUpload];
    [self didChange];
    // if (concurrent || ![self isUploading])
    //     [fileUpload begin];

    return fileUpload;

}

- (DCFileUpload)fileUploadWithFile:(id)theFile uploadURL:(CPURL)theURL
{
    var fileUpload = [[DCFileUpload alloc] initWithFile:theFile];
    [fileUpload setAuthorizationHeader:authorizationHeader];
    [fileUpload setUploadManager:self];
    if (theFile.fileName)
        [fileUpload setName:theFile.fileName];
    else
        [fileUpload setName:theFile.name];
    [fileUpload setUploadURL:theURL];
    [fileUploads addObject:fileUpload];
    [self didChange];
    // if (concurrent || ![self isUploading])
    //     [fileUpload begin];

    return fileUpload;
}

- (DCFileUpload)fileUploadWithBlob:(id)theBlob name:(CPString)aName uploadURL:(CPURL)theURL
{
    var fileUpload = [[DCFileUpload alloc] initWithBlob:theBlob andName:aName];
    [fileUpload setAuthorizationHeader:authorizationHeader];
    [fileUpload setUploadManager:self];

    [fileUpload setName:aName];
    [fileUpload setUploadURL:theURL];
    [fileUploads addObject:fileUpload];
    [self didChange];

    if (concurrent || ![self isUploading])
        [fileUpload begin];

    return fileUpload;
}

- (DCFileUpload)fileUploadWithForm:(id)theForm fileElement:(id)theFileElement uploadURL:(CPURL)theURL delegate:(id)aDelegate
{
    var fileUpload = [[DCFileUpload alloc] initWithForm:theForm fileElement:theFileElement];
    [fileUpload setDelegate:aDelegate];
    [fileUpload setUploadManager:self];
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
    [fileUploads removeObject:anUpload];
    if ([delegate respondsToSelector:@selector(fileUpload:didReceiveResponse:)])
        [delegate fileUpload:anUpload didReceiveResponse:aString];
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
    else return aFile;
}

- (void)fileUploadWillBegin:(DCFileUploadDelegates)theFileUpload
{
    if ([delegate respondsToSelector:@selector(fileUploadWillBegin:)])
        [delegate fileUploadWillBegin:theFileUpload];
}

@end
