/*
Module Name:
    Window.cpp demostrates the use of Objective C for Windowing in macOS
    This Code Works To Create Triangle Perspective Projection in OpenGL on mac

Abstract:
    Ortho Triangle

Revision History:
    Date:	Dec 18, 2019.
    Desc:	Started

    Date:	Dec 18, 2019.
    Desc:	Done
*/

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import "vmath.h"

//////////////////////////////////////////////////////////////////////////
// Global Variables declarations and initializations
//////////////////////////////////////////////////////////////////////////

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXTURE0
};

// 'C' Style global function declaration
CVReturn MyDisplayLinkCallback(CVDisplayLinkRef,
                    const CVTimeStamp *,
                    const CVTimeStamp *,
                    CVOptionFlags,
                    CVOptionFlags *,
                    void *);

FILE *gpFile = NULL;

/////////////////////////////////////////////////////////////////////
//	I N T E R F A C E  D E C L A R A T I O N S
/////////////////////////////////////////////////////////////////////

// interface declarations
@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@end

@interface GlView : NSOpenGLView
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

// interface implementations
@implementation AppDelegate
{
@private
    NSWindow *window;
    GlView *glView;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // code
    // Log File Genereation
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *appDirName = [mainBundle bundlePath];
    NSString *parentDirPath = [appDirName stringByDeletingLastPathComponent];
    NSString *logFileNameWithPath = [NSString stringWithFormat:@"%@/Log.txt", parentDirPath];
    const char *pszLogFileNameWithPath = [logFileNameWithPath
        cStringUsingEncoding:NSASCIIStringEncoding];
    gpFile = fopen(pszLogFileNameWithPath, "w");
    if(NULL == gpFile)
    {
        printf("Can not Create Log File. \nExiting ...\n");
        [self release];
        [NSApp terminate:self];
    }

    fprintf(gpFile, "Program Is Started Successfully");

    // window
    NSRect win_rect;
    win_rect = NSMakeRect(0.0, 0.0, 800.0, 600.0);

    // create simple window
    window = [[NSWindow alloc] initWithContentRect:win_rect
                        styleMask:NSWindowStyleMaskTitled
                        | NSWindowStyleMaskClosable 
                        | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                        backing:NSBackingStoreBuffered
                        defer:NO];

    [window setTitle:@"macOS OpenGL Window"];
    [window center];

    glView=[[GlView alloc]initWithFrame:win_rect];
    [window setContentView:glView];
    [window setDelegate:self];
    [window makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate: (NSNotification *)notification
{
    // code
    fprintf(gpFile, "Program Is Terminated Successfully\n");

    if(gpFile)
    {
        fclose(gpFile);
        gpFile = NULL;
    }
}

- (void)windowWillClose:(NSNotification *)notification;
{
    // code
    [NSApp terminate:self];
}

- (void)dealloc
{
    // code
    [glView release];

    [window release];

    [super dealloc];
}
@end

@implementation GlView
{
@private
    CVDisplayLinkRef displayLink;

    // ortho change
    GLuint vertexShaderObject;
    GLuint fragmentShaderObject;
    GLuint shaderProgramObject;

    GLuint vao;
    GLuint vbo;

    GLuint vao_Circle;
    GLuint vbo_Circle;

    GLuint vao_verticalLines;
    GLuint vbo_verticalLines;

    GLuint vao_Rectangle;
    GLuint vbo_Rectangle;

    GLuint vao_Triangle;
    GLuint vbo_Triangle;

    GLuint vao_In_Circle;
    GLuint vbo_In_Circle;

    GLuint mvpUniform;
    GLuint colorUniform;

    vmath:: mat4 perspectiveProjectionMatrix;
}

-(id)initWithFrame:(NSRect)frame;
{
    // code
    self = [super initWithFrame:frame];

    if(self)
    {
        [[self window]setContentView:self];

        NSOpenGLPixelFormatAttribute attrs[] =
        {
            NSOpenGLPFAOpenGLProfile,
            NSOpenGLProfileVersion4_1Core,
            NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask
                (kCGDirectMainDisplay),
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFADoubleBuffer,
            0
        };

        NSOpenGLPixelFormat *pixelFormat = [[[NSOpenGLPixelFormat alloc]
            initWithAttributes:attrs] autorelease];

        if(nil == pixelFormat)
        {
            fprintf(gpFile, "No Valid OpenGL Pixel Format Is Available. Existing...");
            [self release];
            [NSApp terminate:self];
        }

        NSOpenGLContext *glContext = [[[NSOpenGLContext alloc]
            initWithFormat:pixelFormat shareContext:nil]autorelease];

        [self setPixelFormat:pixelFormat];
        [self setOpenGLContext:glContext]; // it automatically releases the older context

        // centralText=@"Hello World !!!";
    }

    return(self);
}

-(CVReturn)getFrameForTime:(const CVTimeStamp *)pOutputTime
{
    //code
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    [self drawView];

    [pool release];
    return(kCVReturnSuccess);
}

-(void)prepareOpenGL
{
    // code
    // OpenGL Info
    fprintf(gpFile, "OpenGL Version : %s\n", glGetString(GL_VERSION));
    fprintf(gpFile, "GLSL Version : %s\n", glGetString(GL_SHADING_LANGUAGE_VERSION));

    [[self openGLContext]makeCurrentContext];

    GLint swapInt = 1;
    [[self openGLContext]setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

    // *** Vertex Shader ***

    vertexShaderObject = glCreateShader(GL_VERTEX_SHADER);

    const GLchar *vertexShaderSourceCode =
        "#version 410 core" \
        "\n" \
        "in vec4 vPosition;" \
        "uniform mat4 u_mvp_matrix;" \
        "void main(void)" \
        "{" \
        "gl_Position = u_mvp_matrix * vPosition;" \
        "}";

    // specify above code of shader to vertext shader object
    glShaderSource(vertexShaderObject,
        1,
        (const GLchar**)(&vertexShaderSourceCode),
        NULL);

    glCompileShader(vertexShaderObject);

    // catching shader related errors if there are any
    GLint iShaderCompileStatus = 0;
    GLint iInfoLogLength = 0;
    GLchar *szInfoLog = NULL;

    // getting compile status code
    glGetShaderiv(vertexShaderObject,
        GL_COMPILE_STATUS,
        &iShaderCompileStatus);

    if(GL_FALSE == iShaderCompileStatus)
    {
        glGetShaderiv(vertexShaderObject, GL_INFO_LOG_LENGTH,
            &iInfoLogLength);
        if(iInfoLogLength > 0)
        {
            szInfoLog = (GLchar *)malloc(iInfoLogLength);
            if(NULL != szInfoLog)
            {
                GLsizei written;

                glGetShaderInfoLog(
                    vertexShaderObject,
                    iInfoLogLength,
                    &written,
                    szInfoLog
                );

                fprintf(gpFile, "VERTEX SHADER FATAL ERROR: %s\n", szInfoLog);
                free(szInfoLog);
                [self release];
                [NSApp terminate:self];
            }
        }
    }

    // ***  Fragment Shader
    // re-initialize
    // catching shader related errors if there are any
    iShaderCompileStatus = 0;
    iInfoLogLength = 0;
    szInfoLog = NULL;

    fragmentShaderObject = glCreateShader(GL_FRAGMENT_SHADER);
    const GLchar *pcFragmentShaderSourceCode = 
    "#version 410 core" \
    "\n" \
    "out vec4 vFragColor;" \
    "uniform vec4 u_vLineColor;" \
    "void main(void)" \
    "{" \
        "vFragColor = u_vLineColor;" \
    "}";

    // specify above code of shader to vertext shader object
    glShaderSource(fragmentShaderObject,
        1,
        (const GLchar**)&pcFragmentShaderSourceCode,
        NULL);

    // compile the vertext shader
    glCompileShader(fragmentShaderObject);

    // getting compile status code
    glGetShaderiv(fragmentShaderObject,
        GL_COMPILE_STATUS,
        &iShaderCompileStatus);

    if (GL_FALSE == iShaderCompileStatus)
    {
        glGetShaderiv(fragmentShaderObject,
        GL_INFO_LOG_LENGTH,
        &iInfoLogLength);

    if (iInfoLogLength > 0)
    {
            szInfoLog = (GLchar *)malloc(iInfoLogLength);
            if (NULL != szInfoLog)
            {
                GLsizei written;

                glGetShaderInfoLog(
                        fragmentShaderObject,
                        iInfoLogLength,
                        &written,
                        szInfoLog
                    );

                fprintf(gpFile, ("FRAGMENT SHADER FATAL COMPILATION ERROR: %s\n"), szInfoLog);
                free(szInfoLog);
                [self release];
                [NSApp terminate:self];
            }
        }
    }

    // create shader program objects
    shaderProgramObject = glCreateProgram();

    // attach fragment shader to shader program
    glAttachShader(shaderProgramObject, vertexShaderObject);
    glAttachShader(shaderProgramObject, fragmentShaderObject);

    // Before Prelinking bind binding our no to vertex attribute
    // change for Ortho
    // here we binded gpu`s variable to cpu`s index
    glBindAttribLocation(shaderProgramObject,
        AMC_ATTRIBUTE_POSITION,
        "vPosition");

    // link the shader
    glLinkProgram(shaderProgramObject);

    GLint iShaderProgramLinkStatus = 0;
    iInfoLogLength = 0;
    
    glGetProgramiv(shaderProgramObject,
        GL_LINK_STATUS,
        &iShaderProgramLinkStatus);

    if(GL_FALSE == iShaderProgramLinkStatus)
    {
        glGetProgramiv(shaderProgramObject, GL_LINK_STATUS,
            &iInfoLogLength);

        if(iInfoLogLength > 0)
        {
            szInfoLog = NULL;
            szInfoLog = (char *)malloc(iInfoLogLength);
            if(NULL != szInfoLog)
            {
                GLsizei written;
                glGetProgramInfoLog(shaderProgramObject, iInfoLogLength,
                    &written, szInfoLog);
                fprintf(gpFile, "Shader Program Link Log: %s \n", szInfoLog);
                free(szInfoLog);
                [self release];
                [NSApp terminate:self];
            }
        }
    }

    // now this is rule: attribute binding should happen before linking program and
    // uniforms binding should happen after linking
    mvpUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_mvp_matrix"
    );

    colorUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_vLineColor"
    );

    GLfloat fLineArray[126];
    int flag = 0;
    GLfloat fFact = -1.0f;
    int ind;
    for (ind = 0; ind < 42; ind++)
    {
        fLineArray[ind * 3 + 1] = fFact;
        fLineArray[ind * 3 + 2] = 0.0f;
        if (0 == flag)
        {
            fLineArray[ind * 3] = -1.0f;
        }
        else
        {
            fLineArray[ind * 3] = 1.0f;
            fFact += 0.1;
        }

        if (1 == flag)
        {
            flag = 0;
        }
        else
        {
        flag = 1;
        }
    }

    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER,
            sizeof(fLineArray),
            fLineArray,
            GL_STATIC_DRAW);

    glVertexAttribPointer(
            AMC_ATTRIBUTE_POSITION,
            3,									// how many co-ordinates in vertice
            GL_FLOAT,							// type of above data
            GL_FALSE,							// no normalization is desired
            0,									// (dangha)
            NULL								// offset to start in above attrib position
        );

    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    // For VERTICAL Lines
    float fVerticalLines[126];
    flag = 0;
    fFact = -1.0f;
    for (ind = 0; ind < 42; ind++)
    {
        fVerticalLines[ind * 3] = fFact;
        fVerticalLines[ind * 3 + 2] = 0.0f;
        if (0 == flag)
        {
            fVerticalLines[ind * 3 + 1] = -1.0f;
        }
        else
        {
            fVerticalLines[ind * 3 + 1] = 1.0f;
            fFact += 0.1;
        }

        if (1 == flag)
        {
            flag = 0;
        }
        else
        {
            flag = 1;
        }
    }

	glGenVertexArrays(1, &vao_verticalLines);
	glBindVertexArray(vao_verticalLines);

	glGenBuffers(1, &vbo_verticalLines);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_verticalLines);
	glBufferData(GL_ARRAY_BUFFER,
		sizeof(fVerticalLines),
		fVerticalLines,
		GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		3,									// how many co-ordinates in vertice
		GL_FLOAT,							// type of above data
		GL_FALSE,							// no normalization is desired
		0,									// (dangha)
		NULL								// offset to start in above attrib position
	);

    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    // circle
    GLfloat fAngle = 0.0f;
    float fCirclePositions[1000 * 3];
    for (ind = 0; ind < 1000; ind++)
    {
        fAngle = 2.0f * M_PI * ind / 1000;
        fCirclePositions[ind * 3] = cos(fAngle);
        fCirclePositions[ind * 3 + 1] = sin(fAngle);
        fCirclePositions[ind * 3 + 2] = 0.0f;
    }

    glGenVertexArrays(1, &vao_Circle);
    glBindVertexArray(vao_Circle);
    glGenBuffers(1, &vbo_Circle);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_Circle);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fCirclePositions), fCirclePositions, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    //
    // Rectangle
    //
    GLfloat fSide = sqrt(0.5f);
    const GLfloat fArrayRectangle[] = {
        fSide, fSide, 0.0f,
        -fSide, fSide, 0.0f,

        -fSide, fSide, 0.0f,
        -fSide, -fSide, 0.0f,

        -fSide, -fSide, 0.0f,
        fSide, -fSide, 0.0f,

        fSide, -fSide, 0.0f,
        fSide, fSide, 0.0f
    };

    glGenVertexArrays(1, &vao_Rectangle);
    glBindVertexArray(vao_Rectangle);
    glGenBuffers(1, &vbo_Rectangle);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_Rectangle);
    glBufferData(GL_ARRAY_BUFFER,
        sizeof(fArrayRectangle),
        fArrayRectangle,
        GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    // Triangle for Incircle
    // Side of Triangle - fSide 

    // Calculating lengths of sides
    GLfloat fx, fy, fTempfA, fTempfB, fDistA, fDistB, fDistC;

    fx = fy = fSide;
    fTempfA = -fx;
    fTempfB = -2 * fy;
    fDistA = sqrt(fTempfA*fTempfA + fTempfB * fTempfB);
    fTempfA = 2 * fx;
    fTempfB = 0.0f;
    fDistB = sqrt(fTempfA*fTempfA + fTempfB * fTempfB);
    fTempfA = -fx;
    fTempfB = 2 * fy;
    fDistC = sqrt(fTempfA * fTempfA + fTempfB * fTempfB);

    const GLfloat fInTriangle[] = { 0.0f, fy, 0.0f,
        -fx, -fy, 0.0f,
        -fx, -fy, 0.0f,
        fx, -fy, 0.0f,
        fx, -fy, 0.0f,
        0.0f, fy, 0.0f
    };

    glGenVertexArrays(1, &vao_Triangle);
    glBindVertexArray(vao_Triangle);

    glGenBuffers(1, &vbo_Triangle);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_Triangle);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fInTriangle), fInTriangle, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    //
    // In-Circle
    // 
    GLfloat fIncircleXCord, fIncircleYCord, fSemiPerimeter, fAreaSquare, fArea, fInRadius;

    fIncircleXCord = ((fDistB) * 0.0f) + ((fDistC * (-fx)) + ((fDistA) * fx))
                / (fDistA + fDistB + fDistC);

    fIncircleYCord = (((fDistB) * fy) + (fDistC * (-fy)) + ((fDistA) * (-fy)))
        / (fDistA + fDistB + fDistC);

    fSemiPerimeter = (fDistA + fDistB + fDistC) / 2;

    fAreaSquare = (fSemiPerimeter - fDistA)
        * (fSemiPerimeter - fDistB)
        * (fSemiPerimeter - fDistC) * fSemiPerimeter;

    fArea = sqrt(fAreaSquare);
    fInRadius = fArea / fSemiPerimeter;

    ind = 0;
    fAngle = 0.0f;
    float fInCirclePositions[1000 * 3];
    for (ind = 0; ind < 1000; ind++)
    {
        fAngle = 2.0f * M_PI * ind / 1000;
        fInCirclePositions[ind * 3] = fInRadius * cos(fAngle) + fIncircleXCord;
        fInCirclePositions[ind * 3 + 1] = fInRadius * sin(fAngle) + fIncircleYCord;
        fInCirclePositions[ind * 3 + 2] = 0.0f;
    }

    glGenVertexArrays(1, &vao_In_Circle);
    glBindVertexArray(vao_In_Circle);

    glGenBuffers(1, &vbo_In_Circle);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_In_Circle);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fInCirclePositions), fInCirclePositions, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_CULL_FACE);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClearDepth(1.0f);

    // set projection  Matrix
    perspectiveProjectionMatrix = vmath::mat4::identity();

    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
    CGLContextObj cglContext= (CGLContextObj)[[self openGLContext]CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat]CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    CVDisplayLinkStart(displayLink);
}

-(void)reshape
{
    // code
    CGLLockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);

    NSRect rect = [self bounds];

    GLfloat width = rect.size.width;
    GLfloat height = rect.size.height;

    if(0 == height)
    {
        height = 1;
    }

    glViewport(0, 0, (GLsizei)width, (GLsizei)height);

    perspectiveProjectionMatrix = vmath::perspective(45.0f, (GLfloat)width/(GLfloat)height, 0.1f, 100.0f);
    CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

- (void)drawRect:(NSRect)dirtyRect
{
    // code
    [self drawView];
}

- (void)drawView
{
    // Declaration of matrices

    // code
    [[self openGLContext]makeCurrentContext];

    CGLLockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(shaderProgramObject);

    // initialize above matrices to identity
    vmath::mat4 modelViewMatrix = vmath::mat4::identity();
    vmath::mat4 modelViewProjectionMatrix = vmath::mat4::identity();

    modelViewMatrix = vmath::translate(0.0f, 0.0f, -3.0f);
    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix;

    // uniforms are given to m_uv_matrix (i.e. model view matrix)
    glUniformMatrix4fv(
            mvpUniform,
            1,          //  how many matrices
            GL_FALSE,   //  Transpose is needed ? ->
            modelViewProjectionMatrix
        );

    glUniform4f(colorUniform, 0.0f, 0.0f, 1.0f, 1.0f);

    // bind with vow (this is avoiding many necessary binding with vbos)
    glBindVertexArray(vao);

    glLineWidth(0.5f);
    glDrawArrays(GL_LINES,  0,  20);

    glLineWidth(2.0f);
    glUniform4f(colorUniform, 1.0f, 0.0f, 0.0f, 1.0f);
    glDrawArrays(GL_LINES, 20, 2);

    glLineWidth(0.5f);
    glUniform4f(colorUniform, 0.0f, 0.0f, 1.0f, 1.0f);
    glDrawArrays(GL_LINES, 22, 20);
    glBindVertexArray(0);

    glBindVertexArray(vao_verticalLines);

    glLineWidth(0.5f);
    glDrawArrays(GL_LINES, 0, 20);

    glLineWidth(2.0f);
    glUniform4f(colorUniform, 0.0f, 1.0f, 0.0f, 1.0f);
    glDrawArrays(GL_LINES, 20, 2);

    glLineWidth(0.5f);
    glUniform4f(colorUniform, 0.0f, 0.0f, 1.0f, 1.0f);
    glDrawArrays(GL_LINES, 22, 20);
    glBindVertexArray(0);


    //
    // Circle
    //
    modelViewMatrix = mat4::identity();
    modelViewProjectionMatrix = mat4::identity();

    modelViewMatrix = translate(0.0f, 0.0f, -3.0f);
    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix;

    // uniforms are given to m_uv_matrix (i.e. model view matrix)
    glUniformMatrix4fv(
    	mvpUniform,
    	1,			//	how many matrices
    	GL_FALSE,	//	Transpose is needed ? ->
    	modelViewProjectionMatrix
    );
    glUniform4f(colorUniform, 1.0f, 1.0f, 0.0f, 1.0f); // red + green = yellow

    glBindVertexArray(vao_Circle);
    glLineWidth(0.5f);
    glDrawArrays(GL_LINE_LOOP, 0, 1000);
    glBindVertexArray(0);

    //
    // Rectangle
    //
    glBindVertexArray(vao_Rectangle);
    glLineWidth(1.5f);
    glUniform4f(colorUniform, 1.0f, 1.0f, 0.0f, 1.0f); // red + green = yellow
    glDrawArrays(GL_LINES, 0, 8);
    glBindVertexArray(0);

    //
    // Triangle
    //
    glBindVertexArray(vao_Triangle);
    glDrawArrays(GL_LINES, 0, 6);
    glBindVertexArray(0);

    //
    // In-Circle
    //
    glBindVertexArray(vao_In_Circle);
    glDrawArrays(GL_LINE_LOOP, 0, 1000);
    glBindVertexArray(0);

    glUseProgram(0);

    CGLFlushDrawable((CGLContextObj)[[self openGLContext]CGLContextObj]);
    CGLUnlockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);
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
    int key = (int)[[theEvent characters]characterAtIndex:0];
    switch(key)
    {
        case 27: // Esc Key
            [self release];
            [NSApp terminate:self];
            break;

        case 'F':
        case 'f':
            //centralText = @"'F' or 'f' Key Is Pressed";
            [[self window]toggleFullScreen:self]; // repainting occurs
            break;

        default:
            break;
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    // code
    // centralText = @"Left Mouse Button Is Clicked";
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    // code
}

-(void)rightMouseDown:(NSEvent *)theEvent
{
    // code
}

-(void) dealloc
{
    // code
    if(vbo_In_Circle)
    {
        glDeleteBuffers(1, &vbo_In_Circle);
        vbo_In_Circle = 0;
    }

    if (vao_In_Circle)
    {
        glDeleteVertexArrays(1, &vao_In_Circle);
        vao_In_Circle = 0;
    }


    if(vbo_Triangle)
    {
        glDeleteBuffers(1, &vbo_Triangle);
        vbo_Triangle = 0;
    }

    if (vao_Triangle)
    {
        glDeleteVertexArrays(1, &vao_Triangle);
        vao_Triangle = 0;
    }

    if(vbo_Rectangle)
    {
        glDeleteBuffers(1, &vbo_Rectangle);
        vbo_Rectangle = 0;
    }

    if (vao_Rectangle)
    {
        glDeleteVertexArrays(1, &vao_Rectangle);
        vao_Rectangle = 0;
    }

    if(vbo_Circle)
    {
        glDeleteBuffers(1, &vbo_Circle);
        vbo_Circle = 0;
    }

    if (vao_Circle)
    {
        glDeleteVertexArrays(1, &vao_Circle);
        vao_Circle = 0;
    }

    if(vbo)
    {
        glDeleteBuffers(1, &vbo);
        vbo = 0;
    }

    if (vao)
    {
        glDeleteVertexArrays(1, &vao);
        vao = 0;
    }

    if(vbo_verticalLines)
    {
        glDeleteBuffers(1, &vbo_verticalLines);
        vbo = 0;
    }

    if (vao_verticalLines)
    {
        glDeleteVertexArrays(1, &vao_verticalLines);
        vao = 0;
    }

    glDetachShader(shaderProgramObject, vertexShaderObject);
    glDetachShader(shaderProgramObject, fragmentShaderObject);

    glDeleteShader(vertexShaderObject);
    vertexShaderObject = 0;

    glDeleteShader(fragmentShaderObject);
    fragmentShaderObject = 0;

    glDeleteProgram(shaderProgramObject);
    shaderProgramObject = 0;

    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);

    [super dealloc];
}
@end

CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp
    *pNow, const CVTimeStamp *pOutputTime, CVOptionFlags flagsIn,
                                CVOptionFlags *pFlagsOut, void
                            *pDisplayLinkContext)
{
    CVReturn result = [(GlView *)pDisplayLinkContext getFrameForTime:pOutputTime];
    return(result);
}
