#ifndef LAYERDATA_H
#define LAYERDATA_H

typedef struct 
{
/* sequence header */
	int intra_quantizer_matrix[64], non_intra_quantizer_matrix[64];
	int chroma_intra_quantizer_matrix[64], chroma_non_intra_quantizer_matrix[64];
	int mpeg2;
	int qscale_type, altscan;      /* picture coding extension */
	int pict_scal;                /* picture spatial scalable extension */
	int scalable_mode;            /* sequence scalable extension */
} mpeg3_layerdata_t;


#endif
