/*
Module Name:
    Window.cpp demostrates the use of Objective C for Windowing in macOS
    This Code Works To Create Triangle Perspective Projection in OpenGL on mac

Abstract:
    Ortho Triangle

Revision History:
    Date:   Dec 18, 2019.
    Desc:   Started

    Date:   Dec 18, 2019.
    Desc:   Done

*/

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import "vmath.h"

/////////////////////////////////////////////////////
// Global Variables declarations and initializations
/////////////////////////////////////////////////////

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXTURE0
};

#define SAFFRON 1.0f, (153.0f / 256.0f), (51.0f / 256.0f)
#define GREEN (18.0f / 256.0f), (136.0f / 256.0f), (7.0f / 256.0f)

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

    GLuint vao_I; // vertex array object
    GLuint vbo_I_Position;
    GLuint vbo_I_Color;

    GLuint vao_N;
    GLuint vbo_N_Position;
    GLuint vbo_N_Color;

    GLuint vao_D;
    GLuint vbo_D_Position;
    GLuint vbo_D_Color;

    GLuint vao_I2;
    GLuint vbo_I2_Position;
    GLuint vbo_I2_Color;

    GLuint vao_A;
    GLuint vbo_A_Position;
    GLuint vbo_A_Color;

    GLuint mvpUniform;

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
        "in vec4 vColor;" \
        "out vec4 voutColor;" \

        "uniform mat4 u_mvp_matrix;" \
        "void main(void)" \
        "{" \
            "gl_Position = u_mvp_matrix * vPosition;" \
            "voutColor = vColor;" \
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
    "in vec4 voutColor;"
    "out vec4 vFragColor;" \
    "void main(void)" \
    "{" \
    "vFragColor = voutColor;" \
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

    glBindAttribLocation(shaderProgramObject,
        AMC_ATTRIBUTE_POSITION,
        "vColor");

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

    GLfloat fOffN;				// letter N starts at this X pos 
    GLfloat fOffD;				// letter D starts at this X pos
    GLfloat fOffA;
    GLfloat fOffI2;
    GLfloat fOffI1;
    GLfloat fLine1x;
    GLfloat fLine1y;
    GLfloat fLine2x;
    GLfloat fLine2y;
    GLfloat fhSpace;
    GLfloat fwSpace;
    GLfloat fWidthH;
    GLfloat fHeightH;
    GLfloat fOffForN;
    GLfloat fOffForD;
    GLfloat fOffForA;
    GLfloat fLetterWidth;

    const GLfloat cfHeight = 4.1f;
    const GLfloat cfWidth = 7.4f;

    // Drawing Letter I

    fWidthH = cfWidth / 2;
    fHeightH = cfHeight / 2;
    fwSpace = 15 * cfWidth / 100;
    fhSpace = 18 * cfHeight / 100;

    GLfloat Yoff;
    GLfloat fTemp;
    GLfloat fHeight;
    GLfloat fLetterSpace;		// like between I and N with space between them

    fTemp = (fWidthH - fwSpace) - (-(fWidthH - fwSpace));
    fLetterSpace = fTemp / 5;

    fOffI1 = -(fWidthH - fwSpace);
    fOffN = fOffI1 + fLetterSpace;
    fOffD = fOffN + fLetterSpace;
    fOffI2 = fOffD + fLetterSpace;
    fOffA = fOffI2 + fLetterSpace;

	fLetterWidth = fLetterSpace / 4;

	fOffForN = fOffI1 + fLetterSpace;
	fOffForD = fOffForN + fLetterSpace;
	fOffI2 = fOffForD + fLetterSpace;
	fOffForA = fOffI2 + fLetterSpace;

	GLfloat fOffX = -2.35;
	Yoff = fHeightH - fhSpace;
	GLfloat fWidth = fLetterWidth;
	fHeight = -(fHeightH - fhSpace);

	const GLfloat fLineArray[] =
	{
		fOffX + fWidth,Yoff, 0.0f,
		fOffX, Yoff, 0.0f,
		fOffX, fHeight, 0.0f,
		fOffX + fWidth, fHeight, 0.0f
	};

	glGenVertexArrays(1, &vao_I);
	glBindVertexArray(vao_I);

	glGenBuffers(1, &vbo_I_Position);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_I_Position);
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

	const GLfloat fColorIArray[] = {
			SAFFRON,
			SAFFRON,
			GREEN,
			GREEN
	};

	glGenBuffers(1, &vbo_I_Color);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_I_Color);
	glBufferData(GL_ARRAY_BUFFER, sizeof(fColorIArray), fColorIArray, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_COLOR,
		3,									// how many co-ordinates in vertice
		GL_FLOAT,							// type of above data
		GL_FALSE,							// no normalization is desired
		0,									// (dangha)
		NULL								// offset to start in above attrib position
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);

    /*
	// 	fOffX, Yoff, fWidth, fHeight
	// fOffForN, 1.31, fLetterWidth, -1.31
	const GLfloat fN_PositionArray[] = 
    {
        fOffForN + fLetterWidth, 1.31, 0.0f,
        fOffForN, 1.31,  0.0f,
        fOffForN, -1.31, 0.0f,
        fOffForN + fLetterWidth, -1.31, 0.0f,

        fOffForN + 3 * fLetterWidth, -1.31, 0.0f,
        fOffForN + fLetterWidth, 1.31, 0.0f,
        fOffForN, 1.31, 0.0f,
        fOffForN + 2 * fLetterWidth, -1.31, 0.0f,

        fOffForN + 3 * fLetterWidth, 1.31, 0.0f,
        fOffForN + 2 * fLetterWidth, 1.31, 0.0f,
        fOffForN + 2 * fLetterWidth, -1.31, 0.0f,
        fOffForN + 3 * fLetterWidth, -1.31, 0.0f
    };

    const GLfloat fN_ColorArray[] = 
    {
        SAFFRON,
        SAFFRON,

        GREEN,
        GREEN,

        GREEN,
        SAFFRON,

        SAFFRON,
        GREEN,

        SAFFRON,
        SAFFRON,

        GREEN,
        GREEN
    };

    glGenVertexArrays(1, &vao_N);
    glBindVertexArray(vao_N);

    glGenBuffers(1, &vbo_N_Position);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_N_Position);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fN_PositionArray), fN_PositionArray, GL_STATIC_DRAW);
    glVertexAttribPointer(AMC_ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glGenBuffers(1, &vbo_N_Color);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_N_Color);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fN_ColorArray), fN_ColorArray, GL_STATIC_DRAW);
    glVertexAttribPointer(
        AMC_ATTRIBUTE_COLOR,
        3,
        GL_FLOAT,
        GL_FALSE,
        0,
        NULL
    );
    glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0); 

    */

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

    modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);
    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix;

    // uniforms are given to m_uv_matrix (i.e. model view matrix)
    glUniformMatrix4fv(
            mvpUniform,
            1,			//	how many matrices
            GL_FALSE,	//	Transpose is needed ? ->
            modelViewProjectionMatrix
        );

    glBindVertexArray(vao_I);
    glDrawArrays(GL_TRIANGLE_FAN,  0, 4);
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
            [[self window]toggleFullScreen:self];
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
    if(vbo_I2_Color)
    {
        glDeleteBuffers(1, &vbo_I2_Color);
        vbo_I2_Color = 0;
    }

    if(vbo_I2_Position)
    {
        glDeleteBuffers(1, &vbo_I2_Position);
        vbo_I2_Position = 0;
    }

    if (vao_I2)
    {
        glDeleteVertexArrays(1, &vao_I2);
        vao_I2 = 0;
    }

    if(vbo_A_Color)
    {
        glDeleteBuffers(1, &vbo_A_Color);
        vbo_A_Color = 0;
    }

    if(vbo_A_Position)
    {
        glDeleteBuffers(1, &vbo_A_Position);
        vbo_A_Position = 0;
    }

    if (vao_A)
    {
        glDeleteVertexArrays(1, &vao_A);
        vao_A = 0;
    }

    if(vbo_D_Color)
    {
        glDeleteBuffers(1, &vbo_D_Color);
        vbo_D_Color = 0;
    }

    if(vbo_D_Position)
    {
        glDeleteBuffers(1, &vbo_D_Position);
        vbo_D_Position = 0;
    }

    if (vao_D)
    {
        glDeleteVertexArrays(1, &vao_D);
        vao_D = 0;
    }

    if(vbo_N_Color)
    {
        glDeleteBuffers(1, &vbo_N_Color);
        vbo_N_Color = 0;
    }

    if(vbo_N_Position)
    {
        glDeleteBuffers(1, &vbo_N_Position);
        vbo_N_Position = 0;
    }

    if (vao_N)
    {
        glDeleteVertexArrays(1, &vao_N);
        vao_N = 0;
    }

    if(vbo_I_Color)
    {
        glDeleteBuffers(1, &vbo_I_Color);
        vbo_I_Color = 0;
    }

    if(vbo_I_Position)
    {
        glDeleteBuffers(1, &vbo_I_Position);
        vbo_I_Position = 0;
    }

    if (vao_I)
    {
        glDeleteVertexArrays(1, &vao_I);
        vao_I = 0;
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
