@import <AppKit/CPPanel.j>

/*

DCFileDropControllerDropDelegate protocol
- (void)fileDropUploadController:(DCFileDropController *)theController setState:(BOOL)visible;

*/

@implementation DCFileDropController : CPObject {
	CPView view @accessors;
	BOOL enabled @accessors;
	CPURL uploadURL @accessors;
	CPDictionary userInfo @accessors;

	id fileInput;
	id iframeElement;
	id dropDelegate;
	id uploadDelegate @accessors;
	id uploadManager;
	id domElement;
	BOOL insertAsFirstSubview @accessors;
	BOOL isButton @accessors;
	BOOL useEmbeddedFileElement @accessors;

	id fileDroppedEventImplementation;
	id fileDroppedEventCallback;
	id dragExitEventImplementation;
	id dragExitEventCallback;

	// legacy browser support
	CPDictionary _legacyParameters;
	id _legacyUploadForm;
	id _legacyFileUploadElement;
	function _legacyMouseMovedCallback;
	function _legacyMouseUpCallback;
}

+ (BOOL)platformSupportsDeepDropUpload {
	if (typeof(FormData) == "undefined") {
		return NO;
	}
	return YES;
}

+ (BOOL)platformSupportsEmbeddedFileElement {
	if (![CPPlatform isBrowser]) {
		// it's a NativeHost app, so we need to put the file element inside an iframe
		return NO;
	}
	return YES;
}

- (id)initWithView:(CPView)theView dropDelegate:(id)theDropDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager {
	return [self initWithView:theView domElement:theView._DOMElement dropDelegate:theDropDelegate uploadDelegate:nil uploadURL:theUploadURL uploadManager:theUploadManager];
}

- (id)initWithView:(CPView)theView dropDelegate:(id)theDropDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager useEmbeddedFileElement:(BOOL)shouldUseEmbeddedFileElement {
	return [self initWithView:theView domElement:theView._DOMElement dropDelegate:theDropDelegate uploadDelegate:nil uploadURL:theUploadURL uploadManager:theUploadManager useEmbeddedFileElement:shouldUseEmbeddedFileElement];
}

- (id)initWithView:(CPView)theView dropDelegate:(id)theDropDelegate uploadDelegate:(id)theUploadDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager {
	return [self initWithView:theView domElement:theView._DOMElement dropDelegate:theDropDelegate uploadDelegate:theUploadDelegate uploadURL:theUploadURL uploadManager:theUploadManager];
}

- (id)initWithView:(CPView)theView dropDelegate:(id)theDropDelegate uploadDelegate:(id)theUploadDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager useEmbeddedFileElement:(BOOL)shouldUseEmbeddedFileElement {
	return [self initWithView:theView domElement:theView._DOMElement dropDelegate:theDropDelegate uploadDelegate:theUploadDelegate uploadURL:theUploadURL uploadManager:theUploadManager useEmbeddedFileElement:shouldUseEmbeddedFileElement];
}

- (id)initWithView:(CPView)theView domElement:(id)theDomElement dropDelegate:(id)theDropDelegate uploadDelegate:(id)theUploadDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager {
	return [self initWithView:theView domElement:theView._DOMElement dropDelegate:theDropDelegate uploadDelegate:theUploadDelegate uploadURL:theUploadURL uploadManager:theUploadManager useEmbeddedFileElement:[DCFileDropController platformSupportsEmbeddedFileElement]];
}

- (id)initWithView:(CPView)theView domElement:(id)theDomElement dropDelegate:(id)theDropDelegate uploadDelegate:(id)theUploadDelegate uploadURL:(CPURL)theUploadURL uploadManager:(id)theUploadManager useEmbeddedFileElement:(BOOL)shouldUseEmbeddedFileElement {
	self = [super init];

	view = theView;
	domElement = theDomElement;
	dropDelegate = theDropDelegate;
	uploadDelegate = theUploadDelegate;
	uploadURL = theUploadURL;
	uploadManager = theUploadManager;
	useEmbeddedFileElement = shouldUseEmbeddedFileElement;

	[self setFileDropState:NO];

	if (![DCFileDropController platformSupportsDeepDropUpload]) {
		return self;
	}


    // this prevents the little plus sign from showing up when you drag over the body.
    // Otherwise the user could be confused where they can drop the file and it would
    // cause the browser to redirect to the file they just dropped. 
	//var bodyBlockCallback = function(anEvent){ anEvent.dataTransfer.dropEffect = "none"; return NO; };
    //window.document.body.addEventListener("dragover", bodyBlockCallback, NO);

	var theClass = [self class];
	var dragEnterEventImplementation = class_getMethodImplementation(theClass, @selector(fileDraggingEntered:));
	var dragEnterEventCallback = function (anEvent) { anEvent.stopPropagation(); anEvent.preventDefault(); dragEnterEventImplementation(self, nil, anEvent); };
	domElement.addEventListener("dragenter", dragEnterEventCallback, NO);

	fileDroppedEventImplementation = class_getMethodImplementation(theClass, @selector(fileDropped:));
	fileDroppedEventCallback = function (anEvent) { anEvent.stopPropagation(); anEvent.preventDefault(); fileDroppedEventImplementation(self, nil, anEvent); };

	dragExitEventImplementation = class_getMethodImplementation(theClass, @selector(fileDraggingExited:));
	dragExitEventCallback = function (anEvent) { anEvent.stopPropagation(); anEvent.preventDefault(); dragExitEventImplementation(self, nil, anEvent); };

	if (useEmbeddedFileElement) {
		fileInput = document.createElement("input");
		fileInput.type = "file";
		fileInput.id = "filesUpload";
		fileInput.style.position = "absolute";
		fileInput.style.top = "0px";
		fileInput.style.left = "0px";
		fileInput.style.backgroundColor = "#00FF00";
		fileInput.style.opacity = "0";
		if (!isWinSafari) {
			fileInput.setAttribute("multiple",true);
		}
		fileInput.addEventListener("change", fileDroppedEventCallback, NO);
		fileInput.addEventListener("dragleave", dragExitEventCallback, NO);
	} else {
		// in the NativeHost app, we need to put the fileInput element inside an iframe
		iframeElement = document.createElement("iframe");
		iframeElement.style.backgroundColor = "rgba(0,0,0,0)";
		iframeElement.style.border = "0px";
		iframeElement.style.zIndex = "101";
		iframeElement.style.position = "absolute";
		iframeElement.src = "about:blank";
	}

	[self setFileElementVisible:NO];

	return self;
}

- (void)setFileDropState:(BOOL)visible {
	if ([dropDelegate respondsToSelector:@selector(fileDropUploadController:setState:)]) {
		[dropDelegate fileDropUploadController:self setState:visible];
	}
}

- (void)setIsButton:(BOOL)shouldBeButton {
	isButton = shouldBeButton;
	if ([DCFileDropController platformSupportsDeepDropUpload]) {
		// it's a new browser that supports the deep drop upload with progress
		[self setFileElementVisible:isButton];
	} else {
		// it's a legacy browser
		if (isButton) {
			// create the form if it doesn't exist
			[self addLegacyForm];
		} else {
			// remove form
			[self removeLegacyForm];
		}
	}
}

- (void)setFileElementVisible:(BOOL)yesNo {
	if (useEmbeddedFileElement) {
		if (!fileInput) {
			return;
		}
		if (yesNo || isButton) {
			fileInput.style.width = "100%";
			fileInput.style.height = "100%";
			if (insertAsFirstSubview == YES && domElement.firstChild) {
				domElement.insertBefore(fileInput, domElement.firstChild);
			} else {
				domElement.appendChild(fileInput);
			}
		} else {
			fileInput.style.width = "0%";
			fileInput.style.height = "0%";
			if (fileInput.parentNode) {
				fileInput.parentNode.removeChild(fileInput);
			}
		}
	} else {
		// in the NativeHost app, we need to put the fileInput element inside an iframe
		if (!iframeElement) {
			return;
		}
		if (yesNo || isButton) {
			iframeElement.style.width = "100%";
			iframeElement.style.height = "100%";
			if (insertAsFirstSubview == YES && domElement.firstChild) {
				domElement.insertBefore(iframeElement, domElement.firstChild);
			} else {
				domElement.appendChild(iframeElement);
			}
			window.setTimeout(function() {
				iframeElement.src = "about:blank";
				iframeElement.contentWindow.document.write("<input type='file' id='fileElement' />");
				iframeElement.contentWindow.document.body.style.overflow = "hidden";
				fileInput = iframeElement.contentWindow.document.getElementById("fileElement");
				fileInput.style.position = "absolute";
				fileInput.style.top = "0px";
				fileInput.style.left = "0px";
				fileInput.style.width = "100%";
				fileInput.style.height = "100%";
				fileInput.style.opacity = "0";
				fileInput.style.background = "#CCFFCC";
				if (!isWinSafari) {
					fileInput.setAttribute("multiple",true);
				}
				fileInput.addEventListener("change", fileDroppedEventCallback, NO);
				fileInput.addEventListener("dragleave", dragExitEventCallback, NO);
			}, 0);
		} else {
			iframeElement.style.width = "0%";
			iframeElement.style.height = "0%";
			if (iframeElement.parentNode) {
				iframeElement.parentNode.removeChild(iframeElement);
			}
		}
	}
}

- (void)fileDraggingEntered:(id)sender {
	if (!enabled) {
		return;
	}

	// check if an internal Cappuccino drag is already happening
	if ([[CPDragServer sharedDragServer] isDragging]) {
		return;
	}

	[self setFileDropState:YES];
	[self setFileElementVisible:YES];
}

- (void)fileDraggingExited:(id)sender {
	[self setFileDropState:NO];
	[self setFileElementVisible:NO];
}

- (void)fileDropped:(id)sender {
	if (!enabled) {
		return;
	}

	[self setFileDropState:NO];
	[self setFileElementVisible:NO];

	if (!uploadURL) {
		alert("Pick an upload destination.");
	} else {
		var files = nil;
		if (sender.target.files) {
			files = sender.target.files;
		} else if (sender.dataTransfer.files) {
			files = sender.dataTransfer.files;
		}
		[self processFiles:files];
	}

	// now clear the input 
	fileInput.value = nil;
}

- (void)processFiles:(CPArray)files {
	for(var i = 0, len = files.length; i < len; i++) {
		if ([uploadManager respondsToSelector:@selector(fileUploadWithFile:uploadURL:uploadDelegate:userInfo:)]) {
			[uploadManager fileUploadWithFile:files[i] uploadURL:uploadURL uploadDelegate:uploadDelegate userInfo:userInfo];
		}
	}
}


// ************************* Legacy Browser Support *************************

- (void)addLegacyForm {
	_legacyUploadForm = document.createElement("form");
	
	_legacyUploadForm.method = "POST";
	_legacyUploadForm.action = "#";

	if(document.attachEvent)
		_legacyUploadForm.encoding = "multipart/form-data";
	else
		_legacyUploadForm.enctype = "multipart/form-data";
	
	_legacyFileUploadElement = document.createElement("input");
	
	_legacyFileUploadElement.type = "file";
	_legacyFileUploadElement.name = "file[]";
	
	_legacyFileUploadElement.onmousedown = function(aDOMEvent)
	{	 
		aDOMEvent = aDOMEvent || window.event;
		
		var x = aDOMEvent.clientX,
			y = aDOMEvent.clientY,
			theWindow = [view window];
		
		[CPApp sendEvent:[CPEvent mouseEventWithType:CPLeftMouseDown location:[theWindow convertBridgeToBase:CGPointMake(x, y)]
			modifierFlags:0 timestamp:0 windowNumber:[theWindow windowNumber] context:nil eventNumber:-1 clickCount:1 pressure:0]];
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode]; 
		
		if (document.addEventListener)
		{
			document.addEventListener(CPDOMEventMouseUp, _legacyMouseUpCallback, NO);
			document.addEventListener(CPDOMEventMouseMoved, _legacyMouseMovedCallback, NO);
		}
		else if(document.attachEvent)
		{
			document.attachEvent("on" + CPDOMEventMouseUp, _legacyMouseUpCallback);
			document.attachEvent("on" + CPDOMEventMouseMoved, _legacyMouseMovedCallback);
		}
	}

	_legacyMouseUpCallback = function(aDOMEvent)
	{
		if (document.removeEventListener)
		{
			document.removeEventListener(CPDOMEventMouseUp, _legacyMouseUpCallback, NO);
			document.removeEventListener(CPDOMEventMouseMoved, _legacyMouseMovedCallback, NO);
		}
		else if(document.attachEvent)
		{
			document.detachEvent("on" + CPDOMEventMouseUp, _legacyMouseUpCallback);
			document.detachEvent("on" + CPDOMEventMouseMoved, _legacyMouseMovedCallback);
		}
		
		aDOMEvent = aDOMEvent || window.event;
		
		var x = aDOMEvent.clientX,
			y = aDOMEvent.clientY,
			theWindow = [view window];
		
		[CPApp sendEvent:[CPEvent mouseEventWithType:CPLeftMouseUp location:[theWindow convertBridgeToBase:CGPointMake(x, y)]
		   modifierFlags:0 timestamp:0 windowNumber:[theWindow windowNumber] context:nil eventNumber:-1 clickCount:1 pressure:0]];
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode]; 
	}
	
	_legacyMouseMovedCallback = function(aDOMEvent)
	{
		aDOMEvent = aDOMEvent || window.event;
		
		var x = aDOMEvent.clientX,
			y = aDOMEvent.clientY,
			theWindow = [view window];
		
		[CPApp sendEvent:[CPEvent mouseEventWithType:CPLeftMouseDragged location:[theWindow convertBridgeToBase:CGPointMake(x, y)]
		   modifierFlags:0 timestamp:0 windowNumber:[theWindow windowNumber] context:nil eventNumber:-1 clickCount:1 pressure:0]];
	}
	
	_legacyUploadForm.style.position = "absolute";
	_legacyUploadForm.style.top = "0px";
	_legacyUploadForm.style.left = "0px";
	_legacyUploadForm.style.zIndex = 1000;
	
	_legacyFileUploadElement.style.opacity = "0";
	_legacyFileUploadElement.style.filter = "alpha(opacity=0)";
	
	_legacyUploadForm.style.width = "100%";
	_legacyUploadForm.style.height = "100%";
	
	_legacyFileUploadElement.style.fontSize = "1000px";
	
	if (document.attachEvent)
	{
		_legacyFileUploadElement.style.position = "relative";
		_legacyFileUploadElement.style.top = "-10px";
		_legacyFileUploadElement.style.left = "-10px";
		_legacyFileUploadElement.style.width = "1px";
	}
	else
		_legacyFileUploadElement.style.cssFloat = "right";	
				   
	_legacyFileUploadElement.onchange = function()
	{
		[self uploadSelectionDidChange: [self selection]];
	};
	
	_legacyUploadForm.appendChild(_legacyFileUploadElement);
	
	domElement.appendChild(_legacyUploadForm);
	
	_legacyParameters = [CPDictionary dictionary];
}

- (void)removeLegacyForm {
	if (_legacyUploadForm) {
		if (_legacyUploadForm.parentNode()) {
			_legacyUploadForm.parentNode().removeChild(_legacyUploadForm);
		}
	}
}

- (void)uploadSelectionDidChange:(CPArray)selection {
	// create a file upload with the form
	if ([uploadManager respondsToSelector:@selector(fileUploadWithForm:fileElement:uploadURL:uploadDelegate:userInfo:)]) {
		[uploadManager fileUploadWithForm:_legacyUploadForm fileElement:_legacyFileUploadElement uploadURL:uploadURL uploadDelegate:uploadDelegate userInfo:userInfo];
	}
	[self resetSelection];
}

- (CPArray)selection {
	var selection = [CPArray  array];

	if(_legacyFileUploadElement.files) {
		for(var i = 0; i < _legacyFileUploadElement.files.length; i++) {
			[selection addObject:_legacyFileUploadElement.files.item(i).fileName];
		}
	} else {
		[selection addObject:_legacyFileUploadElement.value];
	}

	return selection;
}

- (void)resetSelection {
	_legacyFileUploadElement.value = "";
}

@end
