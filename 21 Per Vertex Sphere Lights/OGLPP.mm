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

    GLuint vao_sphere;
    GLuint vbo_sphere_position;
    GLuint vbo_sphere_elements;
    GLuint vbo_sphere_normals;

    GLuint uiModelMatrixUniform;
    GLuint uiViewMatrixUniform;
    GLuint uiProjectionUniform;

    vmath:: mat4 perspectiveProjectionMatrix;
    float fAngleRotate;

    GLuint laUniform;
    GLuint ldUniform;
    GLuint lsUniform;
    GLuint lightPositionVectorUniform;

    GLuint kaUniform;
    GLuint kdUniform;
    GLuint ksUniform;
    GLuint shineynessUniform;

    float   *fSpherePositions;
    float   *fSphereNormals;
    float   *fSphereTexturesCoords;
    int     *indices;
    int gNumElements;

    bool boKeyOfLightsIsPressed;

    float light_ambient[4] =  { 0.0f, 0.0f, 0.0f, 0.0f };
    float light_diffused[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    float light_specular[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    float light_position[4] = { 100.0f, 100.0f, 100.0f, 1.0f };

    float material_ambient[4] =  { 0.0f, 0.0f, 0.0f, 0.0f };
    float material_diffused[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    float material_specular[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    float material_shineyness = 120.0f;
}

-(id)initWithFrame:(NSRect)frame;
{
    // code
    boKeyOfLightsIsPressed = false;

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
        "in vec4 v_position;" \
        "in vec3 v_normals;" \

        "uniform int ui_is_lighting_key_pressed;" \

        "uniform mat4 u_model_matrix;" \
        "uniform mat4 u_view_matrix;" \
        "uniform mat4 u_projection_matrix;" \

        "uniform vec3 u_la;" \
        "uniform vec3 u_ld;" \
        "uniform vec3 u_ls;" \
        "uniform vec4 u_light_position;" \

        "uniform vec3 u_ka;" \
        "uniform vec3 u_kd;" \
        "uniform vec3 u_ks;" \
        "uniform float u_material_shiney_ness;" \

        "out vec3 phong_ads_light;" \
        "void main(void)" \
        "{" \
        "vec3 t_norm; " \
        "vec3 ambient;" \
        "vec3 diffused;" \
        "vec3 specular;" \
        "float tn_dot_ld;" \
        "vec3 viewer_vector;" \
        "vec4 eye_coordinates;" \
        "vec3 light_direction;" \
        "vec3 reflection_vector;" \

        "if(ui_is_lighting_key_pressed == 1){" \
            "eye_coordinates = u_view_matrix * u_model_matrix * v_position;" \
            "mat3 normal_matrix = mat3(transpose(inverse(u_view_matrix * u_model_matrix)));" \
            "t_norm = normalize(normal_matrix * v_normals);" \
            "light_direction = normalize(vec3(u_light_position - eye_coordinates));" \
            "tn_dot_ld = max(dot(light_direction, t_norm), 0.0);" \
            "reflection_vector = reflect(-light_direction, t_norm);" \
            "viewer_vector = normalize(vec3(-eye_coordinates));" \
            "ambient = u_la * u_ka;" \
            "diffused = u_ld * u_kd * tn_dot_ld;" \
            "specular = u_ls * u_ks * " \
                    "pow(max(dot(reflection_vector, viewer_vector), 0.0), u_material_shiney_ness);" \

            "phong_ads_light = ambient + diffused + specular;" \
        "}" \
        "else{" \
        	"phong_ads_light = vec3(1.0, 1.0, 1.0);" \
        "}" \

        "gl_Position = u_projection_matrix * u_view_matrix * u_model_matrix * v_position;" \
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

    "in vec3 phong_ads_light;" \
    "out vec4 v_frag_color;" \

    "void main(void)" \
    "{" \
        "v_frag_color = vec4(phong_ads_light, 1.0);" \
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

    // here we binded gpu`s variable to cpu`s index
    glBindAttribLocation(shaderProgramObject,
        AMC_ATTRIBUTE_POSITION,
        "vPosition");

    glBindAttribLocation(shaderProgramObject,
        AMC_ATTRIBUTE_NORMAL,
        "v_normals");

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

    uiModelMatrixUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_model_matrix"
    );

    uiViewMatrixUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_view_matrix"
    );

    uiProjectionUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_projection_matrix"
    );

    laUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_la"
    );

    ldUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_ld"
    );

    lsUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_ls"
    );

    lightPositionVectorUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_light_position"
    );

    kaUniform = glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_ka"
    );

    kdUniform = 
        glGetUniformLocation(
            g_uiShaderProgramObject,
            "u_kd"
        );

    ksUniform = 
        glGetUniformLocation(
            g_uiShaderProgramObject,
            "u_ks"
        );

    shineynessUniform = 
        glGetUniformLocation(
        g_uiShaderProgramObject,
        "u_material_shiney_ness"
    );

    uiKeyOfLightsIsPressed =
        glGetUniformLocation(
            g_uiShaderProgramObject,
            "ui_is_lighting_key_pressed"
        );

    int slices = 50;
    int stacks = 50;
    [self mySphereWithRadius:1.0 slices:slices stacks:stacks];
    //mySphereWithRadius(0.6f, slices, stacks);
    int vertexCount = (slices + 1) * (stacks + 1);

    glGenVertexArrays(1, &vao_sphere);
    glBindVertexArray(vao_sphere);

    glGenBuffers(1, &vbo_sphere_position);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_sphere_position);
    glBufferData(
                    GL_ARRAY_BUFFER,
                    3 * vertexCount * sizeof(float),
                    fSpherePositions,
                    GL_STATIC_DRAW
                );

    glVertexAttribPointer(
            AMC_ATTRIBUTE_POSITION,
            3,		
            GL_FLOAT,
            GL_FALSE,
            0,		
            NULL	
        );

    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glGenBuffers(1, &vbo_sphere_elements);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_sphere_elements);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, gNumElements * sizeof(int), indices, GL_STATIC_DRAW);

    // normals
    glGenBuffers(1, &vbo_sphere_normals);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_sphere_normals);
    glBufferData(GL_ARRAY_BUFFER,
         3 * vertexCount * sizeof(float),
        fSphereNormals,
        GL_STATIC_DRAW);

    glVertexAttribPointer(
        AMC_ATTRIBUTE_NORMAL,
        3,
        GL_FLOAT,
        GL_FALSE,
        0, 
        NULL
    );

    glEnableVertexAttribArray(AMC_ATTRIBUTE_NORMAL);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindVertexArray(0);

    //
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

-(void)mySphereWithRadius:(float)radius slices:(int)slices stacks:(int)stacks
{
    int vertexCount = (slices + 1)*(stacks + 1);
    gNumElements = 2 * slices*stacks * 3;

    fSpherePositions = (float *)malloc(3 * vertexCount * sizeof(float));
    fSphereNormals = (float *)malloc(3 * vertexCount * sizeof(float));
    fSphereTexturesCoords = (float *)malloc(2 * vertexCount * sizeof(float));
    indices = (int *)malloc(gNumElements * sizeof(int));

    float du = 2 * M_PI / slices;
    float dv = M_PI / stacks;

    int indexV = 0;
    int indexT = 0;

    float u, v, x, y, z;
    int i, j, k;
    for (i = 0; i <= stacks; i++)
    {
        v = -M_PI / 2 + i * dv;
        for (j = 0; j <= slices; j++)
        {
            u = j * du;
            x = cos(u) * cos(v);
            y = sin(u) * cos(v);
            z = sin(v);
            fSpherePositions[indexV] = radius * x;
            fSphereNormals[indexV++] = x;
            fSpherePositions[indexV] = radius * y;
            fSphereNormals[indexV++] = y;
            fSpherePositions[indexV] = radius * z;
            fSphereNormals[indexV++] = z;
            fSphereTexturesCoords[indexT++] = j / slices;
            fSphereTexturesCoords[indexT++] = i / stacks;
        }
    }

    k = 0;
    for (j = 0; j < stacks; j++)
    {
        int row1 = j * (slices + 1);
        int row2 = (j + 1)*(slices + 1);
        for (i = 0; i < slices; i++)
        {
            indices[k++] = row1 + i;
            indices[k++] = row2 + i + 1;
            indices[k++] = row2 + i;
            indices[k++] = row1 + i;
            indices[k++] = row1 + i + 1;
            indices[k++] = row2 + i + 1;
        }
    }

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

    vmath::mat4 modelMatrix = vmath::mat4::identity();
    vmath::mat4 viewMatrix = vmath::mat4::identity();
    vmath::mat4 rotateMatrix = vmath::mat4::identity();
    vmath::mat4 modelViewProjectionMatrix = vmath::mat4::identity();

    modelMatrix = vmath::translate(0.0f, 0.0f, -5.0f);
    // rotateMatrix = vmath::rotate(90.0f, 1.0f, 0.0f, 0.0f);
    // rotateMatrix = rotateMatrix * vmath::rotate(fAngleRotate, 1.0f, 0.0f, 0.0f);
    // modelViewMatrix = modelViewMatrix * rotateMatrix;

    glUniformMatrix4fv(uiModelMatrixUniform,
            1,
            GL_FALSE,
            modelMatrix
        );
    
    glUniformMatrix4fv(uiViewMatrixUniform,
        1,
        GL_FALSE,
        viewMatrix);
    
    glUniformMatrix4fv(uiProjectionUniform,
        1,
        GL_FALSE,
        perspectiveProjectionMatrix);
    
    if (TRUE == boKeyOfLightsIsPressed)
    {
        glUniform1i(uiKeyOfLightsIsPressed, 1);
        glUniform4f(lightPositionVectorUniform, 100.0f, 100.0f, 100.0f, 1.0f);
    
        glUniform3fv(laUniform, 1, light_ambient);
        glUniform3fv(lsUniform, 1, light_specular);
        glUniform3fv(ldUniform, 1, light_diffused);
    
        glUniform3fv(kaUniform, 1, material_ambient);
        glUniform3fv(kdUniform, 1, material_diffused);
        glUniform3fv(ksUniform, 1, material_specular);
        glUniform1f(shineynessUniform, material_shineyness);
    }
    else
    {
        glUniform1i(uiKeyOfLightsIsPressed, 0);
    }

    glBindVertexArray(vao_sphere);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_sphere_elements);
    glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_INT, 0);
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
        
        case 'l':
        case 'L':
            if (true == boKeyOfLightsIsPressed)
            {
                boKeyOfLightsIsPressed = false;
            }
            else
            {
                boKeyOfLightsIsPressed = true;
            }

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

    free(fSpherePositions);
    fSpherePositions = NULL;
    free(fSphereNormals);
    fSphereNormals = NULL;
    free(fSphereTexturesCoords);
    fSphereTexturesCoords = NULL;
    free(indices);
    indices = NULL;

    if(vbo_sphere_position)
    {
        glDeleteBuffers(1, &vbo_sphere_position);
        vbo_sphere_position = 0;
    }

    if(vbo_sphere_elements)
    {
        glDeleteBuffers(1, &vbo_sphere_elements);
        vbo_sphere_elements = 0;
    }

    if(vbo_sphere_normals)
    {
        glDeleteBuffers(1, &vbo_sphere_normals);
        vbo_sphere_normals = 0;
    }

    if (vao_sphere)
    {
        glDeleteVertexArrays(1, &vao_sphere);
        vao_sphere = 0;
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
