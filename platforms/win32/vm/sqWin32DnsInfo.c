/* sqWin32DnsInfo.c: Gathers DNS information on Windows */
#include <Windows.h>
#include "sq.h"

extern struct VirtualMachine *interpreterProxy;
#define vm interpreterProxy

/* Large enough since we only use 3 entries with 1k bytes max */
#define RESULTBUFSIZE 20000
static char *buf = 0;

#define LOOKUPBUFSIZ 1000

static void
lookup(HKEY hk, char *key, char lkupbuf[LOOKUPBUFSIZ]) {
  DWORD dwLength = LOOKUPBUFSIZ - 1;
  lkupbuf[0] = 0;
  (void)RegQueryValueExA(hk, key, NULL, NULL, (BYTE *)lkupbuf, &dwLength);
  lkupbuf[dwLength] = 0;
}

/* Print base registry info. Return true if DNS info was provided. */
static int
printBaseInfo(char *hkeyName) {
  HKEY hkey;
  DWORD ret;
  int result = 0;
  char value[LOOKUPBUFSIZ];

  ret = RegOpenKeyExA(HKEY_LOCAL_MACHINE, hkeyName, 0, KEY_READ, &hkey);
  if (ret != ERROR_SUCCESS) {
    printf("RegOpenKeyExA failed\n");
    return vm->primitiveFail();
  }

  /* Provide Hostname info if present */
  lookup(hkey, "Hostname", value);
  if (value[0]) {
    strcat(buf, "\nhostname ");
    strcat(buf, value);
  }

  /* The list of suffixes to search */
  lookup(hkey, "SearchList", value);
  if (value[0]) {
    strcat(buf, "\nsearch ");
    strcat(buf, value);
  }

  /* The (static or dhcp) domain */
  lookup(hkey, "Domain", value);
  if (value[0]) {
    strcat(buf, "\ndomain ");
    strcat(buf, value);
    strcat(buf, " # static");
  } else {
    lookup(hkey, "DhcpDomain", value);
    if (value[0]) {
      strcat(buf, "\ndomain ");
      strcat(buf, value);
      strcat(buf, " # dhcp");
    }
  }

  /* And the (static or dhcp) configured name servers */
  lookup(hkey, "NameServer", value);
  if (value[0]) {
    strcat(buf, "\nnameserver ");
    strcat(buf, value);
    strcat(buf, " # static");
    result = 1;
  } else {
    lookup(hkey, "DhcpNameServer", value);
    if (value[0]) {
      strcat(buf, "\nnameserver ");
      strcat(buf, value);
      strcat(buf, " # dhcp");
      result = 1;
    }
  }
  RegCloseKey(hkey);
  return result;
}

static int
printAdapterInfo(char *hkeyName) {
  HKEY hkey;
  DWORD ret;
  int result = 0;
  char value[LOOKUPBUFSIZ];

  ret = RegOpenKeyExA(HKEY_LOCAL_MACHINE, hkeyName, 0, KEY_READ, &hkey);
  if (ret != ERROR_SUCCESS) {
    printf("RegOpenKeyExA failed\n");
    return vm->primitiveFail();
  }

  /* Provide interface address if present */
  lookup(hkey, "IPAddress", value);
  if (value[0] && strcmp(value, "0.0.0.0")) {
    /* Skip interface info since we can't currently determine
       if the information is correct or a dead adapter */
#if 0
    strcat(buf, "\ninterface ");
    strcat(buf, value);
    strcat(buf, " # static");
#endif
  } else {
    lookup(hkey, "DhcpIPAddress", value);
    if (value[0] && strcmp(value, "0.0.0.0")) {
#if 0
      strcat(buf, "\ninterface ");
      strcat(buf, value);
      strcat(buf, " # dhcp ");
#endif
    } else {
      /* Don't bother printing DNS for an adapter w/o IP */
      goto done;
    }
  }

  /* Print the (static or dhcp) configured name servers */
  lookup(hkey, "NameServer", value);
  if (value[0]) {
    strcat(buf, "\nnameserver ");
    strcat(buf, value);
    strcat(buf, " # static");
    result = 1;
  } else {
    lookup(hkey, "DhcpNameServer", value);
    if (value[0]) {
      strcat(buf, "\nnameserver ");
      strcat(buf, value);
      strcat(buf, " # dhcp");
      result = 1;
    }
  }

 done:
  RegCloseKey(hkey);
  return result;
}

#define BASE_KEY \
  "SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters\\Interfaces"

EXPORT(int) primitiveDnsInfo(void) {
  HKEY hkey;
  sqInt sz, stroop;
  DWORD dwLength, ret, index;
  char adapter[1024];

  if (!buf) {
	buf = malloc(RESULTBUFSIZE);
	if (!buf) {
	  vm->primitiveFailFor(PrimErrNoCMemory);
	  return 0;
	}
  }
  *buf = 0;
  strcat(buf, "# Global config settings");

  /* Print the global options */
  if (printBaseInfo("SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters"))
    /* If we have DNS entries globally, skip enumerating all interfaces */
    goto done;

  /* Enumerate the available interfaces */
  ret = RegOpenKeyExA(HKEY_LOCAL_MACHINE, BASE_KEY, 0, KEY_READ, &hkey);
  for(index=0;;index++) {
    char keyName[1024];
    dwLength = sizeof(adapter);
    ret = RegEnumKeyExA(hkey, index, adapter, &dwLength, NULL, NULL, NULL, NULL);
    if (ret != ERROR_SUCCESS) break;
    strcpy(keyName, BASE_KEY);
    strcat(keyName, "\\");
    strcat(keyName, adapter);
    /* Should look up and print the adapter name */
    printAdapterInfo(keyName);
  }

 done:
  sz = strlen(buf);
  stroop = vm->instantiateClassindexableSize(vm->classString(), sz);
  if (!vm->failed()) {
    memcpy(vm->firstIndexableField(stroop), buf, sz);
    vm->popthenPush(vm->methodArgumentCount()+1, stroop);
  }
  return 1;
}
