/* sqWin32DnsInfo.c: Gathers DNS information on Windows */
#include <windows.h>
#include "sq.h"

extern struct VirtualMachine *interpreterProxy;
#define vm interpreterProxy

/* Large enough since we only use 3 entries with 1k bytes max */
static char buf[20000];

static char* lookup(HKEY hk, char *key) {
  static char buf[1000];
  DWORD dwLength, ret;
  dwLength = sizeof(buf)-1;
  *buf = 0;
  ret = RegQueryValueEx(hk, key, NULL, NULL, buf, &dwLength);
  if(buf[dwLength]) buf[dwLength] = 0;
  return buf;
}

/* Print base registry info. Return true if DNS info was provided. */
static int printBaseInfo(char *hkeyName) {
  HKEY hkey;
  DWORD ret;
  char *value;
  int result = 0;

  ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, hkeyName, 0, KEY_READ, &hkey);
  if(ret != ERROR_SUCCESS) {
    printf("RegOpenKeyEx failed\n");
    return vm->primitiveFail();
  }

  /* Provide Hostname info if present */
  value = lookup(hkey, "Hostname");
  if(*value) {
    strcat(buf, "\nhostname ");
    strcat(buf, value);
  }

  /* The list of suffixes to search */
  value = lookup(hkey, "SearchList");
  if(*value) {
    strcat(buf, "\nsearch ");
    strcat(buf, value);
  }

  /* The (static or dhcp) domain */
  value = lookup(hkey, "Domain");
  if(*value) {
    strcat(buf, "\ndomain ");
    strcat(buf, value);
    strcat(buf, " # static");
  } else {
    value = lookup(hkey, "DhcpDomain");
    if(*value) {
      strcat(buf, "\ndomain ");
      strcat(buf, value);
      strcat(buf, " # dhcp");
    }
  }

  /* And the (static or dhcp) configured name servers */
  value = lookup(hkey, "NameServer");
  if(*value) {
    strcat(buf, "\nnameserver ");
    strcat(buf, value);
    strcat(buf, " # static");
    result = 1;
  } else {
    value = lookup(hkey, "DhcpNameServer");
    if(*value) {
      strcat(buf, "\nnameserver ");
      strcat(buf, value);
      strcat(buf, " # dhcp");
      result = 1;
    }
  }
  RegCloseKey(hkey);
  return result;
}

static int printAdapterInfo(char *hkeyName) {
  HKEY hkey;
  DWORD ret;
  char *value;
  int result = 0;

  ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, hkeyName, 0, KEY_READ, &hkey);
  if(ret != ERROR_SUCCESS) {
    printf("RegOpenKeyEx failed\n");
    return vm->primitiveFail();
  }

  /* Provide interface address if present */
  value = lookup(hkey, "IPAddress");
  if(*value && strcmp(value, "0.0.0.0")) {
    /* Skip interface info since we can't currently determine
       if the information is correct or a dead adapter */
#if 0
    strcat(buf, "\ninterface ");
    strcat(buf, value);
    strcat(buf, " # static");
#endif
  } else {
    value = lookup(hkey, "DhcpIPAddress");
    if(*value && strcmp(value, "0.0.0.0")) {
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
  value = lookup(hkey, "NameServer");
  if(*value) {
    strcat(buf, "\nnameserver ");
    strcat(buf, value);
    strcat(buf, " # static");
    result = 1;
  } else {
    value = lookup(hkey, "DhcpNameServer");
    if(*value) {
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

  *buf = 0;
  strcat(buf, "# Global config settings");

  /* Print the global options */
  if(printBaseInfo("SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters")) {
    /* If we have DNS entries globally, skip enumerating all interfaces */
    goto done;
  }

  /* Enumerate the available interfaces */
  ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, BASE_KEY, 0, KEY_READ, &hkey);
  for(index=0;;index++) {
    char keyName[1024];
    dwLength = sizeof(adapter);
    ret = RegEnumKeyEx(hkey, index, adapter, &dwLength, NULL, NULL, NULL, NULL);
    if(ret != ERROR_SUCCESS) break;
    strcpy(keyName, BASE_KEY);
    strcat(keyName, "\\");
    strcat(keyName, adapter);
    /* Should look up and print the adapter name */
    printAdapterInfo(keyName);
  }

 done:
  sz = strlen(buf);
  stroop = vm->instantiateClassindexableSize(vm->classString(), sz);
  if(!vm->failed()) {
    memcpy(vm->firstIndexableField(stroop), buf, sz);
    vm->popthenPush(vm->methodArgumentCount()+1, stroop);
  }
  return 1;
}
