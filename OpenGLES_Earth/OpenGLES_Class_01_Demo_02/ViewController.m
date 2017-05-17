//
//  ViewController.m
//  OpenGLES_Class_01_Demo_02
//
//  Created by cai xuejun on 12-8-23.
//  Copyright (c) 2012年 caixuejun. All rights reserved.
//

#import "ViewController.h"

@import OpenGLES;

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)
#define STACK_NUM 128
#define SLICE_NUM 128
#define SQUASH 1.0f
#define SCALE 1.0f
#define SS_SUNLIGHT GL_LIGHT0

@implementation ViewController
@synthesize context = _context;
@synthesize effect = _effect;
@synthesize textureFile = _textureFile;
@synthesize textureInfo = _textureInfo;

- (void)viewDidLoad {
	[super viewDidLoad];

	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

	if (!self.context) {
		NSLog(@"Failed to create ES context");
	}

	GLKView *view = (GLKView *)self.view;
	view.context = self.context;
	view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

	[EAGLContext setCurrentContext:self.context];

	self.textureFile = [NSString stringWithFormat:@"earth_light.png"];
	[self creatEarth];
	[self initLighting];
	[self setClipping];
}

- (void)initLighting {
	GLfloat sunPos[] = {2.0, 0.3, 0.0, 1.0};

	GLfloat white[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat cyan[] = {0.0, 1.0, 1.0, 1.0};
	GLfloat dimblue[] = {0.0, 0.0, .2, 1.0};

	glLightfv(SS_SUNLIGHT, GL_POSITION, sunPos);
	glLightfv(SS_SUNLIGHT, GL_DIFFUSE, white);
	glLightfv(SS_SUNLIGHT, GL_SPECULAR, cyan);
	glLightf(SS_SUNLIGHT, GL_QUADRATIC_ATTENUATION, .001);

	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, white);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, dimblue);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 25);

	glShadeModel(GL_SMOOTH);
	glLightModelf(GL_LIGHT_MODEL_TWO_SIDE, 0.0);

	glEnable(GL_LIGHTING);
	glEnable(SS_SUNLIGHT);
}

- (void)setClipping {
	float aspectRatio;
	const float zNear = 0.01;
	const float zFar = 1000.0f;
	const float fieldOfView = 45.0;
	GLfloat size;

	CGRect frame = [[UIScreen mainScreen] bounds];

	aspectRatio = (float)frame.size.width / (float)frame.size.height;

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	size = zNear * tanf(GLKMathDegreesToRadians(fieldOfView) / 2.0);
	glFrustumf(-size, size, -size / aspectRatio, size / aspectRatio, zNear, zFar);
	glViewport(0, 0, frame.size.width, frame.size.height);

	glMatrixMode(GL_MODELVIEW);
}

#pragma mark - GLKView and GLKViewController delegate methods

static CGFloat rot = 0;
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
	glClearColor(0.2, 0.2, 0.2, 1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();

	glTranslatef(0, 0, -4);
	glRotatef(rot, 0.0f, 1.0f, 0.0f);

	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	glFrontFace(GL_CW);

	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);

	if (self.textureInfo) {
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);

		if (self.textureInfo) {
			glBindTexture(GL_TEXTURE_2D, self.textureInfo.name);
		}

		glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	}

	glVertexPointer(3, GL_FLOAT, 0, vertexes);
	glNormalPointer(GL_FLOAT, 0, normals);

	glDrawArrays(GL_TRIANGLE_STRIP, 0, (m_Slices + 1) * 2 * (m_Stacks - 1) + 2);

	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGFloat move_rot = [touch locationInView:self.view].x - [touch previousLocationInView:self.view].x;
	rot = rot + move_rot;
}

#pragma mark - Creat Earth

- (void)creatEarth {
	m_Stacks = STACK_NUM;
	m_Slices = SLICE_NUM;
	m_Squash = SQUASH;
	m_Scale = SCALE;

	unsigned int colorIncrment = 0;
	unsigned int blue = 0;
	unsigned int red = 255;
	long numVertices = 0;

	if (self.textureFile) {
		self.textureInfo = [self loadTexture];
	}

	vertexes = nil;
	colors = nil;
	normals = nil;
	texCoords = nil;

	GLfloat *vPtr = vertexes =
	        (GLfloat *)malloc(sizeof(GLfloat) * 3 * ((m_Slices * 2 + 2) * (m_Stacks)));

	GLubyte *cPtr = colors =
	        (GLubyte *)malloc(sizeof(GLubyte) * 4 * ((m_Slices * 2 + 2) * (m_Stacks)));

	GLfloat *nPtr = normals = (GLfloat *)
	        malloc(sizeof(GLfloat) * 3 * ((m_Slices * 2 + 2) * (m_Stacks)));

	GLfloat *tPtr = nil;
	if (self.textureFile) {
		tPtr = texCoords =
		        (GLfloat *)malloc(sizeof(GLfloat) * 2 * ((m_Slices * 2 + 2) * (m_Stacks)));
	}

	unsigned int phiIdx, thetaIdx;
	for (phiIdx = 0; phiIdx < m_Stacks; phiIdx++) {
		float phi0 = M_PI * ((float)(phiIdx + 0) * (1.0 / (float)
		                                            (m_Stacks)) - 0.5);

		float phi1 = M_PI * ((float)(phiIdx + 1) * (1.0 / (float)
		                                            (m_Stacks)) - 0.5);
		float cosPhi0 = cos(phi0);
		float sinPhi0 = sin(phi0);
		float cosPhi1 = cos(phi1);
		float sinPhi1 = sin(phi1);

		float cosTheta, sinTheta;

		for (thetaIdx = 0; thetaIdx < m_Slices; thetaIdx++) {
			float theta = -2.0 * M_PI * ((float)thetaIdx) *
			    (1.0 / (float)(m_Slices - 1));
			cosTheta = cos(theta);
			sinTheta = sin(theta);

			vPtr[0] = m_Scale * cosPhi0 * cosTheta;
			vPtr[1] = m_Scale * sinPhi0 * m_Squash;
			vPtr[2] = m_Scale * (cosPhi0 * sinTheta);

			vPtr[3] = m_Scale * cosPhi1 * cosTheta;
			vPtr[4] = m_Scale * sinPhi1 * m_Squash;
			vPtr[5] = m_Scale * (cosPhi1 * sinTheta);

			nPtr[0] = cosPhi0 * cosTheta;
			nPtr[2] = cosPhi0 * sinTheta;
			nPtr[1] = sinPhi0;

			nPtr[3] = cosPhi1 * cosTheta;
			nPtr[5] = cosPhi1 * sinTheta;
			nPtr[4] = sinPhi1;

			if (tPtr != nil) {
				GLfloat texX = (float)thetaIdx * (1.0f / (float)(m_Slices - 1));
				tPtr[0] = texX;
				tPtr[1] = (float)(phiIdx + 0) * (1.0f / (float)(m_Stacks));
				tPtr[2] = texX;
				tPtr[3] = (float)(phiIdx + 1) * (1.0f / (float)(m_Stacks));
			}

			cPtr[0] = red;
			cPtr[1] = 0;
			cPtr[2] = blue;
			cPtr[4] = red;
			cPtr[5] = 0;
			cPtr[6] = blue;
			cPtr[3] = cPtr[7] = 255;

			cPtr += 2 * 4;
			vPtr += 2 * 3;
			nPtr += 2 * 3;

			if (tPtr != nil) {
				tPtr += 2 * 2;
			}
		}

		blue += colorIncrment;
		red -= colorIncrment;

		vPtr[0] = vPtr[3] = vPtr[-3];
		vPtr[1] = vPtr[4] = vPtr[-2];
		vPtr[2] = vPtr[5] = vPtr[-1];

		nPtr[0] = nPtr[3] = nPtr[-3];
		nPtr[1] = nPtr[4] = nPtr[-2];
		nPtr[2] = nPtr[5] = nPtr[-1];

		if (tPtr != nil) {
			tPtr[0] = tPtr[2] = tPtr[-2];
			tPtr[1] = tPtr[3] = tPtr[-1];
		}
	}

	numVertices = (vPtr - vertexes) / 6;
}

- (GLKTextureInfo *)loadTexture {
	NSError *error;
	GLKTextureInfo *info;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
	                         [NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft,
	                         [NSNumber numberWithBool:TRUE], GLKTextureLoaderGenerateMipmaps, nil];


	NSString *path = [[NSBundle mainBundle]pathForResource:self.textureFile ofType:nil];
	info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
	if (info == nil) {
		NSLog(@"Err:%@", [error localizedDescription]);
	}

	glBindTexture(GL_TEXTURE_2D, info.name);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	return info;
}

- (void)dealloc {
	free(vertexes), vertexes = NULL;
	free(colors), colors = NULL;
	free(normals), normals = NULL;
	free(texCoords), texCoords = NULL;

	[_context release], _context = nil;
	[_effect release], _effect = nil;
	[_textureFile release], _textureFile = nil;
	[_textureInfo release], _textureInfo = nil;
	[super dealloc];
}

@end
