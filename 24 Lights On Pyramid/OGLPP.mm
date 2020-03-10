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

float fAngleRotate = 0.0f;

/////////////////////////////////////////////////////////////////////
//	I N T E R F A C E  D E C L A R A T I O N S
/////////////////////////////////////////////////////////////////////

// interface declarations
@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@end

@interface GlView : NSOpenGLView
@end

// float light_ambient[4] =  { 0.0f, 0.0f, 0.0f, 0.0f };
// float light_diffused[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
// float light_specular[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
// float light_position[4] = { 100.0f, 100.0f, 100.0f, 1.0f};

// float material_ambient[4] =  { 0.0f, 0.0f, 0.0f, 0.0f };
// float material_diffused[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
// float material_specular[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
// float material_shineyness = 120.0f;


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

    GLuint vao_pyramid_sj;
    GLuint vbo_position_pyr_sj;
    GLuint vbo_normals_pyramid_sj;

    GLuint uiModelViewUniform_sj;
    // GLuint uiViewMatrixUniform;
    GLuint uiProjectionUniform;

    vmath:: mat4 perspectiveProjectionMatrix;

    GLuint laUniform_left_sj;
    GLuint ldUniform_left_sj;
    GLuint lsUniform_left_sj;
    GLuint lightPositionVectorUniform_sj_left_sj;

    GLuint laUniform_right_sj;
    GLuint ldUniform_right_sj;
    GLuint lsUniform_right_sj;
    GLuint lightPositionVectorUniform_sj_right_sj;

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
    GLuint uiKeyOfLightsIsPressed;

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

        "uniform mat4 u_model_view_mat;" \
        "uniform mat4 u_model_projection_mat;" \

        "uniform int ui_is_lighting_key_pressed;" \

        "uniform vec3 u_la_left;" \
        "uniform vec3 u_ld_left;" \
        "uniform vec3 u_ls_left;" \
        "uniform vec4 u_light_position_left;" \

        "uniform vec3 u_la_right;" \
        "uniform vec3 u_ld_right;" \
        "uniform vec3 u_ls_right;" \
        "uniform vec4 u_light_position_right;" \

        "uniform vec3 u_ka;" \
        "uniform vec3 u_kd;" \
        "uniform vec3 u_ks;" \
        "uniform float u_material_shiney_ness;" \

        "out vec3 phong_ads_light;" \

        "void main(void)" \
        "{" \

            "vec3 ambient;" \
            "vec3 diffused;" \
            "vec3 specular;" \
            "vec3 t_norm; " \
            "vec3 viewer_vector;" \
            "vec4 eye_coordinates;" \

            "float tn_dot_ld_right;" \
            "vec3 light_direction_right;" \
            "vec3 reflection_vector_right;" \

            "float tn_dot_ld_left;" \
            "vec3 light_direction_left;" \
            "vec3 reflection_vector_left;" \

            "if(ui_is_lighting_key_pressed == 1){" \
                "eye_coordinates = u_model_view_mat * v_position;" \
                "mat3 normal_matrix = mat3(transpose(inverse(u_model_view_mat)));" \
                "t_norm = normalize(normal_matrix * v_normals);" \
                "viewer_vector = normalize(vec3(-eye_coordinates));" \

                "light_direction_right = normalize(vec3(u_light_position_right - eye_coordinates));" \
                "tn_dot_ld_right = max(dot(light_direction_right, t_norm), 0.0);" \
                "reflection_vector_right = reflect(-light_direction_right, t_norm);" \

                "light_direction_left = normalize(vec3(u_light_position_left - eye_coordinates));" \
                "tn_dot_ld_left = max(dot(light_direction_left, t_norm), 0.0);" \
                "reflection_vector_left = reflect(-light_direction_left, t_norm);" \

                "ambient = u_la_right * u_ka;" \
                "diffused = u_ld_right * u_kd * tn_dot_ld_right;" \
                "specular = u_ls_right * u_ks * " \
                "pow(max(dot(reflection_vector_right, viewer_vector), 0.0), u_material_shiney_ness);" \

                "phong_ads_light = ambient + diffused + specular;" \

                "ambient = u_la_left * u_ka;" \
                "diffused = u_ld_left * u_kd * tn_dot_ld_left;" \
                "specular = u_ls_left * u_ks * " \
                "pow(max(dot(reflection_vector_left, viewer_vector), 0.0), u_material_shiney_ness);" \

                "phong_ads_light = phong_ads_light + ambient + diffused + specular;" \
            "}" \
            "else{" \
            	"phong_ads_light = vec3(1.0, 1.0, 1.0);" \
            "}"

            "gl_Position = u_model_projection_mat * u_model_view_mat * v_position;" \

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

    uiModelViewUniform_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_model_view_mat"
    );

    // uiViewMatrixUniform = glGetUniformLocation(
    //     shaderProgramObject,
    //     "u_view_matrix"
    // );

    uiProjectionUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_model_projection_mat"
    );

    uiKeyOfLightsIsPressed = glGetUniformLocation(
            shaderProgramObject,
            "ui_is_lighting_key_pressed"
        );

    laUniform_left_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_la_left"
    );

    ldUniform_left_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_ld_left"
    );

    lsUniform_left_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_ls_left"
    );

    lightPositionVectorUniform_sj_left_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_light_position_left"
    );

    lightPositionVectorUniform_sj_right_sj = glGetUniformLocation(shaderProgramObject, "u_light_position_right");
    laUniform_right_sj = glGetUniformLocation(shaderProgramObject, "u_la_right");
    ldUniform_right_sj = glGetUniformLocation(shaderProgramObject, "u_ld_right");
    lsUniform_right_sj = glGetUniformLocation(shaderProgramObject, "u_ls_right");


    kaUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_ka"
    );

    kdUniform = 
        glGetUniformLocation(
            shaderProgramObject,
            "u_kd"
        );

    ksUniform = 
        glGetUniformLocation(
            shaderProgramObject,
            "u_ks"
        );

    shineynessUniform = 
        glGetUniformLocation(
        shaderProgramObject,
        "u_material_shiney_ness"
    );

    // int slices = 50;
    // int stacks = 50;
    // [self mySphereWithRadius:1.0 slices:slices stacks:stacks];

    // int vertexCount = (slices + 1) * (stacks + 1);

    // RECTANGLE
    const GLfloat fCubePositions[] =
                    {
                        0.0f, 1.0f, 0.0f, 	-1.0f, -1.0f, 1.0f, 	1.0f, -1.0f, 1.0f,
                        0.0f, 1.0f, 0.0f, 	1.0f, -1.0f, 1.0f,	1.0f, -1.0f, -1.0f,
                        0.0f, 1.0f, 0.0f, 	1.0f, -1.0f, -1.0f,  -1.0f, -1.0f, -1.0f,
                        0.0f, 1.0f, 0.0f, -1.0f, -1.0f, -1.0f, 	-1.0f, -1.0f, 1.0f
                    };

    const GLfloat fCubeNormals[] =
    {
                0.0f, 0.447214f, 0.894427f,
                0.0f, 0.447214f, 0.894427f,
                0.0f, 0.447214f, 0.894427f,

                0.894427f, 0.447214f, 0.0f,
                0.894427f, 0.447214f, 0.0f,
                0.894427f, 0.447214f, 0.0f,

                0.0f, 0.447214f, -0.894427f,
                0.0f, 0.447214f, -0.894427f,
                0.0f, 0.447214f, -0.894427f,

                -0.894427f, 0.447214f, 0.0f,
                -0.894427f, 0.447214f, 0.0f,
                -0.894427f, 0.447214f, 0.0f
    };

    glGenVertexArrays(1, &vao_pyramid_sj);
    glBindVertexArray(vao_pyramid_sj);

    glGenBuffers(1, &vbo_position_pyr_sj);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_position_pyr_sj);
    glBufferData(
                    GL_ARRAY_BUFFER,
                    sizeof(fCubePositions),
                    fCubePositions,
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

    // glGenBuffers(1, &vbo_sphere_elements);
    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_sphere_elements);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, gNumElements * sizeof(int), indices, GL_STATIC_DRAW);

    // normals
    glGenBuffers(1, &vbo_normals_pyramid_sj);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_normals_pyramid_sj);
    glBufferData(GL_ARRAY_BUFFER,
         sizeof(fCubeNormals),
         fCubeNormals,
         GL_STATIC_DRAW
        );

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

    vmath::mat4 modelViewMatrix = vmath::mat4::identity();
    // vmath::mat4 viewMatrix = vmath::mat4::identity();
    vmath::mat4 rotateMatrix = vmath::mat4::identity();
    vmath::mat4 modelViewProjectionMatrix = vmath::mat4::identity();

    modelViewMatrix = vmath::translate(0.0f, 0.0f, -5.0f);
    rotateMatrix = vmath::rotate(fAngleRotate, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = modelViewMatrix * rotateMatrix;

    glUniformMatrix4fv(uiModelViewUniform_sj,
            1,
            GL_FALSE,
            modelViewMatrix
        );
    
    glUniformMatrix4fv(uiProjectionUniform,
        1,
        GL_FALSE,
        perspectiveProjectionMatrix);
    
    if (true == boKeyOfLightsIsPressed)
    {
        glUniform1i(uiKeyOfLightsIsPressed, 1);

        glUniform4f(lightPositionVectorUniform_sj_left_sj, -2.0f, 0.0f, 0.0f, 1.0f);
        glUniform3f(laUniform_left_sj, 0.0f, 0.0f, 0.0f);
        glUniform3f(lsUniform_left_sj, 1.0f, 0.0f, 0.0f);
        glUniform3f(ldUniform_left_sj, 1.0f, 0.0f, 0.0f);

        glUniform4f(lightPositionVectorUniform_sj_right_sj, 2.0f, 0.0f, 0.0f, 1.0f);
        glUniform3f(laUniform_right_sj, 0.0f, 0.0f, 0.0f);
        glUniform3f(lsUniform_right_sj, 0.0f, 0.0f, 1.0f);
        glUniform3f(ldUniform_right_sj, 0.0f, 0.0f, 1.0f);

        glUniform3f(kaUniform, 0.0f, 0.0f, 0.0f);
        glUniform3f(kdUniform, 1.0f, 1.0f, 1.0f);
        glUniform3f(ksUniform, 1.0f, 1.0f, 1.0f);
        glUniform1f(shineynessUniform, 100.0f);
    }
    else
    {
        glUniform1i(uiKeyOfLightsIsPressed, 0);
    }

    glBindVertexArray(vao_pyramid_sj);
    glDrawArrays(GL_TRIANGLES, 0, 12);
    glBindVertexArray(0);

    glUseProgram(0);
    CGLFlushDrawable((CGLContextObj)[[self openGLContext]CGLContextObj]);
    CGLUnlockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);

    fAngleRotate += 0.1f;
    if (fAngleRotate > 360.0f)
    {
        fAngleRotate = 0.0f;
    }
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
    if(vbo_position_pyr_sj)
    {
        glDeleteBuffers(1, &vbo_position_pyr_sj);
        vbo_position_pyr_sj = 0;
    }

    // if(vbo_sphere_elements)
    // {
    //     glDeleteBuffers(1, &vbo_sphere_elements);
    //     vbo_sphere_elements = 0;
    // }

    if(vbo_normals_pyramid_sj)
    {
        glDeleteBuffers(1, &vbo_normals_pyramid_sj);
        vbo_normals_pyramid_sj = 0;
    }

    if (vao_pyramid_sj)
    {
        glDeleteVertexArrays(1, &vao_pyramid_sj);
        vao_pyramid_sj = 0;
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
