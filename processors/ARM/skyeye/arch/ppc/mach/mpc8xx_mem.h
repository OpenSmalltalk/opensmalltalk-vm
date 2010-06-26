#define CS0 (0)
#define CS1 (1)
#define CS2 (2)
#define CS3 (3)
#define CS4 (4)
#define CS5 (5)
#define CS6 (6)
#define CS7 (7)

#define SPR_IMMR (638)
/* Internal space base */
#define IMMR_ISB(immr) ((immr) & 0xffff0000);
#define IMMR_PARTNUM(immr) (((immr)&0xff00)>>8)
#define IMMR_MASKNUM(immr) (((immr)&0xff))
typedef struct MPC8xx_MemCo MPC8xx_MemCo;

MPC8xx_MemCo * MPC8xx_MemController_New();
void MPC8xx_RegisterDevice(MPC8xx_MemCo *memco,BusDevice *bdev,uint32_t cs);
