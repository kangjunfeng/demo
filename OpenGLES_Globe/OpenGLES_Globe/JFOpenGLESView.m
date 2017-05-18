//
//  JFOpenGLESView.m
//  OpenGLES_2
//
//  Created by admin on 12/04/2017.
//  Copyright © 2017 admin. All rights reserved.
//

#import "JFOpenGLESView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "gmMatrix.h"
#import "Sphere.h"

#define PI 3.141592653f
#define Angle_To_Radian(angle) (angle * PI / 180.0)


@interface JFOpenGLESView(){
    EAGLContext *_eaglContext;
    CAEAGLLayer *_glLayer;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    GLuint _glProgram;
    
    GLuint _glPosition;
    GLuint _texture;
    GLuint _textureCoords;
    GLuint _textureID;
    GLuint _uMatrix;
    
    gmMatrix4 _mMatrix4;
    
    GLint _viewWidth;
    GLint _viewHeight;
    
    GLfloat   *_vertexData; // 顶点数据
    GLfloat   *_texCoords;  // 纹理坐标
    GLushort  *_indices;    // 顶点索引
    GLint    _numVetex;   // 顶点数量
    GLuint  _texCoordsBuffer;// 纹理坐标内存标识
    GLuint  _numIndices; // 顶点索引的数量
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
}

@end

@implementation JFOpenGLESView

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

-(id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame =frame;
        [self initGLWithFrame:frame];
        [self setupLayer];
        [self deleteBuffer];
        [self initBuffer];
        [self initProgram];
        [self initImageTexture];
        [self initParm];
        
        // Set up Display Link
        CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(CADisplayLinkRender:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    }
    return self;
}

/**
 * 创建渲染对象
 */
-(void)initGLWithFrame:(CGRect)frame
{
    _eaglContext =[[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_eaglContext];
}

/**
 * 创建渲染视图
 */
- (void)setupLayer
{
    _glLayer = (CAEAGLLayer*) self.layer;
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    _glLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    _glLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

/**
 * 创建渲染缓存
 */
-(void)initBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    glGenFramebuffers(1,&_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER,_frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _frameBuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewHeight);
    
}

/**
 * 删除渲染缓存
 */
-(void)deleteBuffer
{
    if (_colorRenderBuffer) {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer=0;
    }
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer= 0;
    }
}

/**
 * 创建渲染片元及着色器
 */
-(void)initProgram
{
    //shader
    GLuint vertext  =[self compileWithShaderName:@"Vertex" shaderType:GL_VERTEX_SHADER];
    GLuint fragment =[self compileWithShaderName:@"Fragment" shaderType:GL_FRAGMENT_SHADER];
    
    _glProgram =glCreateProgram();
    glAttachShader(_glProgram, vertext);
    glAttachShader(_glProgram, fragment);

    //操作产生最后的可执行程序，它包含最后可以在硬件上执行的硬件指令。
    glLinkProgram(_glProgram);
    
    GLint linkSuccess = GL_TRUE;
    glGetProgramiv(_glProgram, GL_LINK_STATUS,&linkSuccess);
    if (linkSuccess ==GL_FALSE) {
        GLchar glMessage[256];
        glGetProgramInfoLog(_glProgram, sizeof(glMessage), 0, &glMessage[0]);
        NSString *messageString = [NSString stringWithUTF8String:glMessage];
        NSLog(@"program error %@", messageString);
        exit(1);
    }
    
    //绑定着色器参数
    glUseProgram(_glProgram);
}

-(GLuint)compileWithShaderName:(NSString*)name shaderType:(GLenum)shaderType
{
    //获取着色器文件
    NSString *shaderPath =[[NSBundle mainBundle]pathForResource:name ofType:@"glsl"];
    NSError *error;
    NSString *strShader =[NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];

    if (!strShader) {
        NSLog(@"shader error %@",error.localizedDescription);
        exit(1);
    }
    
    // 2 创建一个代表shader的OpenGL对象, 指定vertex或fragment shader
    GLuint shaderHandler = glCreateShader(shaderType);
    
    // 3 获取shader的source
    const char* shaderString = [strShader UTF8String];
    int shaderStringLength = (int)[strShader length];
    glShaderSource(shaderHandler, 1, &shaderString, &shaderStringLength);
    
    // 4 编译shader
    glCompileShader(shaderHandler);
    
    // 5 查询shader对象的信息
    GLint compileSuccess;
    glGetShaderiv(shaderHandler, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandler, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderHandler;
}

/**
 * 创建图片纹理
 */
-(void)initImageTexture
{
    //获取图片
    NSString *imgPath =[[NSBundle mainBundle]pathForResource:@"balitieta" ofType:@"jpg"];
    NSData   *data    =[[NSData alloc]initWithContentsOfFile:imgPath];
    UIImage  *image   =[UIImage imageWithData:data];
    _textureID =[self createTextureWithImage:image];
}

-(GLuint)createTextureWithImage:(UIImage*)image
{
    //获取图片基本参数
    CGImageRef imageRef =[image CGImage];
    GLuint width   = (GLuint)CGImageGetWidth(imageRef);
    GLuint height  = (GLuint)CGImageGetHeight(imageRef);
    CGRect rect    = CGRectMake(0,0,width,height);
    
    //绘制
    CGColorSpaceRef  colorSpace =  CGColorSpaceCreateDeviceRGB();
    void *imageData  =  malloc(width*height*4);
    /**
     *  CGBitmapContextCreate(void * __nullable data,size_t width, size_t height, size_t
     *  bitsPerComponent, size_t bytesPerRow,CGColorSpaceRef cg_nullable space, uint32_t
     *  bitmapInfo)
     *  data:指向绘图操作被渲染的内存区域，这个内存区域大小应该为（bytesPerRow*height）个字节。如果对绘制操作被
     渲染的内存区域并无特别的要求，那么可以传递NULL给参数data。
     *  width:代表被渲染内存区域的宽度。
     *  height:代表被渲染内存区域的高度。
     *  bitsPerComponent:被渲染内存区域中组件在屏幕每个像素点上需要使用的bits位，举例来说，如果使用32-bit像素和
     RGB颜色格式，那么RGBA颜色格式中每个组件在屏幕每个像素点上需要使用的bits位就为32/4=8。
     *  bytesPerRow:代表被渲染内存区域中每行所使用的bytes位数。
     *  colorspace:用于被渲染内存区域的“位图上下文”。
     *  bitmapInfo:指定被渲染内存区域的“视图”是否包含一个alpha（透视）通道以及每个像素相应的位置，除此之外还
     可以指定组件式是浮点值还是整数值。
     */
    CGContextRef contextRef = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    /**
     *  void CGContextTranslateCTM ( CGContextRef c, CGFloat tx, CGFloat ty )：平移坐标系统。
     *  该方法相当于把原来位于 (0, 0) 位置的坐标原点平移到 (tx, ty) 点。在平移后的坐标系统上绘制图形时，所有坐标点的 X 坐标都相当于增加了 tx，所有点的 Y 坐标都相当于增加了 ty。
     */
    CGContextTranslateCTM(contextRef, 0, height);
    /**
     *  void CGContextScaleCTM ( CGContextRef c, CGFloat sx, CGFloat sy )：缩放坐标系统。
     *  该方法控制坐标系统水平方向上缩放 sx，垂直方向上缩放 sy。在缩放后的坐标系统上绘制图形时，所有点的 X 坐标都相当于乘以 sx 因子，所有点的 Y 坐标都相当于乘以 sy 因子。
     */
    
    CGContextScaleCTM(contextRef, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(contextRef, rect);
    CGContextDrawImage(contextRef, rect, imageRef);
    
    //生成纹理
    glEnable(GL_TEXTURE_2D);
    GLuint textureID;
    glGenTextures(1,&textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //纹理设置
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    
    /**
     *  void glTexImage2D(GLenum target,GLint level,GLint internalformat,GLsizei width,GLsizei
     height,GLint border,GLenum format,GLenum type,const GLvoid * pixels);
     *  target  指定目标纹理，这个值必须是GL_TEXTURE_2D。
     *  level   执行细节级别。0是最基本的图像级别，你表示第N级贴图细化级别。
     *  internalformat     指定纹理中的颜色组件，这个取值和后面的format取值必须相同。可选的值有
     GL_ALPHA,GL_RGB,GL_RGBA,GL_LUMINANCE,GL_LUMINANCE_ALPHA 等几种。
     *  width   指定纹理图像的宽度，必须是2的n次方。纹理图片至少要支持64个材质元素的宽度
     *  height  指定纹理图像的高度，必须是2的m次方。纹理图片至少要支持64个材质元素的高度
     *  border  指定边框的宽度。必须为0。
     *  format  像素数据的颜色格式，必须和internalformatt取值必须相同。可选的值有
     GL_ALPHA,GL_RGB,GL_RGBA,GL_LUMINANCE,GL_LUMINANCE_ALPHA 等几种。
     *  type    指定像素数据的数据类型。可以使用的值有
     GL_UNSIGNED_BYTE,
     GL_UNSIGNED_SHORT_5_6_5,
     GL_UNSIGNED_SHORT_4_4_4_4,
     GL_UNSIGNED_SHORT_5_5_5_1
     *  pixels  指定内存中指向图像数据的指针
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    //绑定纹理位置
    glBindTexture(GL_TEXTURE_2D, 0);
    //释放内存
    CGContextRelease(contextRef);
    free(imageData);
    
    return textureID;
}


- (GLuint)setupTexture:(UIImage *)image {
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glEnable(GL_TEXTURE_2D);
    
    /**
     *  GL_TEXTURE_2D表示操作2D纹理
     *  创建纹理对象，
     *  绑定纹理对象，
     */
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    /**
     *  纹理过滤函数
     *  图象从纹理图象空间映射到帧缓冲图象空间(映射需要重新构造纹理图像,这样就会造成应用到多边形上的图像失真),
     *  这时就可用glTexParmeteri()函数来确定如何把纹理象素映射成像素.
     *  如何把图像从纹理图像空间映射到帧缓冲图像空间（即如何把纹理像素映射成像素）
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    /**
     *  将图像数据传递给到GL_TEXTURE_2D中, 因其于textureID纹理对象已经绑定，所以即传递给了textureID纹理对象中。
     *  glTexImage2d会将图像数据从CPU内存通过PCIE上传到GPU内存。
     *  不使用PBO时它是一个阻塞CPU的函数，数据量大会卡。
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // 结束后要做清理
    glBindTexture(GL_TEXTURE_2D, 0); //解绑
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}


-(void)initParm
{
    InitgmMatrix4(&_mMatrix4);
    
    //坐标、纹理、索引
    _numIndices = createSphere(200, 1.0, &(_vertexData), &(_texCoords), &_indices, &_numVetex);
    
    //参数
    _glPosition = glGetAttribLocation(_glProgram,"Position");
    _texture    = glGetUniformLocation(_glProgram, "Texture");//frag
    _textureCoords = glGetAttribLocation(_glProgram, "TextureCoords");
    _uMatrix    = glGetUniformLocation(_glProgram, "Matrix");
}

-(void)CADisplayLinkRender:(CADisplayLink *)displayLink
{
    [self draw];
}


/**
 * 绘制
 */
-(void)draw{
    //清屏
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //设置绘制区域
//    glViewport(self.frame.size.width/2-100,self.frame.size.height/2-100,200,200);
    glViewport(0,_viewHeight/2-_viewWidth/2, _viewWidth, _viewWidth);
    //激活
    glActiveTexture(GL_TEXTURE5); // 指定纹理单元GL_TEXTURE5
    glBindTexture(GL_TEXTURE_2D, _textureID); // 绑定，即可从_textureID中取出图像数据。
    glUniform1i(_texture, 5); // 与纹理单元的序号对应
    
    //render
//    [self renderVertices];
    [self renderSphereVertice3];
    
    // 使用完之后解绑GL_TEXTURE_2D
    glBindTexture(GL_TEXTURE_2D, 0);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

-(void)renderSphereVertice1
{
    NSMutableArray *array =[NSMutableArray array];

    float r1,r2;
    float h1,h2;
    float sin,cos;
    int step =2.0f;
    for(float i=-90;i<90+step;i+=step)
    {
        r1 = (float)cosf(i * PI / 180.0);
        r2 = (float)cosf((i + step) * PI / 180.0);
        h1 = (float)sinf(i * PI / 180.0);
        h2 = (float)sinf((i + step) * PI / 180.0);
        //固定纬度, 360 度旋转遍历一条纬线
        float step2=step*2;
        for (float j = 0.0f; j <360.0f+step2;j +=step2 )
        {
            cos = (float) cosf(j * PI / 180.0);
            sin = -(float) sinf(j * PI / 180.0);
            
            [array addObject:@(r2*cos)];
            [array addObject:@(h2)];
            [array addObject:@(r2*sin)];
            [array addObject:@(r1*cos)];
            [array addObject:@(h1)];
            [array addObject:@(r1*sin)];
        }
    }
    
    int size =(int)array.count;
    GLfloat vertices[size];
    for(int i=0;i<size;i++){
        vertices[i]=[array[i] floatValue];
    }

//    gmMatrix4 model, view, proj;
//
//    static float angle = 0.0f;
//    gmMatrixRotateY(&model, angle);
//    angle += 0.1f;
//
//    gmVector3 eye = {0.0f, 0.0f, -1.0f};
//    gmVector3 at =  {0.0f, 0.0f, 0.0f};
//    gmVector3 up =  {0.0f, 0.5f, 0.0f};
//
//    gmMatrixPerspectiveFovLH(&proj, 10.0f, (float)_viewWidth / (float)_viewHeight, -5.0f, 1000.0f);
//    gmMatrixLookAtLH(&view, &eye, &at, &up);
//
//    gmMatrixMultiply(&_mMatrix4, &model, &view);
//    gmMatrixMultiply(&_mMatrix4, &_mMatrix4, &proj);
   
    //矩阵传递
    glUniformMatrix4fv(_uMatrix, 1, 0, (float*)&_mMatrix4);
    glEnableVertexAttribArray(_glPosition);
    glVertexAttribPointer(_glPosition, 3, GL_FLOAT, GL_FALSE,0, vertices);
    glDrawArrays(GL_TRIANGLE_STRIP,0,size/3);
}

-(void)renderSphereVertice2
{
    NSMutableArray *verticeArray =[NSMutableArray array];
    
    static float UNIT_SIZE = 1.0f;// 单位尺寸
    float r = 0.8f; // 球的半径
    int angleSpan = 10;// 将球进行单位切分的角度
    int vCount = 0;// 顶点个数，先初始化为0
    
    for (int vAngle = -90; vAngle < 90; vAngle = vAngle + angleSpan)// 垂直方向angleSpan度一份
    {
        for (int hAngle = 0; hAngle <= 360; hAngle = hAngle + angleSpan)// 水平方向angleSpan度一份
        {
            // 纵向横向各到一个角度后计算对应的此点在球面上的坐标
            float x0 = (float) (r * UNIT_SIZE* sin(vAngle) * cos(hAngle));
            float y0 = (float) (r * UNIT_SIZE* sin(vAngle) * sin(hAngle));
            float z0 = (float) (r * UNIT_SIZE * cos(vAngle));
            // Log.w("x0 y0 z0","" + x0 + "  "+y0+ "  " +z0);

            float x1 = (float) (r * UNIT_SIZE * sin(vAngle) * cos(hAngle + angleSpan));
            float y1 = (float) (r * UNIT_SIZE * sin(vAngle) * sin(hAngle + angleSpan));
            float z1 = (float) (r * UNIT_SIZE * cos(vAngle));
            // Log.w("x1 y1 z1","" + x1 + "  "+y1+ "  " +z1);

            float x2 = (float) (r * UNIT_SIZE * sin(vAngle + angleSpan) * cos(hAngle + angleSpan));
            float y2 = (float) (r * UNIT_SIZE * sin(vAngle + angleSpan) * sin(hAngle + angleSpan));
            float z2 = (float) (r * UNIT_SIZE * cos(vAngle + angleSpan));
            // Log.w("x2 y2 z2","" + x2 + "  "+y2+ "  " +z2);
            float x3 = (float) (r * UNIT_SIZE * sin(vAngle + angleSpan) * cos(hAngle));
            float y3 = (float) (r * UNIT_SIZE * sin(vAngle + angleSpan) * sin(hAngle));
            float z3 = (float) (r * UNIT_SIZE * cos(vAngle + angleSpan));
            // Log.w("x3 y3 z3","" + x3 + "  "+y3+ "  " +z3);
//             将计算出来的XYZ坐标加入存放顶点坐标的ArrayList
            [verticeArray addObject:@(x0)];
            [verticeArray addObject:@(y0)];
            [verticeArray addObject:@(z0)];
            [verticeArray addObject:@(x3)];
            [verticeArray addObject:@(y3)];
            [verticeArray addObject:@(z3)];
            [verticeArray addObject:@(x1)];
            [verticeArray addObject:@(y1)];
            [verticeArray addObject:@(z1)];

            [verticeArray addObject:@(x1)];
            [verticeArray addObject:@(y1)];
            [verticeArray addObject:@(z1)];
            [verticeArray addObject:@(x2)];
            [verticeArray addObject:@(y2)];
            [verticeArray addObject:@(z2)];
            [verticeArray addObject:@(x3)];
            [verticeArray addObject:@(y3)];
            [verticeArray addObject:@(z3)];
        }
    }
    
    vCount = (int)verticeArray.count;
    // 将alVertix中的坐标值转存到一个float数组中
    float vertices[vCount];
    for (int i = 0; i < vCount; i++) {
        vertices[i] = [verticeArray[i] floatValue];
    }

//    //投影视角
//    GLKMatrix4 frustumMatrix =GLKMatrix4MakeFrustum(-1.0,1.0,-1.0,1.0f,-10,10);
//    frustumMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, -20.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.5f, 0.0f);
//
//    float aspect = fabsf(_viewWidth /_viewWidth);
//    GLKMatrix4 projectionMatrix =GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f),aspect, 0.5f,1.0f);
    
    glUniformMatrix4fv(_uMatrix, 1, 0, (float*)&_mMatrix4);
    glEnableVertexAttribArray(_glPosition);
    glVertexAttribPointer(_glPosition, 3, GL_FLOAT, GL_FALSE,0, vertices);
    glDrawArrays(GL_TRIANGLES,0,vCount/3);

}

-(void)renderSphereVertice3
{
    // 加载顶点坐标数据
    glGenBuffers(1, &_vertexBuffer); // 申请内存
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer); // 将命名的缓冲对象绑定到指定的类型上去
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*_numVetex*3,_vertexData, GL_STATIC_DRAW);
    
    // 加载顶点索引数据
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numIndices*sizeof(GLushort), _indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(_glPosition);  // 绑定到位置上
    glVertexAttribPointer(_glPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), NULL);
  
    // 加载纹理坐标
    glGenBuffers(1, &_texCoordsBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _texCoordsBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*_numVetex*2, _texCoords, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(_textureCoords);
    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), NULL);
   
    
    glUniformMatrix4fv(_uMatrix, 1, 0, (float*)&_mMatrix4);
    glDrawElements(GL_TRIANGLES, (GLsizei)_numIndices,GL_UNSIGNED_SHORT, nil);

    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteBuffers(1, &_texCoordsBuffer);
}


-(void)renderVertices
{
    GLfloat texCoords[] = {
        0, 0,//左下
        1, 0,//右下
        0, 1,//左上
        1, 1,//右上
    };
   
    /**
     *void glVertexAttribPointer(GLuint index,GLint size,GLenum type,GLboolean normalized,GLsizei
     *                            stride,const void *ptr)
     *     index: 着色器脚本对应变量ID
     *     size : 此类型数据的个数
     *     type : 此类型的sizeof值
     *     normalized : 是否对非float类型数据转化到float时候进行归一化处理
     *     stride : 此类型数据在数组中的重复间隔宽度，byte类型计数
     *     ptr    : 数据指针， 这个值受到VBO的影响
     */
    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    glEnableVertexAttribArray(_textureCoords);
    
    GLfloat vertices[] = {
        -1, -1, 0, //左下
         1, -1, 0, //右下
        -1,  1, 0, //左上
         1,  1, 0  //右上
    };
    glVertexAttribPointer(_glPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(_glPosition);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

-(void)renderByVBO
{
    const GLfloat texCoords[] = {
        0, 0,//左下
        1, 0,//右下
        0, 1,//左上
        1, 1,//右上
    };
    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    glEnableVertexAttribArray(_textureCoords);


    const GLfloat vertices[] = {
        -1, -1, 0, //左下
         1, -1, 0, //右下
        -1,  1, 0, //左上
         1,  1, 0  //右上
    };

    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(_glPosition, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(_glPosition);


    const GLubyte indices[] = {
        0,1,2,
        1,2,3
    };
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
}



-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    UITouch * touch = [touches anyObject];
//    CGPoint location = [touch locationInView:self];
//    CGPoint lastLoc = [touch previousLocationInView:self];
//    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
//    
//
//    float rotX = -1 * GLKMathDegreesAngle_To_Radian(diff.y / 2.0);
//    float rotY = -1 * GLKMathDegreesAngle_To_Radian(diff.x / 2.0);
//    
//    GLKMatrix4 _rotMatrix = GLKMatrix4MakeOrtho(-2, 2, -3, 3, -1, 1);
//    GLKVector3 xAxis = GLKVector3Make(1, 0, 0);
//    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
//    GLKVector3 yAxis = GLKVector3Make(0, 1, 0);
//    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);

    static float angle = 0.0f;
    gmMatrixRotateY(&_mMatrix4, angle);
    angle += 0.1f;
    

    //    gmMatrixScale(&_mMatrix4,0.5f,0.5f,1.0f);
}



/*-------------------------  相机视角 -------------------------*/
//    GLKMatrix4 eyeMatrix= GLKMatrix4MakeLookAt(0.0f, 0.0f, -20.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.5f, 0.0f);
//    //投影视角
//    GLKMatrix4 frustumMatrix =GLKMatrix4MakeFrustum(-1.0,1.0,-1.0,1.0f,-10,10);
//
//    float aspect = fabsf(_viewWidth /_viewWidth);
//    GLKMatrix4 projectionMatrix =GLKMatrix4MakePerspective(GLKMathDegreesAngle_To_Radian(65.0f),aspect, 0.5f,1.0f);
//
//    float newF[16]={
//        eyeMatrix.m[0]*frustumMatrix.m[0],
//        eyeMatrix.m[1]*frustumMatrix.m[1],
//        eyeMatrix.m[2]*frustumMatrix.m[2],
//        eyeMatrix.m[3]*frustumMatrix.m[3],
//        eyeMatrix.m[4]*frustumMatrix.m[4],
//        eyeMatrix.m[5]*frustumMatrix.m[5],
//        eyeMatrix.m[6]*frustumMatrix.m[6],
//        eyeMatrix.m[7]*frustumMatrix.m[7],
//        eyeMatrix.m[8]*frustumMatrix.m[8],
//        eyeMatrix.m[9]*frustumMatrix.m[9],
//        eyeMatrix.m[10]*frustumMatrix.m[10],
//        eyeMatrix.m[11]*frustumMatrix.m[11],
//        eyeMatrix.m[12]*frustumMatrix.m[12],
//        eyeMatrix.m[13]*frustumMatrix.m[13],
//        eyeMatrix.m[14]*frustumMatrix.m[14],
//        eyeMatrix.m[15]*frustumMatrix.m[15]
//    };





/*-------------------------- 顶点坐标 ----------------------------*/
//    static int angleSpan = 5;
//    float mRadius =1.0;
//    static float UNIT_SIZE = 1.0f;
//    static float DEFAULT_RADIUS = 0.5f;
//
//    for (int vAngle = -90; vAngle < 90; vAngle = vAngle + angleSpan) {
//        for (int hAngle = 0; hAngle <= 360; hAngle = hAngle + angleSpan) {
//            float x0 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle)) * cos(Angle_To_Radian(hAngle)));
//            float y0 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle)) * sin(Angle_To_Radian(hAngle)));
//            float z0 = (float) (mRadius * UNIT_SIZE * sin(Angle_To_Radian(vAngle)));
//
//            float x1 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle)) * cos(Angle_To_Radian(hAngle + angleSpan)));
//            float y1 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle)) * sin(Angle_To_Radian(hAngle + angleSpan)));
//            float z1 = (float) (mRadius * UNIT_SIZE * sin(Angle_To_Radian(vAngle)));
//
//            float x2 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle + angleSpan)) *
//                                cos(Angle_To_Radian(hAngle + angleSpan)));
//            float y2 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle + angleSpan)) *
//                                sin(Angle_To_Radian(hAngle + angleSpan)));
//            float z2 = (float) (mRadius * UNIT_SIZE * sin(Angle_To_Radian(vAngle + angleSpan)));
//
//            float x3 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle + angleSpan)) *
//                                cos(Angle_To_Radian(hAngle)));
//            float y3 = (float) (mRadius * UNIT_SIZE
//                                * cos(Angle_To_Radian(vAngle + angleSpan)) *
//                                sin(Angle_To_Radian(hAngle)));
//            float z3 = (float) (mRadius * UNIT_SIZE * sin(Angle_To_Radian(vAngle + angleSpan)));
//
//            // 将计算出来的XYZ坐标加入存放顶点坐标的ArrayList
//            [array addObject:@(x0)];
//            [array addObject:@(y0)];
//            [array addObject:@(z0)];
//
//            [array addObject:@(x3)];
//            [array addObject:@(y3)];
//            [array addObject:@(z3)];
//
//            [array addObject:@(x1)];
//            [array addObject:@(y1)];
//            [array addObject:@(z1)];
//
//
//            [array addObject:@(x1)];
//            [array addObject:@(y1)];
//            [array addObject:@(z1)];
//
//            [array addObject:@(x3)];
//            [array addObject:@(y3)];
//            [array addObject:@(z3)];
//
//            [array addObject:@(x2)];
//            [array addObject:@(y2)];
//            [array addObject:@(z2)];
//        }
//    }


@end
