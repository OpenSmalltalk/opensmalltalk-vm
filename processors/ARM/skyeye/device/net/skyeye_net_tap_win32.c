/*
 *  TAP-Win32 -- A kernel driver to provide virtual tap device functionality
 *               on Windows.  Originally derived from the CIPE-Win32
 *               project by Damion K. Wilson, with extensive modifications by
 *               James Yonan.
 *
 *  All source code which derives from the CIPE-Win32 project is
 *  Copyright (C) Damion K. Wilson, 2003, and is released under the
 *  GPL version 2 (see below).
 *
 *  All other source code is Copyright (C) James Yonan, 2003-2004,
 *  and is released under the GPL version 2 (see below).
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program (see the file COPYING included with this
 *  distribution); if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/* modified by Anthony Lee 2007.1.6 : for SkyEye to work on MinGW/CygWin */

#include "skyeye_net.h"
#undef WORD
#undef byte

#include <process.h>
#include <windows.h>

#include <ddk/ntapi.h>
#include <ddk/winddk.h>
#include <ddk/ntddk.h>

#define TAP_CONTROL_CODE(request,method)	CTL_CODE(FILE_DEVICE_UNKNOWN, request, method, FILE_ANY_ACCESS)
#define TAP_IOCTL_GET_MAC			TAP_CONTROL_CODE(1, METHOD_BUFFERED)
#define TAP_IOCTL_GET_VERSION			TAP_CONTROL_CODE(2, METHOD_BUFFERED)
#define TAP_IOCTL_GET_MTU			TAP_CONTROL_CODE(3, METHOD_BUFFERED)
#define TAP_IOCTL_GET_INFO			TAP_CONTROL_CODE(4, METHOD_BUFFERED)
#define TAP_IOCTL_CONFIG_POINT_TO_POINT		TAP_CONTROL_CODE(5, METHOD_BUFFERED)
#define TAP_IOCTL_SET_MEDIA_STATUS		TAP_CONTROL_CODE(6, METHOD_BUFFERED)
#define TAP_IOCTL_CONFIG_DHCP_MASQ		TAP_CONTROL_CODE(7, METHOD_BUFFERED)
#define TAP_IOCTL_GET_LOG_LINE			TAP_CONTROL_CODE(8, METHOD_BUFFERED)
#define TAP_IOCTL_CONFIG_DHCP_SET_OPT		TAP_CONTROL_CODE(9, METHOD_BUFFERED)

#define ADAPTER_KEY				"SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
#define NETWORK_CONNECTIONS_KEY			"SYSTEM\\CurrentControlSet\\Control\\Network\\{4D36E972-E325-11CE-BFC1-08002BE10318}"

#define USERMODEDEVICEDIR			"\\\\.\\Global\\"
#define TAPSUFFIX				".tap"

#define TAP_WIN32_MIN_MAJOR			7
#define TAP_WIN32_MIN_MINOR			1

#define TAP_BUFFER_SIZE				1560

#define printm(s...)				fprintf(stderr, "[TAP-WIN32]: "s)


typedef struct tap_win32 {
	HANDLE fHandle;
	HANDLE fEvent;

	unsigned char fBuffer[TAP_BUFFER_SIZE];
	DWORD fBufferLen;

	CRITICAL_SECTION fLocker;
	BOOL fReading;
	OVERLAPPED fOverlapped;
	OVERLAPPED fOverlappedOut;
} tap_win32;


static void ShowErrorMsg(const char *prefix)
{
	char errmsg[1024] = "\0";

	if(prefix == NULL) prefix = "";
	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, NULL,
		      GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		      errmsg, 1024, NULL);

	printm("%s --- %s\n", prefix, errmsg);
}


static int is_tap_win32_dev(const char *guid)
{
	HKEY netcard_key;
	LONG status;
	DWORD len;
	int i, found = -1;

	char enum_name[256];
	char unit_string[256];
	HKEY unit_key;
	char component_id_string[] = "ComponentId";
	char component_id[256];
	char net_cfg_instance_id_string[] = "NetCfgInstanceId";
	char net_cfg_instance_id[256];
	DWORD data_type;

	if(RegOpenKeyEx(HKEY_LOCAL_MACHINE, ADAPTER_KEY, 0, KEY_READ, &netcard_key) != ERROR_SUCCESS) return -1;

	for(i = 0; found < 0; i++)
	{
		len = sizeof(enum_name);
		if(RegEnumKeyEx(netcard_key, i, enum_name, &len, NULL, NULL, NULL, NULL) != ERROR_SUCCESS) break;

		snprintf(unit_string, sizeof(unit_string), "%s\\%s", ADAPTER_KEY, enum_name);
		if(RegOpenKeyEx(HKEY_LOCAL_MACHINE, unit_string, 0, KEY_READ, &unit_key) != ERROR_SUCCESS) break;

		len = sizeof(component_id);
		if(RegQueryValueEx(unit_key, component_id_string, NULL,
				   &data_type, component_id, &len) == ERROR_SUCCESS && data_type == REG_SZ)
		{
			len = sizeof(net_cfg_instance_id);
			if(RegQueryValueEx(unit_key, net_cfg_instance_id_string, NULL,
					   &data_type, net_cfg_instance_id, &len) == ERROR_SUCCESS && data_type == REG_SZ)
			{
				if(strncmp(component_id, "tap", 3) == 0 && strcmp(net_cfg_instance_id, guid) == 0) found = i;
			}
		}

		RegCloseKey(unit_key);
	}

	RegCloseKey(netcard_key);

	return(found < 0 ? -1 : 0);
}


static int get_device_guid(char *name, int name_size, char *actual_name, int actual_name_size)
{
	HKEY control_net_key;
	DWORD len;
	int i, found = -1;

	char enum_name[256];
	char connection_string[256];
	HKEY connection_key;
	char name_data[256];
	DWORD name_type;
	const char name_string[] = "Name";

	if(RegOpenKeyEx(HKEY_LOCAL_MACHINE, NETWORK_CONNECTIONS_KEY, 0, KEY_READ, &control_net_key) != ERROR_SUCCESS)
	{
		printm("Error opening registry key: %s\n", NETWORK_CONNECTIONS_KEY);
		return -1;
	}

	for(i = 0; found < 0; i++)
	{
		len = sizeof(enum_name);
		if(RegEnumKeyEx(control_net_key, i, enum_name, &len, NULL, NULL, NULL, NULL) != ERROR_SUCCESS)
		{
			printm("Error enumerating registry subkeys of key: %s\n", NETWORK_CONNECTIONS_KEY);
			break;
		}

		snprintf(connection_string, sizeof(connection_string), "%s\\%s\\Connection", NETWORK_CONNECTIONS_KEY, enum_name);
		if(RegOpenKeyEx(HKEY_LOCAL_MACHINE, connection_string, 0, KEY_READ, &connection_key) != ERROR_SUCCESS) continue;

		len = sizeof(name_data);
		if(!(RegQueryValueEx(connection_key, name_string, NULL, &name_type, (BYTE *)name_data, &len) != ERROR_SUCCESS ||
		     name_type != REG_SZ || is_tap_win32_dev(enum_name) != 0))
		{
			printm("Found TAP device named '%s'\n", name_data);
			snprintf(name, name_size, "%s", enum_name);
			if(actual_name) snprintf(actual_name, actual_name_size, "\"%s\"", name_data);
			found = i;
		}

		RegCloseKey(connection_key);
	}

	RegCloseKey(control_net_key);

	return(found < 0 ? -1 : 0);
}


static int initDevice(struct net_device *net_dev)
{
	char device_path[256];
	char device_guid[0x100];
	char device_name[1024];

	ULONG tapVer[3];
	ULONG len = 0;

	tap_win32 *dev = (net_dev ? (tap_win32*)(net_dev->priv) : NULL);
	if(dev == NULL) return -1;
	bzero(dev, sizeof(tap_win32));

	if(get_device_guid(device_guid, sizeof(device_guid), device_name, sizeof(device_name)) != 0)
	{
		printm("ERROR: SkyEye requires a TAP-Win32 driver that is at least version %d.%d\n"
		       "Please install from http://prdownloads.sourceforge.net/openvpn/openvpn-2.0_beta2-install.exe\n",
		       TAP_WIN32_MIN_MAJOR, TAP_WIN32_MIN_MINOR);
		return -1;
	}

	if(GetVersion() < 0x80000000)
	{
		char hostip[16];

		sprintf(hostip, "%d.%d.%d.%d",
			net_dev->hostip[0], net_dev->hostip[1], net_dev->hostip[2], net_dev->hostip[3]);

		if(_spawnlp(_P_DETACH, "netsh.exe", "netsh.exe",
			    "interface", "ip", "set", "address", device_name,
			    "static", hostip, "255.255.255.0", NULL) == -1)
		{
			printm("WARNING: Failed to Change IP Address/Mask.\n");
		}
	}

	snprintf(device_path, sizeof(device_path), "%s%s%s", USERMODEDEVICEDIR, device_guid, TAPSUFFIX);

	dev->fHandle = CreateFile(device_path,
				  GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
				  NULL, OPEN_EXISTING,
				  FILE_ATTRIBUTE_SYSTEM | FILE_FLAG_OVERLAPPED, NULL);
	if(dev->fHandle == INVALID_HANDLE_VALUE)
	{
		printm("Opening TAP connection failed\n");
		return -1;
	}

	bzero(&tapVer[0], sizeof(tapVer));
	if(!DeviceIoControl(dev->fHandle, TAP_IOCTL_GET_VERSION,
			    &tapVer[0], sizeof(tapVer), &tapVer[0], sizeof(tapVer), &len, NULL))
	{
		ShowErrorMsg("Could not get driver version info");
		CloseHandle(dev->fHandle);
		return -1;
	}
	if(!(tapVer[0] > TAP_WIN32_MIN_MAJOR || (tapVer[0] == TAP_WIN32_MIN_MAJOR && tapVer[1] >= TAP_WIN32_MIN_MINOR)))
	{
		printm("ERROR: SkyEye requires a TAP-Win32 driver that is at least version %d.%d\n"
		       "Please install an updated version from http://prdownloads.sourceforge.net/openvpn/openvpn-2.0_beta2-install.exe\n",
		       TAP_WIN32_MIN_MAJOR, TAP_WIN32_MIN_MINOR);
		CloseHandle(dev->fHandle);
		return -1;
	}

	tapVer[0] = 1;
	if(!DeviceIoControl(dev->fHandle, TAP_IOCTL_SET_MEDIA_STATUS,
			    &tapVer[0], sizeof(ULONG), &tapVer[0], sizeof(ULONG), &len, NULL))
	{
		ShowErrorMsg("Setting Media Status to connected failed");
		CloseHandle(dev->fHandle);
		return -1;
	}

	InitializeCriticalSection(&dev->fLocker);
	dev->fEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	return 0;
}


static int shutdownDevice(struct net_device *net_dev)
{
	tap_win32 *dev = (net_dev ? (tap_win32*)(net_dev->priv) : NULL);
	if(dev == NULL) return -1;

	printm("Closing TAP-WIN32 handle.\n");

	CloseHandle(dev->fHandle);
	CloseHandle(dev->fEvent);
	DeleteCriticalSection(&dev->fLocker);

	net_dev->priv = NULL;

	return 0;
}


static int recvPacket(tap_win32 *dev, void *buf, int size)
{
	int retVal = 0;

	if(size < 0) return -1;

	EnterCriticalSection(&dev->fLocker);

	if(dev->fReading == FALSE)
	{
		if(dev->fBufferLen > (DWORD)size)
		{
			/* no partial packets. drop it. */
			retVal = 0;
		}
		else if(dev->fBufferLen > 0)
		{
			memcpy(buf, &dev->fBuffer[0], (size_t)dev->fBufferLen);
			retVal = (int)dev->fBufferLen;
		}

		dev->fBufferLen = 0;
	}

	LeaveCriticalSection(&dev->fLocker);

	return retVal;
}


static void CALLBACK waitRecvPacket_callback(DWORD dwErrorCode, DWORD dwNumberOfBytesTransfered, LPOVERLAPPED lpOverlapped)
{
	tap_win32 *dev = (tap_win32*)lpOverlapped->hEvent;
	if(dev == NULL) return;

	EnterCriticalSection(&dev->fLocker);

	dev->fReading = FALSE;
	dev->fBufferLen = (dwErrorCode == 0 ? dwNumberOfBytesTransfered : 0);
	SetEvent(dev->fEvent);

	LeaveCriticalSection(&dev->fLocker);
}


static int waitRecvPacket(tap_win32 *dev, struct timeval *tv)
{
	int retVal = 0;
	DWORD status;

	EnterCriticalSection(&dev->fLocker);

	if(dev->fReading)
	{
		retVal = -1;
	}
	else if(dev->fBufferLen == 0)
	{
		retVal = -1;

		dev->fReading = TRUE;
		dev->fOverlapped.Internal = 0;
		dev->fOverlapped.InternalHigh = 0;
		dev->fOverlapped.Offset = 0;
		dev->fOverlapped.OffsetHigh = 0;
		dev->fOverlapped.hEvent = dev;
		ResetEvent(dev->fEvent);

		if(ReadFileEx(dev->fHandle, &dev->fBuffer[0], TAP_BUFFER_SIZE,
			      &dev->fOverlapped, waitRecvPacket_callback) == 0)
		{
			ShowErrorMsg("ReadFileEx error");
			dev->fReading = FALSE;
			retVal = -2;
		}
	}

	LeaveCriticalSection(&dev->fLocker);

	if(retVal == -1)
	{
		DWORD timeout = (tv == NULL ? INFINITE : (DWORD)(tv->tv_sec * 1000UL + tv->tv_usec / 1000UL));
		while(TRUE)
		{
			status = WaitForSingleObjectEx(dev->fEvent, timeout, TRUE);
			if(status == WAIT_IO_COMPLETION && tv == NULL) continue;
			if(status == WAIT_OBJECT_0) retVal = 0;
			break;
		}
	}

	return retVal;
}


static int sendPacket(tap_win32 *dev, void *buf, int size)
{
	DWORD written = 0;

	if(WriteFile(dev->fHandle, buf, (DWORD)size, &written, &dev->fOverlappedOut) == 0)
	{
		char errmsg[1024];
		DWORD errCode = GetLastError();

		snprintf(errmsg, sizeof(errmsg), "Sending of %d bytes failed (%u bytes sent)", size, written);
		ShowErrorMsg(errmsg);
	}

	return (int)written;
}


int tuntap_open(struct net_device *net_dev)
{
	net_dev->priv = LocalAlloc(LMEM_ZEROINIT, sizeof(tap_win32));

	if(initDevice(net_dev) != 0)
	{
		if(net_dev->priv) LocalFree(net_dev->priv);
		net_dev->priv = NULL;
		return -1;
	}

	return 0;
}


int tuntap_close(struct net_device *net_dev)
{
	shutdownDevice(net_dev);
	if(net_dev->priv) LocalFree(net_dev->priv);
	net_dev->priv = NULL;
	return 0;
}


int tuntap_read(struct net_device *net_dev, void *buf, size_t count)
{
	if(net_dev->priv == NULL) return -1;
	return recvPacket((tap_win32*)net_dev->priv, buf, count);
}


int tuntap_write(struct net_device *net_dev, void *buf, size_t count)
{
	if(net_dev->priv == NULL) return -1;
	return sendPacket((tap_win32*)net_dev->priv, buf, count);
}


int tuntap_wait_packet(struct net_device *net_dev, struct timeval *tv)
{
	if(net_dev->priv == NULL) return -1;
	return waitRecvPacket((tap_win32*)net_dev->priv, tv);
}
