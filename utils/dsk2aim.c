#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  char *dest="test.aim";
  char *source="test.dsk";
  FILE *sp;
  FILE *sop;
  const unsigned short prefix0 = 0x00AA;
  const unsigned short prefix1[4] = {0x0100,0x0095,0x006A,0x00FE};
  const unsigned short prefix2[4] = {0x005A,0x00AA,0x00AA,0x00AA};
  const unsigned short prefix3[3] = {0x0100,0x006A,0x0095};
  unsigned short crc = 0x00dd;
  unsigned char rb=0;
  unsigned short rbb=0;
  if(argc<3){
    printf("dsk2aim it is program converts from dsk to aim format (Only Soviet Agate, 840 kB disks)\n");
    printf("Example: dsk2aim source destination\n");
    return -1;
  }
  dest = argv[2];
  source = argv[1];
  printf("Start..\r");
  sp=fopen(dest,"wb+");
  if(sp==NULL){
    printf("File destination %s not open! Error!\n",dest);
    printf("Error!\n");
    return -1;
    }
  sop=fopen(source,"rb");
  if(sop==NULL){
    fclose(sop);
    printf("File source %s not open! Error!\n",source);
    printf("Error!\n");
    return -1;
    }
    
  fseek(sop, 0, SEEK_END);
  unsigned long len = (unsigned long)ftell(sop);
  if(len!=860160){
    fclose(sp);
    fclose(sop);
    printf("File source %s not dsk-file! Size %s:%ld != 860160 bytes\n",source,source,len);
    printf("Error!\n");
    return -1;
  }
  
  fseek(sp, 0, SEEK_SET);
  fseek(sop, 0, SEEK_SET);
  for(unsigned short track = 0; track < 160; track++)
  {
    for(unsigned short sec = 0; sec <21 ;sec ++)
    {
      for(int i=0;i<0x14;i++)
        fwrite(&prefix0,2,1,sp);
      fwrite(&prefix1,2*4,1,sp);
      fwrite(&track,2,1,sp);
      fwrite(&sec,2,1,sp);
      fwrite(&prefix2,2*4,1,sp);
      fwrite(&prefix3,2*3,1,sp);
      crc=0;
      for(unsigned short bt=0;bt<256;bt++)
      {
        fread(&rb,1,1,sop);
        if(crc>255){crc++;crc&=255;}
        crc+=rb;
        rbb=rb;
        fwrite(&rbb,2,1,sp);
      }
      crc&=255;
      fwrite(&crc,2,1,sp);
      fwrite(&prefix2,2*4,1,sp);
      for(int i=0;i<0xC;i++)
        fwrite(&prefix0,2,1,sp);
    }
    for(int i=0;i<38;i++)
        fwrite(&prefix0,2,1,sp);
  }
  fclose(sp);
  fclose(sop);
  printf("Complete!\n");
  return 0;
}
