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

float light_ambient[4] =  { 0.0f, 0.0f, 0.0f, 0.0f };
float light_diffused[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
float light_specular[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
float light_position[4] = { 100.0f, 100.0f, 100.0f, 1.0f};

//
// Gems Material
//
float material_ambient_emerald[4] = { 0.0215f, 0.1745f, 0.0215f, 1.0f };
float material_diffused_emerald[4] = { 0.07568f, 0.61424f, 0.07568f, 1.0f };
float material_specular_emerald[4] = { 0.633f, 0.727811f, 0.633f, 1.0f};
float material_shineyness_emerald = 0.6f * 128;

float material_ambient_jade[4] = { 0.135f, 0.2225f, 0.1575f, 1.0f };
float material_diffused_jade[4] = { 0.54f, 0.89f, 0.63f, 1.0f };
float material_specular_jade[4] = { 0.316228f, 0.316228f, 0.316228f, 1.0f };
float material_shineyness_jade = 0.1f * 128;

float material_ambient_obsidian[4] = { 0.05375f, 0.05f, 0.06625f, 1.0f };
float material_diffused_obsidian[4] = { 0.18275f, 0.17f, 0.22525f, 1.0f };
float material_specular_obsidian[4] = { 0.332741f, 0.328634f, 0.346435f, 1.0f };
float material_shineyness_obsidian = 0.3f * 128;

float material_ambient_pearl[4] = { 0.25f, 0.20725f, 0.20725f, 1.0f };
float material_diffused_pearl[4] = { 1.0f, 0.829f, 0.829f, 1.0f };
float material_specular_pearl[4] = { 0.296648f, 0.296648f, 0.296648f, 1.0f };
float material_shineyness_pearl = 0.088f * 128;

float material_ambient_ruby[4] = { 0.1745f, 0.01175f, 0.01175f, 1.0f };
float material_diffused_ruby[4] = { 0.61424f, 0.04136f, 0.04136f, 1.0f };
float material_specular_ruby[4] = { 0.727811f, 0.626959f,0.626959f, 1.0f };
float material_shineyness_ruby = 0.6f * 128;

float material_ambient_turquoise[4] = { 0.1f, 0.18725f, 0.1745f, 1.0f };
float material_diffused_turquoise[4] = { 0.396f, 0.74151f, 0.69102f, 1.0f };
float material_specular_turquoise[4] = { 0.297254f, 0.30829f, 0.306678f, 1.0f };
float material_shineyness_turquoise = 0.1f * 128;

//
// Metals
//
float material_ambient_brass[4] = { 0.32412f, 0.223529f, 0.027451f, 1.0f };
float material_diffused_brass[4] = { 0.780392f, 0.568627f, 0.113725f, 1.0f };
float material_specular_brass[4] = { 0.992157f, 0.941176f, 0.807843f, 1.0f };
float material_shineyness_brass = 0.21794872f * 128;

float material_ambient_bronze[4] = { 0.2125f, 0.1275f, 0.054f, 1.0f };
float material_diffused_bronze[4] = { 0.714f, 0.4284f, 0.18144f, 1.0f };
float material_specular_bronze[4] = { 0.393548f, 0.271906f, 0.166721f, 1.0f };
float material_shineyness_bronze = 0.2f * 128;

float material_ambient_chrome[4] = { 0.25f, 0.25f, 0.25f, 1.0f };
float material_diffused_chrome[4] = { 0.4f, 0.4f, 0.4f, 1.0f };
float material_specular_chrome[4] = { 0.774597f, 0.774597f, 0.774597f, 1.0f };
float material_shineyness_chrome = 0.6f * 128;

float material_ambient_copper[4] = { 0.19125f, 0.0735f, 0.0225f, 1.0f };
float material_diffused_copper[4] = { 0.7038f, 0.27048f, 0.0828f, 1.0f };
float material_specular_copper[4] = { 0.256777f, 0.137622f, 0.086014f, 1.0f };
float material_shineyness_copper = 0.1f * 128;

float material_ambient_gold[4] = { 0.24725f, 0.1995f, 0.0745f, 1.0f };
float material_diffused_gold[4] = { 0.75164f, 0.60648f, 0.22648f, 1.0f };
float material_specular_gold[4] = { 0.628281f, 0.555802f, 0.366065f, 1.0f };
float material_shineyness_gold = 0.4f * 128;

float material_ambient_silver[4] = { 0.19225f, 0.19225f, 0.19225f, 1.0f };
float material_diffused_silver[4] = { 0.50754f, 0.50754f, 0.50754f, 1.0f };
float material_specular_silver[4] = { 0.508273f, 0.508273f, 0.508273f, 1.0f };
float material_shineyness_silver = 0.4f * 128;

//	Plastic

float material_ambient_black[4] = { 0.0f,  0.19225f, 0.19225f, 1.0f };
float material_diffused_black[4] = { 0.01f, 0.01f, 0.01f, 1.0f };
float material_specular_black[4] = { 0.5f, 0.5f, 0.5f, 1.0f };
float material_shineyness_black= 0.25f * 128;

float material_ambient_cyan[4] = { 0.0f,  0.1f, 0.06f, 1.0f };
float material_diffused_cyan[4] = { 0.0f, 0.50980392f, 0.50980392f, 1.0f };
float material_specular_cyan[4] = { 0.50196078f, 0.50196078f, 0.50196078f, 1.0f };
float material_shineyness_cyan = 0.25f * 128;

float material_ambient_green[4] = { 0.0f,  0.0f, 0.0f, 1.0f };
float material_diffused_green[4] = { 0.1f, 0.35f, 0.1f, 1.0f };
float material_specular_green[4] = { 0.45f, 0.55f, 0.45f, 1.0f };
float material_shineyness_green = 0.25f * 128;

float material_ambient_red[4] = { 0.0f,  0.0f, 0.0f, 1.0f };
float material_diffused_red[4] = { 0.5f, 0.0f, 0.0f, 1.0f };
float material_specular_red[4] = { 0.7f, 0.6f, 0.6f, 1.0f };
float material_shineyness_red= 0.25f * 128;

float material_ambient_white[4] = { 0.0f,  0.0f, 0.0f, 1.0f };
float material_diffused_white[4] = { 0.55f, 0.55f, 0.55f, 1.0f };
float material_specular_white[4] = { 0.70f, 0.70f, 0.70f, 1.0f };
float material_shineyness_white = 0.25f * 128;

float material_ambient_yellow[4] = { 0.0f,  0.0f, 0.0f, 1.0f };
float material_diffused_yellow[4] = { 0.5f, 0.5f, 0.0f, 1.0f };
float material_specular_yellow[4] = { 0.60f, 0.60f, 0.5f, 1.0f };
float material_shineyness_yellow = 0.25f * 128;

// rubber
float material_ambient_rubber_black[4] = { 0.02f, 0.02f, 0.02f, 1.0f };
float material_diffused_rubber_black[4] = { 0.01, 0.01, 0.01, 1.0f };
float material_specular_rubber_black[4] = { 0.4f, 0.4f, 0.4f, 1.0f };
float material_shineyness_rubber_black = 0.078125f * 128;

float material_ambient_rubber_cyan[4]  = { 0.0f, 0.05f, 0.05f, 1.0f };
float material_diffused_rubber_cyan[4] = { 0.4f, 0.5f, 0.5f, 1.0f };
float material_specular_rubber_cyan[4] = { 0.04f, 0.7f, 0.7f, 1.0f };
float material_shineyness_rubber_cyan  = 0.078125f * 128;

float material_ambient_rubber_green[4]  = { 0.0f, 0.05f, 0.0f, 1.0f };
float material_diffused_rubber_green[4] = { 0.4f, 0.5f, 0.4f, 1.0f };
float material_specular_rubber_green[4] = { 0.04f, 0.7f, 0.04f, 1.0f };
float material_shineyness_rubber_green = 0.078125f * 128;

float material_ambient_rubber_red[4] = { 0.05f, 0.0f, 0.0f, 1.0f };
float material_diffused_rubber_red[4] = { 0.5f, 0.4f, 0.4f, 1.0f };
float material_specular_rubber_red[4] = { 0.7f, 0.04f, 0.04f, 1.0f };
float material_shineyness_rubber_red = 0.078125f * 128;

float material_ambient_rubber_white[4] = { 0.05f, 0.05f, 0.0f, 1.0f };
float material_diffused_rubber_white[4] = { 0.5f, 0.5f, 0.5f, 1.0f };
float material_specular_rubber_white[4] = { 0.7f, 0.7f, 0.7f, 1.0f };
float material_shineyness_rubber_white = 0.078125f * 128;

float material_ambient_rubber_yellow[4] = { 0.05f, 0.05f, 0.0f, 1.0f };
float material_diffused_rubber_yellow[4] = { 0.5f, 0.5f, 0.4f, 1.0f };
float material_specular_rubber_yellow[4] = { 0.7f, 0.7f, 0.04f, 1.0f };
float material_shineyness_rubber_yellow = 0.078125f * 128;

int g_X_Y_Z = 0;
int ind = 0;

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

    GLfloat     width;
    GLfloat     height;

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
    GLuint lightPositionVectorUniform_sj;

    GLuint kaUniform_sj;
    GLuint kdUniform_sj;
    GLuint ksUniform_sj;
    GLuint shineynessUniform_sj;

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

        "uniform mat4 u_view_matrix;" \
        "uniform mat4 u_model_matrix;" \
        "uniform vec4 u_light_position;" \
        "uniform mat4 u_projection_matrix;" \
        "uniform int ui_is_lighting_key_pressed;" \

        "out vec3 t_norm;" \
        "out vec3 viewer_vector;" \
        "out vec3 light_direction;" \

        "void main(void)" \
        "{" \
            "vec4 eye_coordinates;" \

            "if(ui_is_lighting_key_pressed == 1){" \
                "eye_coordinates = u_view_matrix * u_model_matrix * v_position;" \
                "t_norm = mat3(u_view_matrix * u_model_matrix) * v_normals;" \
                "light_direction = vec3(u_light_position - eye_coordinates);" \
                "viewer_vector = vec3(-eye_coordinates);" \
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

    "in vec3 t_norm;" \
    "in vec3 light_direction;" \
    "in vec3 phong_ads_light;" \

    "in vec3 viewer_vector;" \
    "out vec4 v_frag_color;" \

    "uniform vec3 u_la;" \
    "uniform vec3 u_ld;" \
    "uniform vec3 u_ls;" \
    "uniform vec3 u_ka;" \
    "uniform vec3 u_kd;" \
    "uniform vec3 u_ks;" \
    "uniform float u_material_shiney_ness;" \
    "uniform int ui_is_lighting_key_pressed;" \

    "void main(void)" \
    "{" \
        "vec3 l_t_norm;" \
        "float tn_dot_ld;" \
        "vec3 l_light_direction;" \
        "vec3 l_viewer_vector;" \
        "vec3 reflection_vector;" \
        "vec3 ambient;" \
        "vec3 diffused;" \
        "vec3 specular;" \
        "vec3 phong_ads_light;" \

        "if(ui_is_lighting_key_pressed == 1){" \

            "l_t_norm = normalize(t_norm);" \
            "l_light_direction	= normalize(light_direction);" \
            "l_viewer_vector = normalize(viewer_vector);" \
            "reflection_vector = reflect(-l_light_direction, l_t_norm);" \
            "tn_dot_ld = max(dot(l_light_direction, l_t_norm), 0.0);" \
            "ambient = u_la * u_ka;" \
            "diffused = u_ld * u_kd * tn_dot_ld;" \

            "specular = u_ls * u_ks * " \
                "pow(max(dot(reflection_vector," \
                "l_viewer_vector), 0.0), u_material_shiney_ness);" \

            "phong_ads_light = ambient + diffused + specular;" \
            "v_frag_color = vec4(phong_ads_light, 1.0);" \
        "}" \
        "else{" \
            "v_frag_color = vec4(1.0, 1.0, 1.0, 1.0);" \
        "}" \
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
        shaderProgramObject,
        "u_model_matrix"
    );

    uiViewMatrixUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_view_matrix"
    );

    uiProjectionUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_projection_matrix"
    );

    laUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_la"
    );

    ldUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_ld"
    );

    lsUniform = glGetUniformLocation(
        shaderProgramObject,
        "u_ls"
    );

    lightPositionVectorUniform_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_light_position"
    );

    kaUniform_sj = glGetUniformLocation(
        shaderProgramObject,
        "u_ka"
    );

    kdUniform_sj = 
        glGetUniformLocation(
            shaderProgramObject,
            "u_kd"
        );

    ksUniform_sj = 
        glGetUniformLocation(
            shaderProgramObject,
            "u_ks"
        );

    shineynessUniform_sj = 
        glGetUniformLocation(
        shaderProgramObject,
        "u_material_shiney_ness"
    );

    uiKeyOfLightsIsPressed =
        glGetUniformLocation(
            shaderProgramObject,
            "ui_is_lighting_key_pressed"
        );

    int slices = 50;
    int stacks = 50;
    [self mySphereWithRadius:1.0 slices:slices stacks:stacks];

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

    width  = rect.size.width;
    height = rect.size.height;

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

    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    glEnable(GL_POLYGON_OFFSET_FILL);
    glPolygonOffset(1.0f, 2.5f);

    float angle;
    float fCirclePositions[3];
    angle = 2.0f * M_PI * ind / 1000;

    fCirclePositions[0] = cos(angle) * 30.0f;
    fCirclePositions[1] = sin(angle) * 30.0f;
    fCirclePositions[2] = -4.0f;

    glUseProgram(shaderProgramObject);

    vmath::mat4 modelMatrix = vmath::mat4::identity();
    vmath::mat4 viewMatrix = vmath::mat4::identity();
    vmath::mat4 modelRotationMatrix = vmath::mat4::identity();
    vmath::mat4 modelViewProjectionMatrix = vmath::mat4::identity();

    if (true == boKeyOfLightsIsPressed)
    {
        glUniform1i(uiKeyOfLightsIsPressed, 1);
        if (0 == g_X_Y_Z)
        {
        	glUniform4f(lightPositionVectorUniform_sj, 100.0f, 100.0f, 100.0f, 1.0f);
        }
        else if (3 == g_X_Y_Z)
        {
        	glUniform4f(lightPositionVectorUniform_sj, fCirclePositions[0], fCirclePositions[1], fCirclePositions[2], 1.0f);
        }
        else if (2 == g_X_Y_Z)
        {
        	glUniform4f(lightPositionVectorUniform_sj, fCirclePositions[0], 0.0f, fCirclePositions[1] - 10.0f, 1.0f);
        }
        else if (1 == g_X_Y_Z)
        {
        	glUniform4f(lightPositionVectorUniform_sj, 0.0f, fCirclePositions[0], fCirclePositions[1] - 10.0f, 1.0f);
        }

        glUniform3fv(laUniform, 1, light_ambient);
        glUniform3fv(lsUniform, 1, light_specular);
        glUniform3fv(ldUniform, 1, light_diffused);
    
        glUniform3fv(kaUniform_sj, 1, material_ambient_emerald);
        glUniform3fv(kdUniform_sj, 1, material_diffused_emerald);
        glUniform3fv(ksUniform_sj, 1, material_specular_emerald);
        glUniform1f(shineynessUniform_sj, material_shineyness_emerald);
    }
    else
    {
        glUniform1i(uiKeyOfLightsIsPressed, 0);
    }

    glUniformMatrix4fv(uiModelMatrixUniform, 1, GL_FALSE, modelMatrix);
    glUniformMatrix4fv(uiViewMatrixUniform, 1, GL_FALSE, viewMatrix);
    glUniformMatrix4fv(uiProjectionUniform, 1, GL_FALSE, perspectiveProjectionMatrix);

    modelMatrix = vmath::translate(0.0f, 0.0f, -6.0f);

    //glViewport(0, (GLsizei)height * 2.7 / 4, (GLsizei)width / 3, (GLsizei)height / 3);

    glBindVertexArray(vao_sphere);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_sphere_elements);
    glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_INT, 0);

    glBindVertexArray(0);
    //[self reshape];

    // Jade

    if (true == boKeyOfLightsIsPressed)
    {
        glUniform3fv(kaUniform_sj, 1, material_ambient_jade);
        glUniform3fv(kdUniform_sj, 1, material_diffused_jade);
        glUniform3fv(ksUniform_sj, 1, material_specular_jade);
        glUniform1f(shineynessUniform_sj, material_shineyness_jade);
    }
    else
    {
        glUniform1i(uiKeyOfLightsIsPressed, 0);
    }

    glViewport(0, (GLsizei)height * 2.2/ 4, (GLsizei)width / 3, (GLsizei)hight / 3);
    glBindVertexArray(vao_sphere);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_sphere_elements);
    glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
    [self reshape];

    glUseProgram(0);

    glDisable(GL_POLYGON_OFFSET_FILL);
    ind = ind + 1;
    if (ind > 1000)
    {
        ind = 0;
    }

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
        case 'q':
        case 'Q':
                [self release];
                [NSApp terminate:self];

            break;

        case 27: // Esc Key
                [[self window]toggleFullScreen:self];

            break;

        case 'x':
        case 'X':
            g_X_Y_Z = 1;
            break;

        case 'Y':
        case 'y':
            g_X_Y_Z = 2;
            break;

        case 'z':
        case 'Z':
            g_X_Y_Z = 3;
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
