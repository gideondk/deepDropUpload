@import <AppKit/CPPanel.j>

/*

DCFileUploadDelegate protocol
- (void)fileUploadDidBegin:(DCFileUpload)theController;
- (void)fileUploadProgressDidChange:(DCFileUpload)theController;
- (void)fileUploadDidEnd:(DCFileUpload)theController;

*/

@implementation DCFileUpload : CPObject
{
    CPString        name @accessors;
    CPString        remoteId @accessors;
    float           progress @accessors;
    id              delegate @accessors;
    id              uploadManager @accessors;
    CPURL           uploadURL @accessors;
    CPDictionary    userInfo @accessors;
    CPString        responseText @accessors;
    BOOL            indeterminate @accessors;
    class             uploadObjectClass @accessors;

    id              file;
    id              xhr;
    BOOL            isUploading;
    CPString        authorizationHeader @accessors;

    // legacy support
    id              legacyForm;
    id              legacyFileElement;
    DOMElement      _DOMIFrameElement;

    var             fileName @accessors;
    var             fileSize;
}

- (id)initWithFile:(id)theFile
{
    self = [super init];
    file = theFile;
    fileSize = file.fileSize;
    [self retrieveFileName];

    progress = 0.0;
    isUploading = NO;
    return self;
}

- (id)initWithBlob:(id)theBlob andName:(CPString)aName
{
    self = [super init];
    file = theBlob;
    fileSize = theBlob.size;
    fileName = aName;
    progress = 0.0;
    isUploading = NO;
    return self;
}


- (id)initWithForm:(id)theForm fileElement:(id)theFileElement
{
    self = [super init];
    legacyForm = theForm;
    legacyFileElement = theFileElement;
    progress = 0.0;
    isUploading = NO;
    return self;
}

- (void)retrieveFileName
{
    if (file.fileName)
        fileName = file.fileName;
    else
        fileName = file.name;
}

- (void)begin
{
    if ([uploadManager respondsToSelector:@selector(fileUploadWillBegin:)])
        [uploadManager fileUploadWillBegin:self];

    if (file)
    {
        // upload asynchronously with progress in newer browsers
        indeterminate = NO;
        [self processXHR];
    }
    else if (legacyForm && legacyFileElement)
    {
        // fall back to legacy iframe upload method
        indeterminate = YES;
        [self uploadInIframe];
    }
}

- (void)processXHR
{
    xhr = new XMLHttpRequest();

    var fileUpload = xhr.upload;

    fileUpload.addEventListener("progress", function(event)
    {
        if (event.lengthComputable)
        {
            [self setProgress:event.loaded / event.total];
            [self fileUploadProgressDidChange];
        }
    }, false);

    fileUpload.addEventListener("load", function(event)
    {
        if (xhr.responseText)
            [self fileUploadDidReceiveResponse:xhr.responseText];
    }, false);

    fileUpload.addEventListener("error", function(evt) {
        CPLog("error: " + evt.code);
    }, false);

    if (!uploadURL)
        return;

    if (!FormData)
    {
        CPLog("Cancelling Upload: FormData object not found.");
        return;
    }

    xhr.addEventListener("load", function(evt)
    {
        if (xhr.responseText)
            [self fileUploadDidReceiveResponse:xhr.responseText];

        [self fileUploadDidEnd];
    }, NO);

    xhr.open("POST", [uploadURL absoluteURL]);

    xhr.setRequestHeader("If-Modified-Since", "Mon, 26 Jul 1997 05:00:00 GMT");
    xhr.setRequestHeader("Cache-Control", "no-cache");
    xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");

    var postParams = {"remote_id": remoteId}
    xhr.setRequestHeader("X-Query-Params", JSON.stringify(postParams));
    xhr.setRequestHeader("X-File-Name", fileName);
    xhr.setRequestHeader("X-File-Size", fileSize);
    xhr.setRequestHeader("Content-Type", "application/octet-stream");
    xhr.setRequestHeader("Authorization", authorizationHeader);

    var data = file;
    if ([uploadManager respondsToSelector:@selector(dataForFileUpload:xhr:file:)])
    {
        // Give a delegate a chance to swap file with a FormData object with
        // additional info.
        data = [uploadManager dataForFileUpload:self xhr:xhr file:file];
    }

    xhr.send(data);

    [self fileUploadDidBegin];
};

- (void)fileUploadDidDrop
{
    if ([uploadManager respondsToSelector:@selector(fileUploadDidDrop:)])
        [uploadManager fileUploadDidDrop:self];
    if ([delegate respondsToSelector:@selector(fileUploadDidDrop:)])
        [delegate fileUploadDidDrop:self];
}

- (void)fileUploadDidBegin
{
    isUploading = YES;
    if ([uploadManager respondsToSelector:@selector(fileUploadDidBegin:)])
        [uploadManager fileUploadDidBegin:self];
    if ([delegate respondsToSelector:@selector(fileUploadDidBegin:)])
        [delegate fileUploadDidBegin:self];
}

- (void)fileUploadProgressDidChange
{
    isUploading = YES;
    if ([uploadManager respondsToSelector:@selector(fileUploadProgressDidChange:)])
        [uploadManager fileUploadProgressDidChange:self];
}

- (void)fileUploadDidEnd
{
    isUploading = NO;
    if ([uploadManager respondsToSelector:@selector(fileUploadDidEnd:)])
        [uploadManager fileUploadDidEnd:self];
    if ([delegate respondsToSelector:@selector(fileUploadDidEnd:)])
        [delegate fileUploadDidEnd:self];
}

- (void)fileUploadDidReceiveResponse:(CPString)aResponse
{
    responseText = aResponse;
    if ([uploadManager respondsToSelector:@selector(fileUpload:didReceiveResponse:)])
        [uploadManager fileUpload:self didReceiveResponse:aResponse];

    if ([delegate respondsToSelector:@selector(fileUpload:didReceiveResponse:)])
        [delegate fileUpload:self didReceiveResponse:aResponse];
}

- (BOOL)isUploading
{
    return isUploading;
}

- (void)cancel
{
    isUploading = NO;
    xhr.abort();
}


// ************************* Legacy Browser Support *************************

- (void)uploadInIframe
{
    legacyForm.target = "FRAME_"+(new Date());
    legacyForm.action = uploadURL;

    //remove existing parameters
    [self _removeUploadFormElements];

    var _parameters;
    if ([[uploadManager delegate] respondsToSelector:@selector(legacyFormParametersForFileUpload:fileElement:)])
    {
        // This is really clunky. Would be nice to unify with dataForFileUpload:xhr:file somehow.
        _parameters = [[uploadManager delegate] legacyFormParametersForFileUpload:self fileElement:legacyFileElement];
    }
    else
    {
        _parameters = [CPDictionary dictionaryWithObjectsAndKeys:
            legacyFileElement.value, "file"
        ];
    }

    //append the parameters to the form
    var keys = [_parameters allKeys];
    for (var i = 0, count = keys.length; i < count; i++)
    {
        var theElement = document.createElement("input");

        theElement.type = "hidden";
        theElement.name = keys[i];
        theElement.value = [_parameters objectForKey:keys[i]];

        legacyForm.appendChild(theElement);
    }

    legacyForm.appendChild(legacyFileElement);

    if (_DOMIFrameElement)
    {
        document.body.removeChild(_DOMIFrameElement);
        _DOMIFrameElement.onload = nil;
        _DOMIFrameElement = nil;
    }

    if (window.attachEvent)
    {
        _DOMIFrameElement = document.createElement("<iframe id=\"" + legacyForm.target + "\" name=\"" + legacyForm.target + "\" />");

        if (window.location.href.toLowerCase().indexOf("https") === 0)
            _DOMIFrameElement.src = "javascript:false";
    }
    else
    {
        _DOMIFrameElement = document.createElement("iframe");
        _DOMIFrameElement.name = legacyForm.target;
    }

    _DOMIFrameElement.style.width = "1px";
    _DOMIFrameElement.style.height = "1px";
    _DOMIFrameElement.style.zIndex = -1000;
    _DOMIFrameElement.style.opacity = "0";
    _DOMIFrameElement.style.filter = "alpha(opacity=0)";

    document.body.appendChild(_DOMIFrameElement);

    _onloadHandler = function()
    {
        try
        {
            CATCH_EXCEPTIONS = NO;
            responseText = _DOMIFrameElement.contentWindow.document.body ? _DOMIFrameElement.contentWindow.document.body.innerHTML :
                                                                               _DOMIFrameElement.contentWindow.document.documentElement.textContent;

            [self fileUploadDidEnd];

            window.setTimeout(function()
            {
                document.body.removeChild(_DOMIFrameElement);
                _DOMIFrameElement.onload = nil;
                _DOMIFrameElement = nil;
            }, 100);
            CATCH_EXCEPTIONS = YES;
        }
        catch (e)
        {
            [self uploadDidFailWithError:e];
        }
    }

    if (window.attachEvent)
    {
        _DOMIFrameElement.onreadystatechange = function()
        {
            if (this.readyState == "loaded" || this.readyState == "complete")
                _onloadHandler();
        }
    }

    _DOMIFrameElement.onload = _onloadHandler;

    legacyForm.submit();

    [self fileUploadDidBegin];
}

- (void)_removeUploadFormElements
{
    var index = legacyForm.childNodes.length;
    while (index--)
        legacyForm.removeChild(legacyForm.childNodes[index]);
}

- (void)uploadDidFailWithError:(id)error
{
    CPLog("uploadDidFailWithError: "+ error);
}

@end