/////////////////////////////////////////////////////////////////////////
// $Id: win32dialog.cc,v 1.62 2008/02/05 22:57:41 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////

#include "config.h"

#if BX_USE_TEXTCONFIG && defined(WIN32)

extern "C" {
#include <assert.h>
#include <stdio.h>
#include <windows.h>
#include <commctrl.h>
#include <shlobj.h>
#include <ctype.h>
}
#include "win32res.h"
#include "siminterface.h"
#include "textconfig.h"
#include "win32dialog.h"

const char log_choices[5][16] = {"ignore", "log", "ask user", "end simulation", "no change"};
static int retcode = 0;
static bxevent_handler old_callback = NULL;
static void *old_callback_arg = NULL;
#if BX_DEBUGGER
static HWND hDebugDialog = NULL;
static char *debug_cmd = NULL;
static BOOL debug_cmd_ready = FALSE;
static BOOL showCPU = FALSE;
static bx_param_num_c *cpu_param[16];
#endif

int AskFilename(HWND hwnd, bx_param_filename_c *param, const char *ext);

char *backslashes(char *s)
{
  if (s != NULL) {
    while (*s != 0) {
       if (*s == '/') *s = '\\';
       s++;
    }
  }
  return s;
}

HWND GetBochsWindow()
{
  HWND hwnd;

  hwnd = FindWindow("Bochs for Windows", NULL);
  if (hwnd == NULL) {
    hwnd = GetForegroundWindow();
  }
  return hwnd;
}

BOOL CreateImage(HWND hDlg, int sectors, const char *filename)
{
  if (sectors < 1) {
    MessageBox(hDlg, "The disk size is invalid.", "Invalid size", MB_ICONERROR);
    return FALSE;
  }
  if (lstrlen(filename) < 1) {
    MessageBox(hDlg, "You must type a file name for the new disk image.", "Bad filename", MB_ICONERROR);
    return FALSE;
  }
  int ret = SIM->create_disk_image (filename, sectors, 0);
  if (ret == -1) {  // already exists
    int answer = MessageBox(hDlg, "File exists.  Do you want to overwrite it?",
                            "File exists", MB_YESNO);
    if (answer == IDYES)
      ret = SIM->create_disk_image (filename, sectors, 1);
    else
      return FALSE;
  }
  if (ret == -2) {
    MessageBox(hDlg, "I could not create the disk image. Check for permission problems or available disk space.", "Failed", MB_ICONERROR);
    return FALSE;
  }
  return TRUE;
}

int CALLBACK BrowseCallbackProc(HWND hwnd, UINT uMsg, LPARAM lParam, LPARAM lpData)
{
  char path[MAX_PATH];

  if (uMsg == BFFM_INITIALIZED) {
    GetCurrentDirectory(MAX_PATH, path);
    SendMessage(hwnd, BFFM_SETSELECTION, TRUE, (LPARAM)path);
  }
  return 0;
}

#ifndef BIF_NEWDIALOGSTYLE
#define BIF_NEWDIALOGSTYLE 0
#endif

int BrowseDir(const char *Title, char *result)
{
  BROWSEINFO browseInfo;
  LPITEMIDLIST ItemIDList;
  int r = -1;

  memset(&browseInfo,0,sizeof(BROWSEINFO));
  browseInfo.hwndOwner = GetActiveWindow();
  browseInfo.pszDisplayName = result;
  browseInfo.lpszTitle = (LPCSTR)Title;
  browseInfo.ulFlags = BIF_NEWDIALOGSTYLE | BIF_RETURNONLYFSDIRS;
  browseInfo.lpfn = BrowseCallbackProc;
  ItemIDList = SHBrowseForFolder(&browseInfo);
  if (ItemIDList != NULL) {
    *result = 0;
    if (SHGetPathFromIDList(ItemIDList, result)) {
      if (result[0]) r = 0;
    }
    // free memory used
    IMalloc * imalloc = 0;
    if (SUCCEEDED(SHGetMalloc(&imalloc))) {
      imalloc->Free(ItemIDList);
      imalloc->Release();
    }
  }
  return r;
}

static BOOL CALLBACK LogAskProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  BxEvent *event;
  int level;

  switch (msg) {
    case WM_INITDIALOG:
      event = (BxEvent*)lParam;
      level = event->u.logmsg.level;
      SetWindowText(hDlg, SIM->get_log_level_name(level));
      SetWindowText(GetDlgItem(hDlg, IDASKDEV), event->u.logmsg.prefix);
      SetWindowText(GetDlgItem(hDlg, IDASKMSG), event->u.logmsg.msg);
      SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_ADDSTRING, 0, (LPARAM)"Continue");
      SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_ADDSTRING, 0, (LPARAM)"Continue and don't ask again");
      SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_ADDSTRING, 0, (LPARAM)"Kill simulation");
      SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_ADDSTRING, 0, (LPARAM)"Abort (dump core)");
#if BX_DEBUGGER
      SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_ADDSTRING, 0, (LPARAM)"Continue and return to debugger");
#endif
      SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_SETCURSEL, 2, 0);
      SetFocus(GetDlgItem(hDlg, IDASKLIST));
      return FALSE;
    case WM_CLOSE:
      EndDialog(hDlg, BX_LOG_ASK_CHOICE_DIE);
      break;
    case WM_COMMAND:
      switch (LOWORD(wParam)) {
        case IDOK:
          EndDialog(hDlg, SendMessage(GetDlgItem(hDlg, IDASKLIST), LB_GETCURSEL, 0, 0));
          break;
        case IDCANCEL:
          EndDialog(hDlg, BX_LOG_ASK_CHOICE_DIE);
          break;
      }
  }
  return FALSE;
}

static BOOL CALLBACK StringParamProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static bx_param_string_c *param;
  char buffer[512];
  const char *title;

  switch (msg) {
    case WM_INITDIALOG:
      param = (bx_param_string_c *)lParam;
      title = param->get_label();
      if ((title == NULL) || (strlen(title) == 0)) {
        title = param->get_name();
      }
      SetWindowText(hDlg, title);
      SetWindowText(GetDlgItem(hDlg, IDSTRING), param->getptr());
      SendMessage(GetDlgItem(hDlg, IDSTRING), EM_SETLIMITTEXT, param->get_maxsize(), 0);
      return TRUE;
      break;
    case WM_CLOSE:
      EndDialog(hDlg, -1);
      break;
    case WM_COMMAND:
      switch (LOWORD(wParam)) {
        case IDOK:
          GetDlgItemText(hDlg, IDSTRING, buffer, param->get_maxsize() + 1);
          param->set(buffer);
          EndDialog(hDlg, 1);
          break;
        case IDCANCEL:
          EndDialog(hDlg, -1);
          break;
      }
  }
  return FALSE;
}

static BOOL CALLBACK FloppyDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static bx_param_filename_c *param;
  static bx_param_enum_c *status;
  static bx_param_enum_c *devtype;
  static bx_param_enum_c *mediatype;
  static char origpath[MAX_PATH];
  char mesg[MAX_PATH];
  char path[MAX_PATH];
  char pname[80];
  const char *title;
  int i, cap;

  switch (msg) {
    case WM_INITDIALOG:
      param = (bx_param_filename_c *)lParam;
      param->get_param_path(pname, 80);
      if (!strcmp(pname, BXPN_FLOPPYA_PATH)) {
        status = SIM->get_param_enum(BXPN_FLOPPYA_STATUS);
        devtype = SIM->get_param_enum(BXPN_FLOPPYA_DEVTYPE);
        mediatype = SIM->get_param_enum(BXPN_FLOPPYA_TYPE);
      } else {
        status = SIM->get_param_enum(BXPN_FLOPPYB_STATUS);
        devtype = SIM->get_param_enum(BXPN_FLOPPYB_DEVTYPE);
        mediatype = SIM->get_param_enum(BXPN_FLOPPYB_TYPE);
      }
      cap = devtype->get() - (int)devtype->get_min();
      SetWindowText(GetDlgItem(hDlg, IDDEVTYPE), floppy_type_names[cap]);
      i = 0;
      while (floppy_type_names[i] != NULL) {
        SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_ADDSTRING, 0, (LPARAM)floppy_type_names[i]);
        SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_SETITEMDATA, i, (LPARAM)(mediatype->get_min() + i));
        i++;
      }
      cap = mediatype->get() - (int)mediatype->get_min();
      SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_SETCURSEL, cap, 0);
      if (status->get() == BX_INSERTED) {
        SendMessage(GetDlgItem(hDlg, IDSTATUS), BM_SETCHECK, BST_CHECKED, 0);
      }
      lstrcpy(origpath, param->getptr());
      title = param->get_label();
      if (!title) title = param->get_name();
      SetWindowText(hDlg, title);
      if (lstrlen(origpath) && lstrcmp(origpath, "none")) {
        SetWindowText(GetDlgItem(hDlg, IDPATH), origpath);
      }
      return TRUE;
      break;
    case WM_CLOSE:
      GetDlgItemText(hDlg, IDPATH, path, MAX_PATH);
      if (lstrcmp(path, origpath)) {
        param->set(origpath);
      }
      EndDialog(hDlg, -1);
      return TRUE;
      break;
    case WM_COMMAND:
      switch (LOWORD(wParam)) {
        case IDBROWSE:
          GetDlgItemText(hDlg, IDPATH, path, MAX_PATH);
          param->set(backslashes(path));
          if (AskFilename(hDlg, param, "img") > 0) {
            SetWindowText(GetDlgItem(hDlg, IDPATH), param->getptr());
            SendMessage(GetDlgItem(hDlg, IDSTATUS), BM_SETCHECK, BST_CHECKED, 0);
            SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_SELECTSTRING, (WPARAM)-1, (LPARAM)"auto");
            EnableWindow(GetDlgItem(hDlg, IDCREATE), FALSE);
          }
          return TRUE;
          break;
        case IDOK:
          status->set(BX_EJECTED);
          if (SendMessage(GetDlgItem(hDlg, IDSTATUS), BM_GETCHECK, 0, 0) == BST_CHECKED) {
            GetDlgItemText(hDlg, IDPATH, path, MAX_PATH);
            if (lstrlen(path) == 0) {
              lstrcpy(path, "none");
            }
          } else {
            lstrcpy(path, "none");
          }
          param->set(path);
          i = SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_GETCURSEL, 0, 0);
          cap = SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_GETITEMDATA, i, 0);
          mediatype->set(cap);
          if (lstrcmp(path, "none")) {
            status->set(BX_INSERTED);
          }
          EndDialog(hDlg, 1);
          return TRUE;
          break;
        case IDCANCEL:
          GetDlgItemText(hDlg, IDPATH, path, MAX_PATH);
          if (lstrcmp(path, origpath)) {
            param->set(origpath);
          }
          EndDialog(hDlg, -1);
          return TRUE;
          break;
        case IDMEDIATYPE:
          if (HIWORD(wParam) == CBN_SELCHANGE) {
            i = SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_GETCURSEL, 0, 0);
            EnableWindow(GetDlgItem(hDlg, IDCREATE), (floppy_type_n_sectors[i] > 0));
          }
          break;
        case IDCREATE:
          GetDlgItemText(hDlg, IDPATH, path, MAX_PATH);
          backslashes(path);
          i = SendMessage(GetDlgItem(hDlg, IDMEDIATYPE), CB_GETCURSEL, 0, 0);
          if (CreateImage(hDlg, floppy_type_n_sectors[i], path)) {
            wsprintf(mesg, "Created a %s disk image called %s", floppy_type_names[i], path);
            MessageBox(hDlg, mesg, "Image created", MB_OK);
          }
          return TRUE;
          break;
      }
  }
  return FALSE;
}

static BOOL CALLBACK Cdrom1DlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static bx_list_c *cdromop;
  int device;
  static char origpath[MAX_PATH];
  char path[MAX_PATH];

  switch (msg) {
    case WM_INITDIALOG:
      SIM->get_cdrom_options(0, &cdromop, &device);
      lstrcpy(origpath, SIM->get_param_string("path", cdromop)->getptr());
      if (lstrlen(origpath) && lstrcmp(origpath, "none")) {
        SetWindowText(GetDlgItem(hDlg, IDCDROM1), origpath);
      }
      if (SIM->get_param_enum("status", cdromop)->get() == BX_INSERTED) {
        SendMessage(GetDlgItem(hDlg, IDSTATUS1), BM_SETCHECK, BST_CHECKED, 0);
      }
      return TRUE;
      break;
    case WM_CLOSE:
      if (lstrcmp(SIM->get_param_string("path", cdromop)->getptr(), origpath)) {
        SIM->get_param_string("path", cdromop)->set(origpath);
      }
      EndDialog(hDlg, -1);
      break;
    case WM_COMMAND:
      switch (LOWORD(wParam)) {
        case IDBROWSE1:
          GetDlgItemText(hDlg, IDCDROM1, path, MAX_PATH);
          SIM->get_param_string("path", cdromop)->set(backslashes(path));
          if (AskFilename(hDlg, (bx_param_filename_c *)SIM->get_param_string("path", cdromop), "iso") > 0) {
            SetWindowText(GetDlgItem(hDlg, IDCDROM1), SIM->get_param_string("path", cdromop)->getptr());
            SendMessage(GetDlgItem(hDlg, IDSTATUS1), BM_SETCHECK, BST_CHECKED, 0);
          }
          break;
        case IDOK:
          if (SendMessage(GetDlgItem(hDlg, IDSTATUS1), BM_GETCHECK, 0, 0) == BST_CHECKED) {
            GetDlgItemText(hDlg, IDCDROM1, path, MAX_PATH);
            if (lstrlen(path)) {
              SIM->get_param_enum("status", cdromop)->set(BX_INSERTED);
              if (lstrcmp(path, SIM->get_param_string("path", cdromop)->getptr())) {
                SIM->get_param_string("path", cdromop)->set(path);
              }
            } else {
              SIM->get_param_enum("status", cdromop)->set(BX_EJECTED);
            }
          } else {
            SIM->get_param_enum("status", cdromop)->set(BX_EJECTED);
          }
          EndDialog(hDlg, 1);
          break;
        case IDCANCEL:
          if (lstrcmp(SIM->get_param_string("path", cdromop)->getptr(), origpath)) {
            SIM->get_param_string("path", cdromop)->set(origpath);
          }
          EndDialog(hDlg, -1);
          break;
      }
  }
  return FALSE;
}

void RuntimeDlgSetStdLogOpt(HWND hDlg)
{
  int level, idx;
  int defchoice[5];

  for (level=0; level<5; level++) {
    int mod = 0;
    int first = SIM->get_log_action (mod, level);
    BOOL consensus = true;
    // now compare all others to first.  If all match, then use "first" as
    // the initial value.
    for (mod=1; mod<SIM->get_n_log_modules(); mod++) {
      if (first != SIM->get_log_action (mod, level)) {
        consensus = false;
        break;
      }
    }
    if (consensus)
      defchoice[level] = first;
    else
      defchoice[level] = 4;
  }
  for (level=0; level<5; level++) {
    idx = 0;
    SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_RESETCONTENT, 0, 0);
    for (int action=0; action<5; action++) {
      if (((level > 1) && (action > 0)) || ((level < 2) && ((action < 2) || (action > 3)))) {
        SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_ADDSTRING, 0, (LPARAM)log_choices[action]);
        SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_SETITEMDATA, idx, action);
        if (action == defchoice[level]) {
          SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_SETCURSEL, idx, 0);
        }
        idx++;
      }
    }
  }
  EnableWindow(GetDlgItem(hDlg, IDDEVLIST), FALSE);
}

void RuntimeDlgSetAdvLogOpt(HWND hDlg)
{
  int idx, level, mod;

  idx = SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_GETCURSEL, 0, 0);
  mod = SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_GETITEMDATA, idx, 0);
  for (level=0; level<5; level++) {
    idx = 0;
    SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_RESETCONTENT, 0, 0);
    for (int action=0; action<4; action++) {
      if (((level > 1) && (action > 0)) || ((level < 2) && (action < 2))) {
        SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_ADDSTRING, 0, (LPARAM)log_choices[action]);
        SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_SETITEMDATA, idx, action);
        if (action == SIM->get_log_action (mod, level)) {
          SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_SETCURSEL, idx, 0);
        }
        idx++;
      }
    }
  }
}

static BOOL CALLBACK RTCdromDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static int devcount;
  static bx_list_c *cdromop[4];
  static char origpath[4][MAX_PATH];
  static BOOL changed;
  int device;
  long noticode;
  Bit8u cdrom;
  char path[MAX_PATH];
  PSHNOTIFY *psn;

  switch (msg) {
    case WM_INITDIALOG:
      SetForegroundWindow(GetParent(hDlg));
      SetDlgItemText(GetParent(hDlg), IDOK, "Continue");
      SetDlgItemText(GetParent(hDlg), IDCANCEL, "Quit");
      // 4 cdroms supported at run time
      devcount = 1;
      for (cdrom=1; cdrom<4; cdrom++) {
        if (!SIM->get_cdrom_options(cdrom, &cdromop[cdrom], &device) ||
	    !SIM->get_param_bool("present", cdromop[cdrom])->get()) {
          EnableWindow(GetDlgItem(hDlg, IDLABEL1+cdrom), FALSE);
          EnableWindow(GetDlgItem(hDlg, IDCDROM1+cdrom), FALSE);
          EnableWindow(GetDlgItem(hDlg, IDBROWSE1+cdrom), FALSE);
          EnableWindow(GetDlgItem(hDlg, IDSTATUS1+cdrom), FALSE);
        } else {
          lstrcpy(origpath[cdrom], SIM->get_param_string("path", cdromop[cdrom])->getptr());
          if (lstrlen(origpath[cdrom]) && lstrcmp(origpath[cdrom], "none")) {
            SetWindowText(GetDlgItem(hDlg, IDCDROM1+cdrom), origpath[cdrom]);
          }
          if (SIM->get_param_enum("status", cdromop[cdrom])->get() == BX_INSERTED) {
            SendMessage(GetDlgItem(hDlg, IDSTATUS1+cdrom), BM_SETCHECK, BST_CHECKED, 0);
          }
          devcount++;
        }
      }
      changed = FALSE;
      return TRUE;
    case WM_NOTIFY:
      psn = (PSHNOTIFY *)lParam;
      switch(psn->hdr.code) {
        case PSN_APPLY:
          if ((psn->lParam == FALSE) && changed) { // Apply pressed & change in this dialog
            for (device=1; device<devcount; device++) {
              if (SendMessage(GetDlgItem(hDlg, IDSTATUS1+device), BM_GETCHECK, 0, 0) == BST_CHECKED) {
                GetDlgItemText(hDlg, IDCDROM1+device, path, MAX_PATH);
                if (lstrlen(path)) {
                  SIM->get_param_enum("status", cdromop[device])->set(BX_INSERTED);
                  if (lstrcmp(path, SIM->get_param_string("path", cdromop[device])->getptr())) {
                    SIM->get_param_string("path", cdromop[device])->set(path);
                  }
                } else {
                  SIM->get_param_enum("status", cdromop[device])->set(BX_EJECTED);
                }
              } else {
                SIM->get_param_enum("status", cdromop[device])->set(BX_EJECTED);
              }
            }
            changed = FALSE;
          } else {
            if (changed) {
              for (device=1; device<devcount; device++) {
                if (lstrcmp(SIM->get_param_string("path", cdromop[device])->getptr(), origpath[device])) {
                  SIM->get_param_string("path", cdromop[device])->set(origpath[device]);
                }
              }
            }
            retcode = BX_CI_RT_CONT;
          }
          return PSNRET_NOERROR;
        case PSN_QUERYCANCEL:
          retcode = BX_CI_RT_QUIT;
          return TRUE;
      }
      break;
    case WM_COMMAND:
      noticode = HIWORD(wParam);
      switch(noticode) {
        case EN_CHANGE:
          switch (LOWORD(wParam)) {
            case IDCDROM2:
            case IDCDROM3:
            case IDCDROM4:
              changed = TRUE;
              SendMessage(GetParent(hDlg), PSM_CHANGED, (WPARAM)hDlg, 0);
              break;
          }
          break;
        default:
          switch (LOWORD(wParam)) {
            case IDBROWSE2:
            case IDBROWSE3:
            case IDBROWSE4:
              device = LOWORD(wParam) - IDBROWSE1;
              GetDlgItemText(hDlg, IDCDROM1+device, path, MAX_PATH);
              SIM->get_param_string("path", cdromop[device])->set(backslashes(path));
              if (AskFilename(hDlg, (bx_param_filename_c *)SIM->get_param_string("path", cdromop[device]), "iso") > 0) {
                SetWindowText(GetDlgItem(hDlg, IDCDROM1+device), SIM->get_param_string("path", cdromop[device])->getptr());
                SendMessage(GetDlgItem(hDlg, IDSTATUS1+device), BM_SETCHECK, BST_CHECKED, 0);
              }
              break;
            case IDSTATUS2:
            case IDSTATUS3:
            case IDSTATUS4:
              changed = TRUE;
              SendMessage(GetParent(hDlg), PSM_CHANGED, (WPARAM)hDlg, 0);
              break;
          }
      }
      break;
  }
  return FALSE;
}

static BOOL CALLBACK RTUSBdevDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static BOOL changed;
  long noticode;
  char buffer[MAX_PATH];
  PSHNOTIFY *psn;

  switch (msg) {
    case WM_INITDIALOG:
      if (SIM->get_param_string(BXPN_USB1_PORT1)->get_enabled()) {
        SetDlgItemText(hDlg, IDUSBDEV1, SIM->get_param_string(BXPN_USB1_PORT1)->getptr());
        SetDlgItemText(hDlg, IDUSBDEV2, SIM->get_param_string(BXPN_USB1_PORT2)->getptr());
      } else {
        EnableWindow(GetDlgItem(hDlg, IDUSBLBL1), FALSE);
        EnableWindow(GetDlgItem(hDlg, IDUSBLBL2), FALSE);
        EnableWindow(GetDlgItem(hDlg, IDUSBDEV1), FALSE);
        EnableWindow(GetDlgItem(hDlg, IDUSBDEV2), FALSE);
      }
      changed = FALSE;
      return TRUE;
    case WM_NOTIFY:
      psn = (PSHNOTIFY *)lParam;
      switch(psn->hdr.code) {
        case PSN_APPLY:
          if ((psn->lParam == FALSE) && changed) { // Apply pressed & change in this dialog
            GetDlgItemText(hDlg, IDUSBDEV1, buffer, sizeof(buffer));
            SIM->get_param_string(BXPN_USB1_PORT1)->set(buffer);
            GetDlgItemText(hDlg, IDUSBDEV2, buffer, sizeof(buffer));
            SIM->get_param_string(BXPN_USB1_PORT2)->set(buffer);
          }
          return PSNRET_NOERROR;
        case PSN_QUERYCANCEL:
          retcode = BX_CI_RT_QUIT;
          return TRUE;
      }
      break;
    case WM_COMMAND:
      noticode = HIWORD(wParam);
      switch(noticode) {
        case EN_CHANGE:
          switch (LOWORD(wParam)) {
            case IDUSBDEV1:
            case IDUSBDEV2:
              changed = TRUE;
              SendMessage(GetParent(hDlg), PSM_CHANGED, (WPARAM)hDlg, 0);
              break;
          }
          break;
      }
      break;
  }
  return FALSE;
}

static BOOL CALLBACK RTLogOptDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static BOOL advanced;
  static BOOL changed;
  int idx, level, mod, value;
  long noticode;
  char prefix[8];
  PSHNOTIFY *psn;

  switch (msg) {
    case WM_INITDIALOG:
      idx = 0;
      for (mod=0; mod<SIM->get_n_log_modules(); mod++) {
        if (strcmp(SIM->get_prefix(mod), "[     ]")) {
          lstrcpyn(prefix, SIM->get_prefix(mod), sizeof(prefix));
          lstrcpy(prefix, prefix+1);
          prefix[5] = 0;
          SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_ADDSTRING, 0, (LPARAM)prefix);
          SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_SETITEMDATA, idx, mod);
          idx++;
        }
      }
      RuntimeDlgSetStdLogOpt(hDlg);
      advanced = FALSE;
      changed = FALSE;
      return TRUE;
    case WM_NOTIFY:
      psn = (PSHNOTIFY *)lParam;
      switch(psn->hdr.code) {
        case PSN_APPLY:
          if ((psn->lParam == FALSE) && changed) { // Apply pressed & change in this dialog
            if (advanced) {
              idx = SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_GETCURSEL, 0, 0);
              mod = SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_GETITEMDATA, idx, 0);
              for (level=0; level<5; level++) {
                idx = SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_GETCURSEL, 0, 0);
                value = SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_GETITEMDATA, idx, 0);
                SIM->set_log_action (mod, level, value);
              }
              EnableWindow(GetDlgItem(hDlg, IDDEVLIST), TRUE);
            } else {
              for (level=0; level<5; level++) {
                idx = SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_GETCURSEL, 0, 0);
                value = SendMessage(GetDlgItem(hDlg, IDLOGEVT1+level), CB_GETITEMDATA, idx, 0);
                if (value < 4) {
                  // set new default
                  SIM->set_default_log_action (level, value);
                  // apply that action to all modules (devices)
                  SIM->set_log_action (-1, level, value);
                }
              }
            }
            EnableWindow(GetDlgItem(hDlg, IDADVLOGOPT), TRUE);
            changed = FALSE;
          }
          return PSNRET_NOERROR;
        case PSN_QUERYCANCEL:
          retcode = BX_CI_RT_QUIT;
          return TRUE;
      }
      break;
    case WM_COMMAND:
      noticode = HIWORD(wParam);
      switch(noticode) {
        case CBN_SELCHANGE: /* LBN_SELCHANGE is the same value */
          switch (LOWORD(wParam)) {
            case IDDEVLIST:
              RuntimeDlgSetAdvLogOpt(hDlg);
              break;
            case IDLOGEVT1:
            case IDLOGEVT2:
            case IDLOGEVT3:
            case IDLOGEVT4:
            case IDLOGEVT5:
              if (!changed) {
                EnableWindow(GetDlgItem(hDlg, IDADVLOGOPT), FALSE);
                if (advanced) {
                  EnableWindow(GetDlgItem(hDlg, IDDEVLIST), FALSE);
                }
                changed = TRUE;
                SendMessage(GetParent(hDlg), PSM_CHANGED, (WPARAM)hDlg, 0);
              }
              break;
          }
          break;
        default:
          switch (LOWORD(wParam)) {
            case IDADVLOGOPT:
              if (SendMessage(GetDlgItem(hDlg, IDADVLOGOPT), BM_GETCHECK, 0, 0) == BST_CHECKED) {
                EnableWindow(GetDlgItem(hDlg, IDDEVLIST), TRUE);
                SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_SETCURSEL, 0, 0);
                RuntimeDlgSetAdvLogOpt(hDlg);
                advanced = TRUE;
              } else {
                SendMessage(GetDlgItem(hDlg, IDDEVLIST), LB_SETCURSEL, (WPARAM)-1, 0);
                RuntimeDlgSetStdLogOpt(hDlg);
                advanced = FALSE;
              }
              break;
          }
      }
      break;
  }
  return FALSE;
}

static BOOL CALLBACK RTMiscDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  static BOOL changed;
  int value;
  long noticode;
  char buffer[32];
  PSHNOTIFY *psn;

  switch (msg) {
    case WM_INITDIALOG:
      SetDlgItemInt(hDlg, IDVGAUPDATE, SIM->get_param_num(BXPN_VGA_UPDATE_INTERVAL)->get(), FALSE);
      SetDlgItemInt(hDlg, IDKBDPASTE, SIM->get_param_num(BXPN_KBD_PASTE_DELAY)->get(), FALSE);
      if (SIM->get_param_num(BXPN_MOUSE_ENABLED)->get()) {
        SendMessage(GetDlgItem(hDlg, IDMOUSE), BM_SETCHECK, BST_CHECKED, 0);
      }
      SetDlgItemText(hDlg, IDUSERBTN, SIM->get_param_string(BXPN_USER_SHORTCUT)->getptr());
      SetDlgItemInt(hDlg, IDSB16TIMER, SIM->get_param_num(BXPN_SB16_DMATIMER)->get(), FALSE);
      SetDlgItemInt(hDlg, IDSBLOGLEV, SIM->get_param_num(BXPN_SB16_LOGLEVEL)->get(), FALSE);
      changed = FALSE;
      return TRUE;
    case WM_NOTIFY:
      psn = (PSHNOTIFY *)lParam;
      switch(psn->hdr.code) {
        case PSN_APPLY:
          if ((psn->lParam == FALSE) && changed) { // Apply pressed & change in this dialog
            value = GetDlgItemInt(hDlg, IDVGAUPDATE, NULL, FALSE);
            SIM->get_param_num(BXPN_VGA_UPDATE_INTERVAL)->set(value);
            value = GetDlgItemInt(hDlg, IDKBDPASTE, NULL, FALSE);
            SIM->get_param_num(BXPN_KBD_PASTE_DELAY)->set(value);
            value = SendMessage(GetDlgItem(hDlg, IDMOUSE), BM_GETCHECK, 0, 0);
            SIM->get_param_num(BXPN_MOUSE_ENABLED)->set(value==BST_CHECKED);
            GetDlgItemText(hDlg, IDUSERBTN, buffer, sizeof(buffer));
            SIM->get_param_string(BXPN_USER_SHORTCUT)->set(buffer);
            value = GetDlgItemInt(hDlg, IDSB16TIMER, NULL, FALSE);
            SIM->get_param_num(BXPN_SB16_DMATIMER)->set(value);
            value = GetDlgItemInt(hDlg, IDSBLOGLEV, NULL, FALSE);
            SIM->get_param_num(BXPN_SB16_LOGLEVEL)->set(value);
            changed = FALSE;
          }
          return PSNRET_NOERROR;
        case PSN_QUERYCANCEL:
          retcode = BX_CI_RT_QUIT;
          return TRUE;
      }
      break;
    case WM_COMMAND:
      noticode = HIWORD(wParam);
      switch(noticode) {
        case EN_CHANGE:
          switch (LOWORD(wParam)) {
            case IDVGAUPDATE:
            case IDKBDPASTE:
            case IDUSERBTN:
            case IDSB16TIMER:
            case IDSBLOGLEV:
              changed = TRUE;
              SendMessage(GetParent(hDlg), PSM_CHANGED, (WPARAM)hDlg, 0);
              break;
          }
          break;
        default:
          switch (LOWORD(wParam)) {
            case IDMOUSE:
              changed = TRUE;
              SendMessage(GetParent(hDlg), PSM_CHANGED, (WPARAM)hDlg, 0);
              break;
          }
      }
      break;
  }
  return FALSE;
}

void LogAskDialog(BxEvent *event)
{
  event->retcode = DialogBoxParam(NULL, MAKEINTRESOURCE(ASK_DLG), GetBochsWindow(),
                                  (DLGPROC)LogAskProc, (LPARAM)event);
}

int AskFilename(HWND hwnd, bx_param_filename_c *param, const char *ext)
{
  OPENFILENAME ofn;
  int ret;
  DWORD errcode;
  char filename[MAX_PATH];
  const char *title;
  char errtext[80];

  param->get(filename, MAX_PATH);
  // common file dialogs don't accept raw device names
  if ((isalpha(filename[0])) && (filename[1] == ':') && (strlen(filename) == 2)) {
    filename[0] = 0;
  }
  title = param->get_label();
  if (!title) title = param->get_name();
  memset(&ofn, 0, sizeof(OPENFILENAME));
  ofn.lStructSize = sizeof(OPENFILENAME);
  ofn.hwndOwner = hwnd;
  ofn.lpstrFile   = filename;
  ofn.nMaxFile    = MAX_PATH;
  ofn.lpstrInitialDir = bx_startup_flags.initial_dir;
  ofn.lpstrTitle = title;
  ofn.Flags = OFN_EXPLORER | OFN_HIDEREADONLY;
  ofn.lpstrDefExt = ext;
  if (!lstrcmp(ext, "img")) {
    ofn.lpstrFilter = "Floppy image files (*.img)\0*.img\0All files (*.*)\0*.*\0";
  } else if (!lstrcmp(ext, "iso")) {
    ofn.lpstrFilter = "CD-ROM image files (*.iso)\0*.iso\0All files (*.*)\0*.*\0";
  } else if (!lstrcmp(ext, "txt")) {
    ofn.lpstrFilter = "Text files (*.txt)\0*.txt\0All files (*.*)\0*.*\0";
  } else {
    ofn.lpstrFilter = "All files (*.*)\0*.*\0";
  }
  if (param->get_options()->get() & bx_param_filename_c::SAVE_FILE_DIALOG) {
    ofn.Flags |= OFN_OVERWRITEPROMPT;
    ret = GetSaveFileName(&ofn);
  } else {
    ofn.Flags |= OFN_FILEMUSTEXIST;
    ret = GetOpenFileName(&ofn);
  }
  param->set(filename);
  if (ret == 0) {
    errcode = CommDlgExtendedError();
    if (errcode == 0) {
      ret = -1;
    } else {
      if (errcode == 0x3002) {
        wsprintf(errtext, "CommDlgExtendedError: invalid filename");
      } else {
        wsprintf(errtext, "CommDlgExtendedError returns 0x%04x", errcode);
      }
      MessageBox(hwnd, errtext, "Error", MB_ICONERROR);
    }
  }
  return ret;
}

int AskString(bx_param_string_c *param)
{
  return DialogBoxParam(NULL, MAKEINTRESOURCE(STRING_DLG), GetBochsWindow(),
                        (DLGPROC)StringParamProc, (LPARAM)param);
}

int FloppyDialog(bx_param_filename_c *param)
{
  return DialogBoxParam(NULL, MAKEINTRESOURCE(FLOPPY_DLG), GetBochsWindow(),
                        (DLGPROC)FloppyDlgProc, (LPARAM)param);
}

int Cdrom1Dialog()
{
  return DialogBox(NULL, MAKEINTRESOURCE(CDROM1_DLG), GetBochsWindow(),
                   (DLGPROC)Cdrom1DlgProc);
}

int RuntimeOptionsDialog()
{
  PROPSHEETPAGE psp[4];
  PROPSHEETHEADER psh;
  int i;

  memset(psp,0,sizeof(psp));
  for (i = 0; i < 4; i++) {
    psp[i].dwSize = sizeof(PROPSHEETPAGE);
    psp[i].dwFlags = PSP_DEFAULT;
    psp[i].hInstance = NULL;
  }
  psp[0].pszTemplate = MAKEINTRESOURCE(RT_CDROM_DLG);
  psp[0].pfnDlgProc = RTCdromDlgProc;
  psp[1].pszTemplate = MAKEINTRESOURCE(RT_USBDEV_DLG);
  psp[1].pfnDlgProc = RTUSBdevDlgProc;
  psp[2].pszTemplate = MAKEINTRESOURCE(RT_LOGOPT_DLG);
  psp[2].pfnDlgProc = RTLogOptDlgProc;
  psp[3].pszTemplate = MAKEINTRESOURCE(RT_MISC_DLG);
  psp[3].pfnDlgProc = RTMiscDlgProc;

  memset(&psh,0,sizeof(PROPSHEETHEADER));
  psh.dwSize = sizeof(PROPSHEETHEADER);
  psh.dwFlags = PSH_PROPSHEETPAGE;
  psh.hwndParent = GetBochsWindow();
  psh.hInstance = NULL;
  psh.pszCaption = "Runtime Options";
  psh.nPages = 4;
  psh.ppsp = (LPCPROPSHEETPAGE)&psp;

  PropertySheet(&psh);
  PostMessage(GetBochsWindow(), WM_SETFOCUS, 0, 0);
  return retcode;
}

#if BX_DEBUGGER
void RefreshDebugDialog()
{
  unsigned i;
  char buffer[20];

  if (showCPU) {
    for (i = 0; i < 15; i++) {
      sprintf(buffer, "%08X", cpu_param[i]->get());
      SetDlgItemText(hDebugDialog, IDCPUVAL1+i, buffer);
    }
  }
}

static BOOL CALLBACK DebuggerDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  unsigned i;
  int idx, lines;
  static RECT R;

  switch (msg) {
    case WM_INITDIALOG:
      GetWindowRect(hDlg, &R);
#if BX_SUPPORT_X86_64
      cpu_param[0] = SIM->get_param_num("cpu0.RAX", SIM->get_bochs_root());
      cpu_param[1] = SIM->get_param_num("cpu0.RBX", SIM->get_bochs_root());
      cpu_param[2] = SIM->get_param_num("cpu0.RCX", SIM->get_bochs_root());
      cpu_param[3] = SIM->get_param_num("cpu0.RDX", SIM->get_bochs_root());
      cpu_param[4] = SIM->get_param_num("cpu0.RSP", SIM->get_bochs_root());
      cpu_param[5] = SIM->get_param_num("cpu0.RBP", SIM->get_bochs_root());
      cpu_param[6] = SIM->get_param_num("cpu0.RSI", SIM->get_bochs_root());
      cpu_param[7] = SIM->get_param_num("cpu0.RDI", SIM->get_bochs_root());
      cpu_param[8] = SIM->get_param_num("cpu0.RIP", SIM->get_bochs_root());
#else
      cpu_param[0] = SIM->get_param_num("cpu0.EAX", SIM->get_bochs_root());
      cpu_param[1] = SIM->get_param_num("cpu0.EBX", SIM->get_bochs_root());
      cpu_param[2] = SIM->get_param_num("cpu0.ECX", SIM->get_bochs_root());
      cpu_param[3] = SIM->get_param_num("cpu0.EDX", SIM->get_bochs_root());
      cpu_param[4] = SIM->get_param_num("cpu0.ESP", SIM->get_bochs_root());
      cpu_param[5] = SIM->get_param_num("cpu0.EBP", SIM->get_bochs_root());
      cpu_param[6] = SIM->get_param_num("cpu0.ESI", SIM->get_bochs_root());
      cpu_param[7] = SIM->get_param_num("cpu0.EDI", SIM->get_bochs_root());
      cpu_param[8] = SIM->get_param_num("cpu0.EIP", SIM->get_bochs_root());
#endif
      cpu_param[9] = SIM->get_param_num("cpu0.CS.selector", SIM->get_bochs_root());
      cpu_param[10] = SIM->get_param_num("cpu0.DS.selector", SIM->get_bochs_root());
      cpu_param[11] = SIM->get_param_num("cpu0.ES.selector", SIM->get_bochs_root());
      cpu_param[12] = SIM->get_param_num("cpu0.FS.selector", SIM->get_bochs_root());
      cpu_param[13] = SIM->get_param_num("cpu0.GS.selector", SIM->get_bochs_root());
      cpu_param[14] = SIM->get_param_num("cpu0.EFLAGS", SIM->get_bochs_root());
      return TRUE;
    case WM_CLOSE:
      bx_user_quit = 1;
      SIM->debug_break();
      DestroyWindow(hDebugDialog);
      hDebugDialog = NULL;
      break;
    case WM_COMMAND:
      switch (LOWORD(wParam)) {
        case IDEXEC:
          GetDlgItemText(hDlg, DEBUG_CMD, debug_cmd, 512);
          if (lstrlen(debug_cmd) > 0) {
            debug_cmd_ready = TRUE;
          } else {
            SetFocus(GetDlgItem(hDlg, DEBUG_CMD));
          }
          break;
        case IDSTOP:
          SIM->debug_break();
          break;
        case IDSHOWCPU:
          showCPU = !showCPU;
          if (showCPU) {
            SetDlgItemText(hDlg, IDSHOWCPU, "Hide CPU <<");
            MoveWindow(hDlg, R.left, R.top, R.right - R.left + 300, R.bottom - R.top, TRUE);
            RefreshDebugDialog();
          } else {
            SetDlgItemText(hDlg, IDSHOWCPU, "Show CPU >>");
            MoveWindow(hDlg, R.left, R.top, R.right - R.left, R.bottom - R.top, TRUE);
          }
          for (i = 0; i < 15; i++) {
            ShowWindow(GetDlgItem(hDlg, IDCPULBL1+i), showCPU ? SW_SHOW : SW_HIDE);
            ShowWindow(GetDlgItem(hDlg, IDCPUVAL1+i), showCPU ? SW_SHOW : SW_HIDE);
          }
          break;
      }
    case WM_USER:
      if (wParam == 0x1234) {
        EnableWindow(GetDlgItem(hDlg, DEBUG_CMD), lParam > 0);
        EnableWindow(GetDlgItem(hDlg, IDEXEC), lParam > 0);
        EnableWindow(GetDlgItem(hDlg, IDSTOP), lParam == 0);
        SetFocus(GetDlgItem(hDlg, (lParam > 0)?DEBUG_CMD:IDSTOP));
      } else if (wParam == 0x5678) {
        lines = SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_GETLINECOUNT, 0, 0);
        if (lines > 100) {
          idx = SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_LINEINDEX, 1, 0);
          SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_SETSEL, 0, idx);
          SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_REPLACESEL, 0, (LPARAM)"");
          lines--;
        }
        idx = SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_LINEINDEX, lines - 1, 0);
        idx += SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_LINELENGTH, idx, 0);
        SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_SETSEL, idx, idx);
        SendMessage(GetDlgItem(hDlg, DEBUG_MSG), EM_REPLACESEL, 0, lParam);
      }
      break;
  }
  return FALSE;
}

void InitDebugDialog(HWND mainwnd)
{
  hDebugDialog = CreateDialog(GetModuleHandle(NULL), MAKEINTRESOURCE(DEBUGGER_DLG), mainwnd,
                              (DLGPROC)DebuggerDlgProc);
  ShowWindow(hDebugDialog, SW_SHOW);
}
#endif

BxEvent* win32_notify_callback(void *unused, BxEvent *event)
{
  int opts;
  bx_param_c *param;
  bx_param_string_c *sparam;
#if BX_DEBUGGER
  char debug_msg[1024];
  int i, j;
#endif

  event->retcode = -1;
  switch (event->type)
  {
    case BX_SYNC_EVT_LOG_ASK:
      LogAskDialog(event);
      return event;
#if BX_DEBUGGER
    case BX_SYNC_EVT_GET_DBG_COMMAND:
      {
        debug_cmd = new char[512];
        SendMessage(hDebugDialog, WM_USER, 0x1234, 1);
        debug_cmd_ready = FALSE;
        while (!debug_cmd_ready && (hDebugDialog != NULL)) {
          Sleep(10);
        }
        if (hDebugDialog == NULL) {
          lstrcpy(debug_cmd, "q");
        } else {
          SendMessage(hDebugDialog, WM_USER, 0x1234, 0);
        }
        event->u.debugcmd.command = debug_cmd;
        event->retcode = 1;
        return event;
      }
    case BX_ASYNC_EVT_DBG_MSG:
      lstrcpy(debug_msg, (char*)event->u.logmsg.msg);
      for (i = 0; i < lstrlen(debug_msg); i++) {
        if (debug_msg[i] == 10) {
          for (j = lstrlen(debug_msg); j >= i; j--) debug_msg[j+1] = debug_msg[j];
          debug_msg[i] = 13;
          i++;
        }
      }
      SendMessage(hDebugDialog, WM_USER, 0x5678, (LPARAM)debug_msg);
      // free the char* which was allocated in dbg_printf
      delete [] ((char*)event->u.logmsg.msg);
      return event;
#endif
    case BX_SYNC_EVT_ASK_PARAM:
      param = event->u.param.param;
      if (param->get_type() == BXT_PARAM_STRING) {
        sparam = (bx_param_string_c *)param;
        opts = sparam->get_options()->get();
        if (opts & sparam->IS_FILENAME) {
          if (opts & sparam->SELECT_FOLDER_DLG) {
            event->retcode = BrowseDir(sparam->get_label(), sparam->getptr());
          } else if (param->get_parent() == NULL) {
            event->retcode = AskFilename(GetBochsWindow(), (bx_param_filename_c *)sparam, "txt");
          } else {
            event->retcode = FloppyDialog((bx_param_filename_c *)sparam);
          }
          return event;
        } else {
          event->retcode = AskString(sparam);
          return event;
        }
      } else if (param->get_type() == BXT_LIST) {
        event->retcode = Cdrom1Dialog();
        return event;
      } else if (param->get_type() == BXT_PARAM_BOOL) {
        UINT flag = MB_YESNO | MB_SETFOREGROUND;
        if (((bx_param_bool_c *)param)->get() == 0) {
          flag |= MB_DEFBUTTON2;
        }
        ((bx_param_bool_c *)param)->set(MessageBox(GetActiveWindow(), param->get_description(), param->get_label(), flag) == IDYES);
        event->retcode = 0;
        return event;
      }
    case BX_ASYNC_EVT_REFRESH:
#if BX_DEBUGGER
      RefreshDebugDialog();
      return event;
#endif
    case BX_SYNC_EVT_TICK: // called periodically by siminterface.
      // fall into default case
    default:
      return (*old_callback)(old_callback_arg, event);
  }
}

void win32_init_notify_callback()
{
  SIM->get_notify_callback(&old_callback, &old_callback_arg);
  assert (old_callback != NULL);
  SIM->set_notify_callback(win32_notify_callback, NULL);
}

#endif // BX_USE_TEXTCONFIG && defined(WIN32)
