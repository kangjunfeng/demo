//
//  ViewController.h
//  OpenGLES_Class_01_Demo_02
//
//  Created by cai xuejun on 12-8-23.
//  Copyright (c) 2012年 caixuejun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController {
    GLfloat *vertexes;
	GLubyte *colors;
	GLfloat *normals;
    GLfloat *texCoords;
    
    GLint m_Stacks;
    GLint m_Slices;
    GLfloat m_Squash;
    GLfloat m_Scale;
}

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, retain) GLKBaseEffect *effect;
@property (nonatomic, copy) NSString *textureFile;
@property (nonatomic, retain) GLKTextureInfo *textureInfo;

@end
