// fisheye2.cpp : 定义控制台应用程序的入口点。
//

#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc_c.h"
#include "opencv2/core/core.hpp"
#include "opencv2/core/core_c.h"
#include "Warper.h"

using namespace cv;

int fisheye_split(IplImage *pSrc,IplImage *pLeft ,IplImage *pRight)
{
	int sLPos = 0, sRPos =0, dPos =0;
	if((pLeft->height !=  pRight->height) ||  (pLeft->width !=  pRight->width))
	{
		printf("(pLeft->height !=  pRight->height) ||  (pLeft->width !=  pRight->width)\n");
		return -1;
	}

	for(int j = 0; j <  pLeft->height; j++)
	{
		for (int i = 0; i <  pLeft->width; i++)
		{
			sLPos = j*pSrc->widthStep+3*i;
			dPos = j*pLeft->widthStep+3*i;
			pLeft->imageData[dPos ] = pSrc->imageData[sLPos ];
			pLeft->imageData[dPos +1] = pSrc->imageData[sLPos +1];
			pLeft->imageData[dPos +2] = pSrc->imageData[sLPos +2];

			sRPos = j*pSrc->widthStep+3*(i +pSrc->width/2);
			pRight->imageData[dPos ] = pSrc->imageData[sRPos ];
			pRight->imageData[dPos +1] = pSrc->imageData[sRPos +1];
			pRight->imageData[dPos +2] = pSrc->imageData[sRPos +2];
		}
	}

	return 0;
}

int fisheye_correction(int du, float R,Point2f center, IplImage* pSrc, IplImage* pDst)
{
	int w = pSrc->width;
	int h = pSrc->height;
	int o_w = pDst->width;
	int o_h = pDst->height;

	float sw = CV_PI / 180.0*((180 - du)/2);
	float angle0 = CV_PI / 180.0 * du;
	float angle1 = CV_PI;
	float dw = angle0 / o_w;
	float dh = angle1 / o_h;
	
	float rk = R;
	for (int i = 0; i < o_h; ++i)
	{
		for (int j = 0; j < o_w; ++j)
		{
			float phi = dw*j+sw;
			float theta = dh*i;

			if(phi<sw || phi> CV_PI - sw )
				continue;

			float r = 1*sinf(theta);
			float x = -r*cosf(phi);
			float y = 1*cosf(theta);
			float z = r*sinf(phi);

			int u = center.x + x * sqrtf(1 / (1 + z)) * rk;
			int v = center.y - y * sqrtf(1 / (1 + z)) * rk;
			if (u < 0 || v < 0 || u >= w || v >= h)
				continue;

			int srcpos = v * pSrc->widthStep+3*u;
			int dstpos = i * pDst->widthStep +j*3;

			pDst->imageData[dstpos ] = pSrc->imageData[srcpos ];
			pDst->imageData[dstpos +1] = pSrc->imageData[srcpos +1];
			pDst->imageData[dstpos +2] = pSrc->imageData[srcpos +2];
		}
	}
	return 0;
}

int fisheye_stitch2(int W, IplImage* pLeft ,IplImage* pRight, IplImage* pDst)
{
	Mat Left(pLeft);
	Mat Right(pRight);
	Mat Dst(pDst);

	for (int i = 0; i <  pDst->width; i++)
	{
		if(i< (pDst->width/4- W))
		{
			Dst.col(i) = Right.col(i+ pRight->width/2)*1;
		}
		else if(i< (pDst->width/4 + W))
		{
			float rate = (1.0* (i - pDst->width/4  +W))/(2*W);

			Dst.col(i) = Right.col(i+ pRight->width/2)*(1-rate)+ Left.col(i -  pDst->width/4 + W)*rate;
		}
		else if(i< (pDst->width*3/4 - W))
		{
			Dst.col(i) = Left.col( i -  pDst->width/4 + W)*1;
		}
		else if(i< (pDst->width*3.0/4  + W))
		{

			float rate = (1.0*(i - pDst->width*3.0/4 + W ))/(2*W);

			Dst.col(i) = Left.col(i - pDst->width/4+ W)*(1-rate)+ Right.col(i  -pDst->width*3.0/4 + W)*rate;
		}
		else
		{
			Dst.col(i) = Right.col( i  -  pDst->width*3/4+ W)*1;
		}
	}
	
	return 0;
}

int fisheye_stitch(int W, IplImage* pLeft ,IplImage* pRight, IplImage* pDst)
{
	if((pLeft->height !=  pRight->height) ||  (pLeft->width !=  pRight->width))
	{
		return 0;
	}
	for(int j = 0; j <  pDst->height; j++)
	{
		for (int i = 0; i <  pDst->width; i++)
		{
			if(i< (pDst->width/4- W))
			{
				int  x = i + pRight->width/2;//right, 1/2
				int  y = j;

				int srcpos = y* pRight->widthStep+x*3;
				int dstpos = j * pDst->widthStep +i*3;

				//for(int i =0; i < pDst->nChannels; i++)
				//{
				//	pDst->imageData[dstpos +i] = pRight->imageData[srcpos +i];
				//}
				pDst->imageData[dstpos ] = pRight->imageData[srcpos ];
				pDst->imageData[dstpos +1] = pRight->imageData[srcpos +1];
				pDst->imageData[dstpos +2] = pRight->imageData[srcpos +2];
			}
			else if(i< (pDst->width/4 + W))
			{
				//融合
				double rate = (1.0* (i - pDst->width/4  +W ))/(2*W);
				int srcpos1 = j* pRight->widthStep+( i + pRight->width/2)*3;//right 
				int srcpos2 = j* pLeft ->widthStep+( i -  pDst->width/4 + W)*3;//left ,0

				int dstpos = j * pDst->widthStep +i*3;

				//for(int i =0; i < pDst->nChannels; i++)
				//{
				//		pDst->imageData[dstpos+i ] = pRight->imageData[srcpos1+i ]*(1-rate)  +pLeft->imageData[srcpos2+i ]*rate;
				//}

				((uchar*)pDst->imageData)[dstpos ] = ((uchar*)pRight->imageData)[srcpos1 ] *(1-rate) +((uchar*)pLeft->imageData)[srcpos2 ] *rate;
				((uchar*)pDst->imageData)[dstpos +1] = ((uchar*)pRight->imageData)[srcpos1 +1]*(1-rate) + ((uchar*)pLeft->imageData)[srcpos2+1 ] * rate;
				((uchar*)pDst->imageData)[dstpos +2] = ((uchar*)pRight->imageData)[srcpos1+2]*(1-rate) + ((uchar*)pLeft->imageData)[srcpos2+2 ] * rate;
			}
			else if(i< (pDst->width*3/4 - W))
			{
				int x = i -  pDst->width/4 + W;//left
				int  y = j;

				int srcpos = y* pRight->widthStep+x*3;
				int dstpos = j * pDst->widthStep +i*3;

				//for(int i =0; i < pDst->nChannels; i++)
				//{
				//	pDst->imageData[dstpos+i ] = pLeft->imageData[srcpos +i];
				//}

				pDst->imageData[dstpos ] = pLeft->imageData[srcpos ];
				pDst->imageData[dstpos +1] = pLeft->imageData[srcpos +1];
				pDst->imageData[dstpos +2] = pLeft->imageData[srcpos +2];

			}
			else if(i< (pDst->width*3.0/4  + W))
			{
				float rate = (1.0*(i - pDst->width*3.0/4 + W ))/(2*W);
				int srcpos1 = j* pLeft->widthStep+(i - pDst->width/4.0+ W)*3;//left
				int srcpos2 = j* pRight->widthStep+(i  -pDst->width*3.0/4 + W)*3;//right ,0-x

				int dstpos = j * pDst->widthStep +i*3;

				//for(int i =0; i < pDst->nChannels; i++)
				//{
				//	pDst->imageData[dstpos +i] = pLeft->imageData[srcpos1 +i] *(1-rate) +pRight->imageData[srcpos2+i ] *rate;
				//}

				((uchar*)pDst->imageData)[dstpos ] = ((uchar*)pLeft->imageData)[srcpos1 ] *(1-rate) +((uchar*)pRight->imageData)[srcpos2 ] *rate;
				((uchar*)pDst->imageData)[dstpos +1] = ((uchar*)pLeft->imageData)[srcpos1 +1] *(1-rate) + ((uchar*)pRight->imageData)[srcpos2+1 ] * rate;
				((uchar*)pDst->imageData)[dstpos +2] =((uchar*) pLeft->imageData)[srcpos1 +2] *(1-rate) + ((uchar*)pRight->imageData)[srcpos2+2 ] * rate;
			}
			else
			{
				int x = i  -  pDst->width*3/4+ W;//right
				int  y = j;

				int srcpos = y* pRight->widthStep+x*3;
				int dstpos = j * pDst->widthStep +i*3;

				//for(int i =0; i < pDst->nChannels; i++)
				//{
				//	pDst->imageData[dstpos+i ] = pRight->imageData[srcpos+i ];
				//}
				pDst->imageData[dstpos ] = pRight->imageData[srcpos ];
				pDst->imageData[dstpos +1] = pRight->imageData[srcpos +1];
				pDst->imageData[dstpos +2] = pRight->imageData[srcpos +2];
			}
		}
	}
	return 0;
}

int fisheye_display(int type,IplImage* pSrc, IplImage* pDst, int dx, int dy)
{
	int w = pSrc->width;
	int h = pSrc->height;
	int ow = pDst->width;
	int oh = pDst->height;
	int  x0 = ow/2;
	int  y0 = oh/2;

	float dphi = w / (2 * CV_PI);
	float dtheta = h / CV_PI;

	float k =  oh / 4;

	int count = dx;
	float A = 2 * CV_PI * (dy % 100) / 100; 
	for (int i = 0; i < oh; ++i)
	{
		for (int j = 0; j < ow; ++j)
		{
			float X = (j - x0) / k;
			float Y = (i - y0) / k;

			float x_ = 0;
			float y_ = 0;
			float z_ = 0;
			if(type == 1)
			{
				//ste
				 x_ = 4*X / (4 + (X*X + Y*Y));
				 y_ = 4*Y / (4 + (X*X + Y*Y));
				 z_ = (4 - (X*X + Y*Y))/(4 + (X*X + Y*Y));
			}
			else	if(type == 2)
			{
				//eq
				 x_ = X * sqrtf(1 - (X*X + Y*Y) / 4);
				 y_ = Y * sqrtf(1 - (X*X + Y*Y) / 4);
				 z_ = 1 - (X*X + Y*Y) / 2;
			}
			else	if(type == 3)
			{
				//gno
				 x_ = X / sqrtf(1 + X*X + Y*Y);
				 y_ = Y / sqrtf(1 + X*X + Y*Y);
				 z_ = 1 / sqrtf(1 + X*X + Y*Y);
			}
			else
			{
				//ort
				 x_ = X;
				 y_ = Y;		
				 z_ = sqrtf(1 - X*X - Y*Y);
			}

			float x = x_;
			float y = y_ * cosf(-A) - z_ * sinf(-A);
			float z = y_ * sinf(-A) + z_ * cosf(-A);

			float r = hypot(x,y);
			if (r == 0)
				continue;

			float phi = acosf(x/r);
			if (y < 0)
				phi = 2 * CV_PI - phi;

			float t = hypot(r,z);
			if (t == 0)
				continue;

			float theta = CV_PI / 2 + asinf(z / t);
			int u = (int)(dphi * (phi + 2 * CV_PI * (count % 100) / 100)) % w;
			int v = dtheta * theta;

			if (u < 0 || v < 0 || u >= w || v >= h)
				continue;

			int srcpos = v * pSrc->widthStep + 3 * u;
			int dstpos = i * pDst->widthStep + 3 * j;

			pDst->imageData[dstpos ] = pSrc->imageData[srcpos ];
			pDst->imageData[dstpos +1] = pSrc->imageData[srcpos +1];
			pDst->imageData[dstpos +2] = pSrc->imageData[srcpos +2];
		}
	}
	return 0;
}

typedef struct
{
	KERNEK_E warpMode;
	WarperParam stWarperPar;
	CLImage_t stVertex;
	IplImage* srcImg;
	IplImage* dstImg;
	Warper* warper; 
}ShowParam_t;

void onMouse(int event,int x, int y, int flags, void* param)
{
	static bool s_bMouseLButtonDown = false;
	static CvPoint s_cvPrePoint = cvPoint(0, 0);
	int dx = 0, dy = 0, x0 = 50, y0 = 50; 

	ShowParam_t* par = (ShowParam_t *)param;
	switch (event)
	{
	case CV_EVENT_LBUTTONDOWN:
		s_bMouseLButtonDown = true;
		s_cvPrePoint = cvPoint(x, y);
		printf("xy(%d,%d)\n", s_cvPrePoint.x, s_cvPrePoint.y);
		break;

	case  CV_EVENT_LBUTTONUP:
		s_bMouseLButtonDown = false;
		break;

	case CV_EVENT_MOUSEMOVE:
		if (s_bMouseLButtonDown)
		{
			CvPoint cvCurrPoint = cvPoint(x, y);
			float dphi = 2 * CV_PI / par->dstImg->width;
			float dtheta = CV_PI / par->dstImg->height;
			float dx = cvCurrPoint.x - s_cvPrePoint.x;
			float dy = cvCurrPoint.y - s_cvPrePoint.y;

			float offx = dx * dphi + par->stWarperPar.p;
			float offy = dy * dtheta + par->stWarperPar.t;

			if (offx > CV_PI * 2)
				par->stWarperPar.p = CV_PI * 2;
			else if (offx  < 0)
				par->stWarperPar.p = 0;
			else
				par->stWarperPar.p = offx;

			if (offy > CV_PI)
				par->stWarperPar.t = CV_PI;
			else if(offy < 0)
				par->stWarperPar.t = 0;
			else 
				par->stWarperPar.t = offy;

			par->stWarperPar.z = par->stWarperPar.r / 2;

			printf("x(%d,%d),d(%f,%f) p(%f,%f)\n",x, y, dx, dy, par->stWarperPar.p, par->stWarperPar.t);
			if (par->warper->genVertex(par->warpMode, par->srcImg, par->stWarperPar, par->stVertex) < 0)
				return;

			if (par->warper->doMapGpu(par->srcImg, par->dstImg, par->stVertex) < 0)
				return;

			cvResizeWindow("imgDst", 800, 800);
			cvShowImage("imgDst", par->dstImg);

			s_cvPrePoint = cvCurrPoint;
			//cvShowImage( "imgDst", (IplImage*)param);
		}
		break;
	}
}

void addWeighted(const IplImage *src1,const IplImage* src2,IplImage* dst,double gama = 0) 
{            
	CV_Assert(src1->depth == src2->depth);   
	CV_Assert(dst->depth == src2->depth);  
	CV_Assert(src1->nChannels == src2->nChannels);   
	CV_Assert(dst->nChannels == src2->nChannels);      
	CvRect rect1 = cvGetImageROI(src1); 
	CvRect rect2 = cvGetImageROI(src2); 
	CvRect dstRect = cvGetImageROI(dst); 
	CV_Assert(rect1.width == rect2.width && rect1.height == rect2.height); 
	CV_Assert(rect2.width == dstRect.width && rect2.height == dstRect.height); 
	int c,r,l;//c--Channel，r-Row，l-coLumn 
	int val,val1,val2;   
	double alpha = 0; 
	double beta = 0; 
	if(dst->nChannels==3) 
	{ 
		for (c = 0; c < 3; c++) 
			for (r = dstRect.y; r < dstRect.y+dstRect.height; r++) 
				for (l = dstRect.x; l < dstRect.x+dstRect.width; l++) 
				{ 
					val1 = ((uchar*)(src1->imageData + src1->widthStep*(rect1.y+r-dstRect.y)))[(rect1.x+l-dstRect.x)*3+c]; 
					val2 = ((uchar*)(src2->imageData + src2->widthStep*(rect2.y+r-dstRect.y)))[(rect2.x+l-dstRect.x)*3+c]; 
					alpha = (double)(dstRect.y+dstRect.height-1-r)/(dstRect.height-1); 
					beta = 1 -alpha; 
					val =  (int)(val1*alpha + val2*beta + gama);  
					if(val<0) 
						val=0; 
					else if(val>255) 
						val=255; 
					((uchar*)(dst->imageData + dst->widthStep*r))[l*3+c] = (uchar)val; 
				} 
	} 
	else if(dst->nChannels==1) 
	{ 
		//留待实现 
	}        
}

//int main(int argc, char* argv[])
//{
//	IplImage* imgSrc= cvLoadImage("./t/20170301_141018.JPG");
//	IplImage* imgL = cvCreateImage(cvSize( imgSrc->width/2, imgSrc->height),  IPL_DEPTH_8U,3);
//	IplImage* imgR = cvCreateImage(cvSize( imgSrc->width/2, imgSrc->height),  IPL_DEPTH_8U,3);
//	fisheye_split(imgSrc, imgL, imgR);
//	//cvShowImage( "cvSLeft", imgLLD );
//	//cvSaveImage("SLeft.jpg", imgL);
//	//cvShowImage( "cvSRight", imgR );
//	//cvSaveImage("SRight.jpg", imgR);
//
//	Warper objWarper;
//	if (objWarper.init() < 0)
//		return 0;
//
//	IplImage* imgLD = cvCreateImage(cvSize( imgSrc->width* 19/ 36, imgSrc->height),  IPL_DEPTH_8U,3);
//	IplImage* imgRD = cvCreateImage(cvSize( imgSrc->width* 19/ 36, imgSrc->height),  IPL_DEPTH_8U,3);
//	float pL[3] = {726.4 /*+ 7*/,789.1, 710.5 * 17 / 18 -10};
//	float pR[3] = {768.7,755.8, 710.5 * 17 / 18 -10};
//	
//	CLImage_t clVertexL;
//	if (objWarper.allocImg(imgLD->width, imgLD->height, clVertexL) < 0)
//		return 0;
//	CLImage_t clVertexR;
//	if (objWarper.allocImg(imgRD->width, imgRD->height, clVertexR) < 0)
//		return 0;
//	
//	WarperParam stWarperParamL;
//	stWarperParamL.width = imgL->width;
//	stWarperParamL.height = imgL->height;
//	stWarperParamL.x = pL[0];
//	stWarperParamL.y = pL[1];
//	stWarperParamL.r = pL[2];
//	objWarper.genVertex(KERNEL_FISHEYE_TO_PANO, imgL, stWarperParamL, clVertexL);
//	objWarper.doMapGpu(imgL, imgLD, clVertexL);
//	cvShowImage("cvDLeft", imgLD);
//
//	WarperParam stWarperParamR;
//	stWarperParamR.width = imgR->width;
//	stWarperParamR.height = imgR->height;
//	stWarperParamR.x = pR[0];
//	stWarperParamR.y = pR[1];
//	stWarperParamR.r = pR[2];
//	objWarper.genVertex(KERNEL_FISHEYE_TO_PANO, imgR, stWarperParamR, clVertexR);
//	objWarper.doMapGpu(imgR, imgRD, clVertexR);
//	cvShowImage("cvDRight", imgRD);
//
//	//IplImage* imgLD2 = cvCreateImage(cvSize( imgSrc->width* 19/ 36, imgSrc->height),  IPL_DEPTH_8U,3);
//	//addWeighted(imgLD,imgRD,imgLD2);
//	//cvShowImage("cvDLeft2", imgLD2);
//	//cvWaitKey(0);
//
//	IplImage* g_imgDstQ = cvCreateImage(cvSize( imgSrc->width, imgSrc->height),  IPL_DEPTH_8U,3);
//	fisheye_stitch(imgSrc->width / 72, imgLD, imgRD, g_imgDstQ);
//	cvNamedWindow("cvDQ", CV_WINDOW_NORMAL);
//	cvResizeWindow("cvDQ", 1600,800);
//	cvShowImage("cvDQ", g_imgDstQ);
//	cvSaveImage("DstQ.jpg", g_imgDstQ);
//
//	//////display
//	IplImage* imgDst = cvCreateImage(cvSize( imgSrc->width / 2, imgSrc->height),  IPL_DEPTH_8U,3);
//	CLImage_t stCLShow;
//	if (objWarper.allocImg(imgDst->width, imgDst->height, stCLShow) < 0)
//		return 0;
//
//	WarperParam stShowPar;
//	stShowPar.width = imgDst->width;
//	stShowPar.height = imgDst->height;
//	stShowPar.r = imgDst->height / 2;
//	stShowPar.x = imgDst->width / 2;
//	stShowPar.y = imgDst->height / 2;
//	stShowPar.p = CV_PI;
//	stShowPar.t = CV_PI / 2;
//	stShowPar.z = stShowPar.r / 2;
//	if (objWarper.genVertex(KERNEL_PANO_TO_EQ, g_imgDstQ, stShowPar, stCLShow) < 0)
//		return -1;
//
//	if (objWarper.doMapGpu(g_imgDstQ, imgDst, stCLShow) < 0)
//		return -1;
//
//	cvNamedWindow("imgDst",CV_WINDOW_NORMAL);
//	cvResizeWindow("imgDst", 800, 800);
//	cvShowImage("imgDst", imgDst);
//
//	//////mouse
//	ShowParam_t stWarpPar;
//	stWarpPar.warpMode = KERNEL_PANO_TO_EQ;
//	stWarpPar.warper = &objWarper;
//	stWarpPar.stWarperPar = stShowPar;
//	stWarpPar.stVertex = stCLShow;
//	stWarpPar.srcImg = g_imgDstQ;
//	stWarpPar.dstImg = imgDst;
//	cvSetMouseCallback("imgDst", onMouse, (void*)&stWarpPar);
//	cvSaveImage("imgDst.jpg", imgDst);
//
//	cvWaitKey(0);
//	return 0;
//}