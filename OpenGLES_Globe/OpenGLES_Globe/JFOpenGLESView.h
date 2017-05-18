//
//  JFOpenGLESView.h
//  OpenGLES_2
//
//  Created by admin on 12/04/2017.
//  Copyright © 2017 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JFOpenGLESView : UIView

@end
//    for (int vAngle = 0; vAngle < 180; vAngle = vAngle + angleSpan)// 垂直方向angleSpan度一份
//    {
//        for (int hAngle = 0; hAngle <= 360; hAngle = hAngle + angleSpan)// 水平方向angleSpan度一份
//        {
//            // 纵向横向各到一个角度后计算对应的此点在球面上的坐标
//            float x0 = (float) (r * UNIT_SIZE* sin(Angle_To_Radian(vAngle)) * cos(Angle_To_Radian(hAngle)));
//            float y0 = (float) (r * UNIT_SIZE* sin(Angle_To_Radian(vAngle)) * sin(Angle_To_Radian(hAngle)));
//            float z0 = (float) (r * UNIT_SIZE * cos(Angle_To_Radian(vAngle)));
//            // Log.w("x0 y0 z0","" + x0 + "  "+y0+ "  " +z0);
//
//            float x1 = (float) (r * UNIT_SIZE * sin(Angle_To_Radian(vAngle)) * cos(Angle_To_Radian(hAngle + angleSpan)));
//            float y1 = (float) (r * UNIT_SIZE * sin(Angle_To_Radian(vAngle)) * sin(Angle_To_Radian(hAngle + angleSpan)));
//            float z1 = (float) (r * UNIT_SIZE * cos(Angle_To_Radian(vAngle)));
//            // Log.w("x1 y1 z1","" + x1 + "  "+y1+ "  " +z1);
//
//            float x2 = (float) (r * UNIT_SIZE * sin(Angle_To_Radian(vAngle + angleSpan)) * cos(Angle_To_Radian(hAngle + angleSpan)));
//            float y2 = (float) (r * UNIT_SIZE * sin(Angle_To_Radian(vAngle + angleSpan)) * sin(Angle_To_Radian(hAngle + angleSpan)));
//            float z2 = (float) (r * UNIT_SIZE * cos(Angle_To_Radian(vAngle + angleSpan)));
//            // Log.w("x2 y2 z2","" + x2 + "  "+y2+ "  " +z2);
//            float x3 = (float) (r * UNIT_SIZE * sin(Angle_To_Radian(vAngle + angleSpan)) * cos(Angle_To_Radian(hAngle)));
//            float y3 = (float) (r * UNIT_SIZE * sin(Angle_To_Radian(vAngle + angleSpan)) * sin(Angle_To_Radian(hAngle)));
//            float z3 = (float) (r * UNIT_SIZE * cos(Angle_To_Radian(vAngle + angleSpan)));
//            // Log.w("x3 y3 z3","" + x3 + "  "+y3+ "  " +z3);
//            // 将计算出来的XYZ坐标加入存放顶点坐标的ArrayList
//            [verticeArray addObject:@(x1)];
//            [verticeArray addObject:@(y1)];
//            [verticeArray addObject:@(z1)];
//            [verticeArray addObject:@(x3)];
//            [verticeArray addObject:@(y3)];
//            [verticeArray addObject:@(z3)];
//            [verticeArray addObject:@(x0)];
//            [verticeArray addObject:@(y0)];
//            [verticeArray addObject:@(z0)];
//
//            [verticeArray addObject:@(x1)];
//            [verticeArray addObject:@(y1)];
//            [verticeArray addObject:@(z1)];
//            [verticeArray addObject:@(x2)];
//            [verticeArray addObject:@(y2)];
//            [verticeArray addObject:@(z2)];
//            [verticeArray addObject:@(x3)];
//            [verticeArray addObject:@(y3)];
//            [verticeArray addObject:@(z3)];
//        }
//    }
