//
//  testapp.c
//  
//
//  Created by admin on 1/19/15.
//
//

#include "testapp.h"
#include "stdio.h"
#include "stdlib.h"

void testupscale(int argc, char * argv[])
{
    unsigned char *inp_image, *out_image;
    unsigned int inp_width, inp_height,out_width,out_height;
    FILE* fp_input, *fp_output;
    unsigned long ret;
    
    inp_height = 720;
    inp_width = 1280;
    out_height = 1080;
    out_width = 1920;
   
    fp_input = fopen("/sdcard/input_grey.raw","rb");
    fp_output = fopen("/data/local/tmp/output_grey.yuv","wb");
    
    inp_image = (unsigned char *) malloc(inp_height*inp_width*sizeof(unsigned char));
    out_image = (unsigned char *) malloc(out_height*out_width*sizeof(unsigned char));
    
    ret = fread(inp_image,1,sizeof(unsigned char)*inp_height*inp_width,fp_input);
    
    upscale(inp_image,out_image,inp_width,inp_height,out_width,out_height);

    
    ret = fwrite(out_image,1,sizeof(unsigned char)*out_height*out_width,fp_output);
    
}



