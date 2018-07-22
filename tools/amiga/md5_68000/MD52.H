typedef unsigned long uint32;

struct MD5Context {
	uint32 buf[4];
	uint32 bits[2];
	unsigned char in[64];
};

void MD5Init2(struct MD5Context *);
void MD5Update2(struct MD5Context *, unsigned char *buf, unsigned len);
void MD5Final2(unsigned char digest[16], struct MD5Context *);
void Transform2(uint32 buf[4], uint32 in[16]);
