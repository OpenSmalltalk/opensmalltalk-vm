typedef struct {
  void *a, *b, *c;
} sqExport;

#define disabled(NAME) sqExport NAME##_exports = { 0, 0, 0 };
