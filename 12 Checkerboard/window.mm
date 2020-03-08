
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <QuartzCore/CVDisplayLink.h>

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "vmath.h"

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXTURE0
};

/////////////////////////////////////////////////////
// Global Variables declarations and initializations
/////////////////////////////////////////////////////

GLfloat fanglePyramid = 0.0f;
GLfloat fangleCube = 0.0f;

// 'C' Style global function declaration
CVReturn MyDisplayLinkCallback(
                    CVDisplayLinkRef,
                    const CVTimeStamp *,
                    const CVTimeStamp *,
                    CVOptionFlags,
                    CVOptionFlags *,
                    void *
                );

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

    GLuint vao_rectangle;
    GLuint vbo_position_rectangle;
    GLuint vbo_texture;

    // GLuint g_textSmiley;
    GLuint	g_textImage;

    GLuint mvpUniform;
    GLuint samplerUniform;

    vmath:: mat4 perspectiveProjectionMatrix;

    GLubyte g_checkImage[64][64][4];
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
        "in vec2 vTexture0_coord;" \
        "out vec2 out_texture0_coord;" \
        "uniform mat4 u_mvp_matrix;" \
        "void main(void)" \
        "{" \
            "gl_Position = u_mvp_matrix * vPosition;" \
            "out_texture0_coord = vTexture0_coord;" \
        "}";

    // specify above code of shader to vertext shader object
    glShaderSource(vertexShaderObject, 1,
        (const GLchar**)(&vertexShaderSourceCode), NULL);

    glCompileShader(vertexShaderObject);

    // catching shader related errors if there are any
    GLint iShaderCompileStatus = 0;
    GLint iInfoLogLength = 0;
    GLchar *szInfoLog = NULL;

    // getting compile status code
    glGetShaderiv(vertexShaderObject, GL_COMPILE_STATUS, &iShaderCompileStatus);
    if(GL_FALSE == iShaderCompileStatus)
    {
        glGetShaderiv(vertexShaderObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
        if(iInfoLogLength > 0)
        {
            szInfoLog = (char *)malloc(iInfoLogLength);
            if(NULL != szInfoLog)
            {
                GLsizei written;

                glGetShaderInfoLog(vertexShaderObject, iInfoLogLength, &written, szInfoLog);
                fprintf(gpFile, "VERTEX SHADER FATAL ERROR: %s\n", szInfoLog);
                free(szInfoLog);
                [self release];
                [NSApp terminate:self];
            }
        }
    }

    // ***  Fragment Shader
    // re-initialize
    iShaderCompileStatus = 0;
    iInfoLogLength = 0;
    szInfoLog = NULL;

    fragmentShaderObject = glCreateShader(GL_FRAGMENT_SHADER);
    const GLchar *pcFragmentShaderSourceCode = 
    "#version 410 core" \
    "\n" \
    "in vec2 out_texture0_coord;" \
    "uniform sampler2D u_texture0_sampler;" \
    "out vec4 vFragColor;" \
    "void main(void)" \
    "{" \
        "vFragColor = texture(u_texture0_sampler, out_texture0_coord);" \
    "}";

    // specify above code of shader to vertext shader object
    glShaderSource(fragmentShaderObject, 1, (const GLchar**)&pcFragmentShaderSourceCode,
        NULL);

    glCompileShader(fragmentShaderObject);
    glGetShaderiv(fragmentShaderObject, GL_COMPILE_STATUS, &iShaderCompileStatus);
    if(GL_FALSE == iShaderCompileStatus)
    {
        glGetShaderiv(fragmentShaderObject, GL_INFO_LOG_LENGTH,
            &iInfoLogLength);

        if (iInfoLogLength > 0)
        {
            szInfoLog = (GLchar *)malloc(iInfoLogLength);
            if (NULL != szInfoLog)
            {
                GLsizei written;

                glGetShaderInfoLog(fragmentShaderObject, iInfoLogLength,
                    &written, szInfoLog);
                fprintf(gpFile, ("Fragment Shader Compilation Log: %s\n"), szInfoLog);
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
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_POSITION, "vPosition");
    glBindAttribLocation(shaderProgramObject, AMC_ATTRIBUTE_TEXTURE0, "vTexture0_coord");

    // link the shader
    glLinkProgram(shaderProgramObject);

    GLint iShaderProgramLinkStatus = 0;
    iInfoLogLength = 0;
    
    glGetProgramiv(shaderProgramObject, GL_LINK_STATUS,
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
    mvpUniform = glGetUniformLocation(shaderProgramObject, "u_mvp_matrix");
    samplerUniform = glGetUniformLocation(shaderProgramObject, "u_texture0_sampler");

    // load texture
    // g_textSmiley = [self loadTextureFromBMPFile:"Smiley.bmp"];

    const GLfloat frectangleVertices[] = 
    {
        1.0f, 1.0f, 0.0f,
        -1.0f, 1.0f, 0.0f,
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 0.0f,

        1.0f, -1.0f, 0.0f,
        1.0f, 1.0f, 0.0f,
        2.41421f, 1.0f, -1.41421f,
        2.41421f, -1.0f, -1.41421f
    };

    const GLfloat ftextCooards[] = 
    {
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,

        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f
    };

    glGenVertexArrays(1, &vao_rectangle);
    glBindVertexArray(vao_rectangle);

    glGenBuffers(1, &vbo_position_rectangle);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_position_rectangle);
    glBufferData(GL_ARRAY_BUFFER,
        sizeof(frectangleVertices),
        frectangleVertices,
        GL_STATIC_DRAW);

    glVertexAttribPointer(
        AMC_ATTRIBUTE_POSITION,
        3,                              // how many co-ordinates in vertice
        GL_FLOAT,                       // type of above data
        GL_FALSE,                       // no normalization is desired
        0,                              // (dangha)
        NULL                            // offset to start in above attrib position
    );

    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    //
    // working on colors of rectangle
    //
    glGenBuffers(1, &vbo_texture);
    glBindBuffer(GL_ARRAY_BUFFER,
    	vbo_texture);

    glBufferData(GL_ARRAY_BUFFER,
        sizeof(ftextCooards),
        ftextCooards,
        GL_STATIC_DRAW);

    glVertexAttribPointer(AMC_ATTRIBUTE_TEXTURE0,
        2,
        GL_FLOAT,
        GL_FALSE,
        0,
        NULL);

    glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXTURE0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindVertexArray(0);

    [self loadTexture];

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    glDepthFunc(GL_LEQUAL);
    // glEnable(GL_CULL_FACE);
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

-(void)loadTexture
{
    [self MakeCheckImage];
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glGenTextures(1, &g_textImage);
    glBindTexture(GL_TEXTURE_2D, g_textImage);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glTexImage2D(GL_TEXTURE_2D,  0,
        GL_RGBA, 64, 
        64, 0,
        GL_RGBA, GL_UNSIGNED_BYTE,
        g_checkImage);

}

-(void)MakeCheckImage
{
    int i;
    int j;
    int c;

    for (i = 0; i < 64; i++)
    {
        for (j = 0; j < 64; j++)
        {
            c = (((i & 0x8) == 0) ^ ((j & 0x8) == 0));
            c = c * 255;
            g_checkImage[i][j][0] = (GLbyte)c;
            g_checkImage[i][j][1] = (GLbyte)c;
            g_checkImage[i][j][2] = (GLbyte)c;
            g_checkImage[i][j][3] = (GLbyte)c;
        }
    }
}

// -(GLuint)loadTextureFromBMPFile:(const char*)texFileName
// {
//     NSBundle *mainBundle = [NSBundle mainBundle];
//     NSString *appDirName = [mainBundle bundlePath];
//     NSString *parentDirPath = [appDirName stringByDeletingLastPathComponent];
//     NSString *textureFileNameWithPath = [NSString stringWithFormat:@"%@/%s", parentDirPath, texFileName];
//     NSImage *bmpImage = [[NSImage alloc] initWithContentsOfFile:textureFileNameWithPath];
//     if(!bmpImage)
//     {
//         NSLog(@"can't find %@", textureFileNameWithPath);
//         return(0);
//     }
//     CGImageRef cgImage = [bmpImage CGImageForProposedRect:nil context:nil hints:nil];
//     int w = (int)CGImageGetWidth(cgImage);
//     int h = (int)CGImageGetHeight(cgImage);
//     CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
//     void *pixels = (void *)CFDataGetBytePtr(imageData);
//     GLuint bmpTexture;
//     glGenTextures(1, &bmpTexture);
//     glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//     glBindTexture(GL_TEXTURE_2D, bmpTexture);
//     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
//     glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
//     glGenerateMipmap(GL_TEXTURE_2D);
//     CFRelease(imageData);
//     return(bmpTexture);
// }

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
    vmath::mat4 modelRotationMatrix = vmath::mat4::identity();
    vmath::mat4 modelViewProjectionMatrix = vmath::mat4::identity();

    modelViewMatrix = vmath::translate(0.0f, 0.0f, -4.0f);

    //modelRotationMatrix = vmath::rotate(fangleCube, fangleCube, fangleCube);
    // modelRotationMatrix = modelRotationMatrix * vmath::rotate(fanglePyramid, 0.0f, 1.0f, 0.0f);
    // modelRotationMatrix = modelRotationMatrix * vmath::rotate(fanglePyramid, 0.0f, 1.0f, 0.0f);
    //modelViewMatrix = modelViewMatrix * modelRotationMatrix;

    modelViewProjectionMatrix = perspectiveProjectionMatrix * modelViewMatrix;

    // uniforms are given to m_uv_matrix (i.e. model view matrix)
    glUniformMatrix4fv(
            mvpUniform,
            1,			//	how many matrices
            GL_FALSE,	//	Transpose is needed ? ->
            modelViewProjectionMatrix
        );

    glBindTexture(GL_TEXTURE_2D, g_textImage);
    glUniform1i(samplerUniform, 0);
    glBindVertexArray(vao_rectangle);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 4, 4);
    glBindVertexArray(0);

    glUseProgram(0);

    // fanglePyramid += 0.3f;
    // if (fanglePyramid > 360.0f)
    // {
    //     fanglePyramid = 0.0f;
    // }

    // fangleCube += 0.3f;
    // if (fangleCube > 360.0f)
    // {
    //     fangleCube = 0.0f;
    // }

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
    // if(vbo_pyramid_position)
    // {
    //     glDeleteBuffers(1, &vbo_pyramid_position);
    //     vbo_pyramid_position = 0;
    // }

    // if(vbo_pyramid_texture)
    // {
    //     glDeleteBuffers(1, &vbo_pyramid_texture);
    //     vbo_pyramid_texture = 0;
    // }

    // if (vao_pyramid)
    // {
    //     glDeleteVertexArrays(1, &vao_pyramid);
    //     vao_pyramid = 0;
    // }

    if(vbo_position_rectangle)
    {
        glDeleteBuffers(1, &vbo_position_rectangle);
        vbo_position_rectangle = 0;
    }

    if(vbo_texture)
    {
        glDeleteBuffers(1, &vbo_texture);
        glDeleteTextures(1, &g_textImage);
        g_textImage = 0;
        vbo_texture = 0;
    }


    if (vao_rectangle)
    {
        glDeleteVertexArrays(1, &vao_rectangle);
        vao_rectangle = 0;
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
