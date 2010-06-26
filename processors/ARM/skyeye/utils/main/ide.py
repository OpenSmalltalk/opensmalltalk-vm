import os, os.path, sys, Tix
from Tkconstants import *
import traceback, tkMessageBox
from Tkinter import *
import subprocess 
import win32process 
import win32api

class skyeye:
  cpu = ""
  board=""
  net = ""
  lcd = ""
  flash = ""
  map = ""
  type = ""
  addr = ""
  size = ""
  file = ""
  membank = []
  memory_info = ""
  cpu_once = 0
  device_once = 0
  memory_once = 0
  image_path = None
  conf_path = None
  run = None
  kill = None
  is_running = 0
  skyeye_id = 0
  
  
  def __init__(self, top):
    self.root = top
    self.build()
  
  def skyeye_mainmenu(self):
    top = self.root
    w = Tix.Frame(top, bd=2, relief=RAISED)
    file = Tix.Menubutton(w, text='File', underline=0, takefocus=0)
    view = Tix.Menubutton(w, text='Setting', underline=0, takefocus=0)
    project = Tix.Menubutton(w, text='Project', underline=0, takefocus=0)
    execute = Tix.Menubutton(w, text='Execute', underline=0, takefocus=0)
    tools = Tix.Menubutton(w, text='Tools', underline=0, takefocus=0)
    window = Tix.Menubutton(w, text='Window', underline=0, takefocus=0)
    help = Tix.Menubutton(w, text='Help', underline=0, takefocus=0)

    file.pack(side=LEFT)
    project.pack(side=LEFT)
    view.pack(side=LEFT)    
    execute.pack(side=LEFT)
    tools.pack(side=LEFT)
    window.pack(side=LEFT)
    help.pack(side=RIGHT)
    
    file_m = Tix.Menu(file, tearoff=0)
    file['menu'] = file_m
    view_m = Tix.Menu(view, tearoff=0)
    view['menu'] = view_m
    project_m = Tix.Menu(project, tearoff=0)
    project['menu'] = project_m
    execute_m = Tix.Menu(execute, tearoff=0)
    execute['menu'] = execute_m
    tools_m = Tix.Menu(tools, tearoff=0)
    tools['menu'] = tools_m
    window_m = Tix.Menu(window, tearoff=0)
    window['menu'] = window_m
    help_m = Tix.Menu(help, tearoff=0)
    help['menu'] = help_m

    file_m.add_command(label='Open file', underline=1,
                   command = self.file_openfile)
    file_m.add_command(label='Close file', underline=1,
                   command = self.file_closefile)
    file_m.add_command(label='Exit', underline=1,
                   command = self.file_exit)
    
    view_m.add_radiobutton(label='Cpu', underline =1,
                       command = self.view_cpu)
    view_m.add_radiobutton(label='Device', underline =1,
                       command = self.view_device)
    view_m.add_radiobutton(label='Memory', underline =1,
                       command = self.view_memory)
    view_m.add_radiobutton(label='System Info', underline =1,
                       command = self.view_info)
    
    project_m.add_command(label='New', underline =1,
                          command = self.project_new)
    project_m.add_command(label='Save', underline =1,
                          command = self.project_save)
    
    execute_m.add_command(label='Compile', underline =1,
                          command = self.execute_compile)
    execute_m.add_command(label='Compile current file', underline =1,
                          command = self.execute_compilecurrentfile)
    execute_m.add_command(label='Run', underline =1,
                          command = self.execute_run)
    execute_m.add_command(label='Compile & Run', underline =1,
                          command = self.execute_compileandrun)
    execute_m.add_command(label='Rebuild All', underline =1,
                          command = self.execute_rebuildall)
    execute_m.add_command(label='Clean', underline =1,
                          command = self.execute_clean)
    
    tools_m.add_command(label='Compiler Option', underline =1,
                          command = self.tools_compileroption)
    tools_m.add_command(label='Linker Option', underline =1,
                          command = self.tools_linkeroption)
    tools_m.add_command(label='Makefile Option', underline =1,
                          command = self.tools_makefileoption)
    
    
    
    window_m.add_command(label='Max', underline=0, 
                       command=self.window_max)
    window_m.add_command(label='Restore', underline=0, 
                       command=self.window_restore)
    
    help_m.add_command(label='about',underline =0,
                       command=self.help_about)
    return w

  def skyeye_body(self, str):
    top = self.root
    try:
      self.body.destroy()
    except:
      pass
    
    self.body = Tix.LabelFrame(top, label=str, labelside="acrosstop")
    self.body.pack(fill=Tix.BOTH, padx=8, pady=20)
    return self.body
  
  def skyeye_messagebox(self):
    top = self.root
    pane = Tix.LabelFrame(top, label='Message Area',labelside="acrosstop")
    text = Tix.ScrolledText(pane,height=100,scrollbar="y")
    text.text.insert(Tix.END,"Welcome to skyeye")
    text.pack(fill=Tix.BOTH, padx=8, pady=20)
    self.messagebox = text
    return pane
  
  def message(self, msg):
    self.messagebox.text.delete("0.0",Tix.END)
    self.messagebox.text.insert(Tix.END,msg)
    
  def build(self):
    root = self.root
    z = root.winfo_toplevel()
    z.wm_title('skyeye for windows')
        
    frame1 = self.skyeye_mainmenu()
    frame1.grid(row=0,sticky=N+W+E)
    frame2 = self.skyeye_messagebox()
    frame2.grid(row=2,sticky=S+W+E)
    self.welcome()

    
    self.message("hello renjie")

  def file_openfile(self):
    tmp = Tix.ExFileSelectBox(self.skyeye_body("Open file for reading"),command=self.file_openfile_command)
    tmp.pack(fill=Tix.BOTH, padx=8, pady=20)
    self.skyeye_redobody()
    
  
  def file_openfile_command(self,event=None):
    
    text = Tix.ScrolledText(self.skyeye_body("Reading file : %s"%str(event)),height=300,scrollbar="y")
    try:
      fd = open(str(event),"r")
      for x in fd.readlines():
        text.text.insert(Tix.END,x)
        self.message("Open file <%s> for reading"%str(event))
    except:
      self.message("Cannot open file: %s"%str(event))
    text.pack(fill=Tix.BOTH, padx=8, pady=20)
    self.skyeye_redobody()
    
  def welcome(self):
    tmp = Tix.Label(self.skyeye_body("Welcome"),text="koodialar",height=30)
    tmp.pack(fill=Tix.BOTH, padx=8, pady=20)
    self.skyeye_redobody()

  def skyeye_redobody(self):
    self.body.grid(row=1,sticky=N+S+W+E)
    
  def file_closefile(self):
    self.welcome()
  
  def file_exit(self):
    self.destroy()
    self.message("File is closed")
    
  def view_cpu(self):
    self.message("You are now setting the cpu and mainboard information")
    if self.cpu_once == 1:
      self.cpu_board_ok()
      return
    
    cpu_list = ["arm","bfin"]
    board_list =["at91",
                  "at91rm92",
                  "clps7110",
                  "clps9312",
                  "cs89712"
                  "ep7212",
                  "ep9312",
                  "lh79520",
                  "lh79520-hardware",
                  "lh79520-irqs",
                  "lpc",
                  "ns9750",
                  "pxa",
                  "s3c44b0",
                  "s3c2410x",
                  "s3c4510b",
                  "sa1100",
                  "serial_amba",
                  "serial_amba_pl011",
                  "sharp"]
    top = self.skyeye_body("Cpu & Mainboard")
    cpu = Tix.LabelFrame(top, label='Cpu',labelside="acrosstop",padx=5,pady=10)
    board = Tix.LabelFrame(top, label='Mainboard',labelside="acrosstop",padx=5,pady=10)
    
    cpu_s = Tix.OptionMenu(cpu, label="Cpu:   ",command=self.cpu_select)
    
    board_s = Tix.OptionMenu(board, label="Mainboard:    ",command=self.board_select)
    
    ok = Tix.Button(top, text="OK", command=self.cpu_board_ok)
    
    for x in cpu_list:
      cpu_s.add_command(x,label=x)
    for x in board_list:
      board_s.add_command(x,label=x)
      
    cpu_s.pack(padx=5,pady=10)
    cpu.grid(row = 0, column=0,padx=5,pady=10)
    board_s.pack(padx=5,pady=10)
    board.grid(row = 0, column=1,padx=5,pady=10)
    ok.grid(row=1, column=0, columnspan=2,padx=5,pady=10)

    self.skyeye_redobody()
  
  def cpu_select(self, event=None):
    self.cpu = str(event)
    self.message("Cpu <%s> is chosen"%str(event))
    
  def board_select(self, event=None):
    self.board = str(event)
    self.message("Mainboard <%s> is chosen"%str(event))
    
  def cpu_board_ok(self, event=None):
    self.cpu_once = 1
    top = self.skyeye_body("Cpu & Mainboard")
    
    tmp = Tix.Frame(top)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Below are the information of Cpu and Mainboard:')
    b.grid( row =0 ,padx=5,pady=3,sticky=W+E)
    
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='\tCpu\t\t: %s\n\tMainboard\t: %s'%(self.cpu,self.board))
    b.grid( row =1 ,padx=5,pady=3,sticky=W+E)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Would you want to reset?')
    b.grid( row =2 ,padx=5,pady=3,sticky=W+E)
    
    reset = Tix.Button(tmp, text="OK", command=self.reset_cpu, width = 5, bg="red",fg="white")
    reset.grid( row = 3,padx=5,pady=3)
    
    tmp.grid(padx=5,pady=10)
    
    self.message("You choose:\n\tCpu\t\t: %s\n\tMainboard\t: %s"%(self.cpu,self.board))
    
    self.skyeye_redobody() 
    
  def reset_cpu(self):
    self.cpu_once = 0
    self.view_cpu()
    
  def view_device(self):
    self.message("You are now setting the peripherial information")
    if self.device_once == 1:
      self.net_lcd_flash_ok()
      return 
    
    net_list=["cs8900a",
              "rtl8091",
              "s3c4510b"]
    
    lcd_list=["ep7312",
              "pxa",
              "s3c2410"]
    flash_list=["ibm"]
  
    top = self.skyeye_body("Peripherial")
    net = Tix.LabelFrame(top,labelside="acrosstop",padx=5,pady=10)
    lcd = Tix.LabelFrame(top,labelside="acrosstop",padx=5,pady=10)
    flash = Tix.LabelFrame(top,labelside="acrosstop",padx=5,pady=10)
    
    self.net_v = Tix.StringVar()
    self.lcd_v = Tix.StringVar()
    self.flash_v = Tix.StringVar()
    
    net_s = Tix.Select(net, label='Net Adapter', allowzero=1, radio=1,
                      orientation=Tix.VERTICAL,
                      labelside=Tix.TOP,
                      command=self.net_select,
                       variable=self.net_v)
    
    lcd_s = Tix.Select(lcd, label='Lcd', allowzero=1, radio=1,
                       orientation=Tix.VERTICAL,
                       labelside=Tix.TOP,
                       command=self.lcd_select,
                       variable=self.lcd_v)
     
    flash_s = Tix.Select(flash, label='Flash', allowzero=1, radio=1,
                      orientation=Tix.VERTICAL,
                      labelside=Tix.TOP,
                      command=self.flash_select,
                         variable=self.flash_v)
    
    ok = Tix.Button(top, text="OK", command=self.net_lcd_flash_ok)
    
    for x in net_list:
      net_s.add(x,text=x)
    for x in lcd_list:
      lcd_s.add(x,text=x)
    for x in flash_list:
      flash_s.add(x,text=x)      
      
    net_s.pack(padx=5,pady=10)
    net.grid(row = 0, column=0,padx=5,pady=10)
    lcd_s.pack(padx=5,pady=10)
    lcd.grid(row = 0, column=1,padx=5,pady=10)
    flash_s.pack(padx=5,pady=10)
    flash.grid(row = 0, column=2,padx=5,pady=10)
    ok.grid(row=1, column=1, columnspan=1,padx=5,pady=10)

    self.skyeye_redobody() 
    
  def net_select(self,event=None,test=None):
    if str(test) != "0":
      self.net_tmp = self.net_v
      self.message("Net adapter <%s> is chosen"%str(event))
    else:
      self.message("No net adapter is chosen")
    
  def lcd_select(self,event=None,test=None):
    if str(test) != "0":
      self.lcd_tmp = self.lcd_v
      self.message("Lcd <%s> is chosen"%str(event))
    else:
      self.message("No Lcd is chosen")
    
  def flash_select(self,event=None,test=None):
    
    if str(test) != "0":
      self.flash_tmp = self.flash_v
      self.message("Flash <%s> is chosen"%str(event))
    else:
      self.message("No Flash is chosen")
    
  def net_lcd_flash_ok(self,event=None):
    self.device_once = 1
    top = self.skyeye_body("Peripherial")
    
    tmp = Tix.Frame(top)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Below are the information of peripherials:')
    b.grid( row =0 ,padx=5,pady=3,sticky=W+E)
    
    self.net = self.net_v.get()[2:-3]
    str = ""
    if self.net !="":
      str +="\tNet\t: %s\n"%self.net
    else:
      str +="\tNet\t: disabled\n"
      
    self.lcd = self.lcd_v.get()[2:-3]
    if self.lcd !="":
      str +="\tLcd\t: %s\n"%self.lcd
    else:
      str +="\tLcd\t: disabled\n"
      
    self.flash = self.flash_v.get()[2:-3]
    if self.flash !="":
      str +="\tFlash\t: %s\n"%self.flash
    else:
      str +="\tFlash\t: disabled\n"
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='%s'%str)
    b.grid( row =1 ,padx=5,pady=3,sticky=W+E)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Would you want to reset?')
    b.grid( row =2 ,padx=5,pady=3,sticky=W+E)
    
    reset = Tix.Button(tmp, text="OK", command=self.reset_device, width = 5, bg="red",fg="white")
    reset.grid( row = 3,padx=5,pady=3)
    
    tmp.grid(padx=5,pady=10)
    
    self.message("Peripherial information:\n"+str)
    self.skyeye_redobody() 
    
  def reset_device(self):
    self.device_once = 0
    self.view_device()
    
  def view_memory(self):
    self.message("You are now setting memory information")
    if self.memory_once == 1:
      self.memory_ok()
      return
    
    top = self.skyeye_body("Cpu & Mainboard")
    
    mem = Tix.Frame(top)

    b = Tix.Label(mem, text="Map  :")
    map = Tix.OptionMenu(mem,command=self.memory_map)
    b.grid(row = 0, column = 0,padx=5,pady=3,sticky=W+E)
    map.grid(row = 0,column = 1, columnspan=2, padx=5,pady=3,sticky=W+E)
    
    b = Tix.Label(mem, text="Type :")
    type = Tix.OptionMenu(mem,command=self.memory_type)
    b.grid(row = 1, column = 0,padx=5,pady=3,sticky=W+E)
    type.grid(row = 1,column = 1, columnspan=2, padx=5,pady=3,sticky=W+E)
    
    b = Tix.Label(mem, text="'Addr :")
    addr = Tix.ComboBox(mem, editable=1, history=1,anchor=Tix.E,command=self.memory_addr)
    b.grid(row = 2, column = 0,padx=5,pady=3,sticky=W+E)
    addr.grid(row = 2,column = 1, columnspan=2, padx=5,pady=3,sticky=W+E)
    
    b = Tix.Label(mem, text="Size :")
    size = Tix.ComboBox(mem,editable=1, history=1,anchor=Tix.E,command=self.memory_size)
    b.grid(row = 3, column = 0,padx=5,pady=3,sticky=W+E)
    size.grid(row = 3,column = 1, columnspan=2, padx=5,pady=3,sticky=W+E)
    
    b = Tix.Label(mem, text="File :")
    file = Tix.FileEntry(mem,command=self.memory_file)
    b.grid(row = 4, column = 0,padx=5,pady=3,sticky=W+E)
    file.grid(row = 4,column = 1, columnspan=2, padx=5,pady=3,sticky=W+E)
    
    add = Tix.Button(top, text="Add", command=self.memory_add)
    reset = Tix.Button(top, text="Reset", command=self.memory_reset)
    ok = Tix.Button(top, text="OK",command=self.memory_ok)
      
      
    map.add_command("I",label="I")
    map.add_command("M",label="M")
    
    type.add_command("R",label="R")
    type.add_command("W",label="W")
    type.add_command("RW",label="RW")
    
    addr.insert(Tix.END,"0x00000000")
    
    size.insert(Tix.END,"0x00000000")
    
    
    mem.grid(row = 0, column = 0, columnspan=3,padx=5,pady=10,sticky=N+S+W+E)
    add.grid(row = 1, column = 0,padx=5,pady=10,sticky=W+E)
    reset.grid(row =1, column = 1,padx=5,pady=10,sticky=W+E)
    ok.grid(row =1, column = 2,padx=5,pady=10,sticky=W+E)

    self.skyeye_redobody()
  
  def memory_map(self,event=None):
    self.map = str(event)
    
  def memory_type(self,event=None):
    self.type = str(event)
    
  def memory_addr(self,event=None):
    self.addr = str(event)
    
  def memory_size(self,event=None):
    self.size = str(event)
  
  def memory_file(self,event=None):
    self.file = str(event)
    
  def memory_add(self,event=None):
    x = {}
    
    if self.map != "":
      x["map"] = self.map
    else:
      self.message("map is not filled yet")
      return 
    
    if self.type != "":
      x["type"] = self.type
    else:
      self.message("map is not filled yet")
      return 
    
    if self.addr != "":
      x["addr"] = self.addr
    else:
      self.message("address is not filled yet")
      return 
    
    if self.size != "":
      x["size"] = self.size
    else:
      self.message("size is not filled yet")
      return 
    
    x["file"] = self.file
    
    self.membank.append(x)
    
    str = ""
    for x in self.membank:
      str += "membank:"
      
      str += "map="+x["map"]+","
      str += "type="+x["type"]+","
      str += "addr="+x["addr"]+","
      str += "size="+x["size"]
      
      if x["file"] != "":
        str += ",file="+x["file"]
      str += "\n"
        
    self.memory_info = str
    self.show_memory()
    
  def memory_reset(self,event=None):
    self.memory_info = ""
    self.membank = []
    self.message("Memory information is reseted")
  
  def memory_ok(self,event=None):
    self.memory_once = 1
    
    top = self.skyeye_body("Memory")
    
    tmp = Tix.Frame(top)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Below are the information of memory:')
    b.grid( row =0 ,padx=5,pady=3,sticky=W+E)
    
    str = ""
    for x in self.membank:
      str += "membank:"
      
      str += "map="+x["map"]+","
      str += "type="+x["type"]+","
      str += "addr="+x["addr"]+","
      str += "size="+x["size"]
      
      if x["file"] != "":
        str += ",file="+x["file"]
      str += "\n"
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='%s'%str)
    b.grid( row =1 ,padx=5,pady=3,sticky=W+E)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Would you want to reset?')
    b.grid( row =2 ,padx=5,pady=3,sticky=W+E)
    
    reset = Tix.Button(tmp, text="OK", command=self.reset_memory, width = 5, bg="red",fg="white")
    reset.grid( row = 3,padx=5,pady=3)
    
    tmp.grid(padx=5,pady=10)
    
    self.message("Memory information is :\n"+str)
    
    self.skyeye_redobody() 
    
  def reset_memory(self):
    self.memory_once = 0
    self.view_memory()
    
  def show_memory(self):
    self.message(self.memory_info)
  
  def view_info(self):
    top = self.skyeye_body("System information")
    
    tmp = Tix.Frame(top,padx=10,pady=15)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Below are the information of the whole system:')
    b.grid( row =0 ,padx=5,pady=3,sticky=W+E)
    
    str = ""
    
    str += "Cpu \t\t: %s\n"%self.cpu
    str += "Mainboard \t: %s\n"%self.board
    str += "Net \t\t: %s\n"%self.net
    str += "Lcd \t\t: %s\n"%self.lcd
    str += "Flash \t\t: %s\n"%self.flash
    
    for x in self.membank:
      str += "membank \t : "
      
      str += "map="+x["map"]+","
      str += "type="+x["type"]+","
      str += "addr="+x["addr"]+","
      str += "size="+x["size"]
      
      if x["file"] != "":
        str += ",file="+x["file"]
      str += "\n"
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='%s'%str)
    b.grid( row =1 ,padx=5,pady=3,sticky=W+E)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Would you want to reset ALL?')
    b.grid( row =2 ,padx=5,pady=3,sticky=W+E)
    
    reset = Tix.Button(tmp, text="OK", command=self.reset_all, width = 5, bg="red",fg="white")
    reset.grid( row = 3,padx=5,pady=3)
    
    tmp.grid(padx=5,pady=25)
    
    self.message("System information is :\n"+str)
    
    self.skyeye_redobody() 
  
  def reset_all(self):
    self.cpu_once = 0
    self.device_once = 0
    self.memory_once = 0
    self.cpu = ""
    self.board=""
    self.net = ""
    self.lcd = ""
    self.flash = ""
    self.map = ""
    self.type = ""
    self.addr = ""
    self.size = ""
    self.file = ""
    self.membank = []
    self.memory_info = ""
    self.welcome()
    self.message("All information has been reset")
    
  def project_new(self):
    self.reset_all()
    self.message("A new project is open")
  
  def project_save(self):
    if self.cpu_once == 0:
      self.message("Cpu and Mainboard is not chosen yet")
      self.welcome()
      return
    if self.device_once == 0:
      self.message("Peripherial is not chosen yet")
      self.welcome()
      return
    if self.memory_once == 0:
      self.message("Memory is not chose yet")
      self.welcome()
      return
    
    try:
      tmp_fd = open("skyeye.conf.koo","w")
      
    except:
      self.message("./skyeye.conf.koo write failure")
      return
    
    top = self.skyeye_body("Write configuration file")
    
    tmp = Tix.Frame(top,padx=10,pady=25)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Below are the saved information:')
    b.grid( row =0 ,padx=5,pady=3,sticky=W+E)
    
    str = "cpu\t:" + self.cpu + "\n"
    str += "mach\t:"+ self.board + "\n"
    
    for x in self.membank:
      tmpp = "membank\t:map=" + x["map"] +",type=" +x["type"] + ",addr=" + x["addr"] + ",size=" + x["size"]
      if x["file"] != "":
        tmpp += ",file=" + x["file"]
      str += tmpp + "\n"
    
    if self.lcd != "":
      str += "lcd\t:state=on,type="+self.lcd+",mode=gtk\n"
    
    if self.net!= "":
      pass # i have to find one demo ...
    
    str += "dbct\t:state=on\n"
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='%s'%str)
    b.grid( row =1 ,padx=5,pady=3,sticky=W+E)
    
    tmp_fd.write(str)
    
    tmp.grid(padx=5,pady=25)
    
    self.message("Information has been written to ./skyeye.conf.koo")
    
    self.skyeye_redobody() 
    
  def execute_compile(self):
    pass
  
  def execute_compilecurrentfile(self):
    pass
  
  def execute_run(self):
    top = self.skyeye_body("Start running skyeye")
    
    tmp = Tix.Frame(top,padx=10,pady=15)
    
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=240, anchor=Tix.N,
                text='Below are the command to skyeye:')
    b.grid( row =0 ,padx=5,pady=15,sticky=W+E)
    tmp.grid(row =0,column =0,padx=5,pady=15,sticky=W+E)
    
    tmp = Tix.Frame(top,padx=10,pady=15)
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='skyeye')
    b.grid( row =0 ,column =0,padx=5,pady=3,sticky=W+E)
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='-e')
    b.grid( row =0 ,column =1,padx=5,pady=3,sticky=W+E)
    b = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='-c')
    b.grid( row =1 ,column =1,padx=5,pady=3,sticky=W+E)
    self.image_path = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='vmlinux')
    self.image_path.grid( row =0 ,column =2,padx=5,pady=3,sticky=W)
    self.conf_path = Tix.Message(tmp, 
                relief=Tix.FLAT, width=440, anchor=Tix.N,
                text='skyeye.conf')
    self.conf_path.grid( row =1 ,column =2,padx=5,pady=3,sticky=W)
    
    file = Tix.FileEntry(tmp,command=self.image_path_do)
    file.grid( row = 0, column =3,padx=5,pady=3,sticky=W+E)
    file = Tix.FileEntry(tmp,command=self.conf_path_do)
    file.grid( row = 1, column =3,padx=5,pady=3,sticky=W+E)
    
    tmp.grid(row =1,column =0,padx=5,pady=10,sticky=W+E)
    
    tmp = Tix.Frame(top,padx=10,pady=15)
    
    tmp.grid(row =2,column =0,padx=5,pady=10,sticky=W+E)
    
    self.run = Tix.Button(tmp, text="Run", command=self.run_skyeye)
    self.kill = Tix.Button(tmp, text="Kill", command=self.kill_skyeye)
    self.kill.config(state=DISABLED)
    
    self.run.grid( row = 0, column =0,padx=5,pady=3,sticky=W+E)
    self.kill.grid( row = 0, column =1,padx=5,pady=3,sticky=W+E)
    
    self.skyeye_redobody()
    
  def image_path_do(self,event=None):
    if str(event) != "":
      self.image_path.config(text=str(event))
  
  def conf_path_do(self,event=None):
    if str(event) != "":
      self.conf_path.config(text=str(event))
  
  def run_skyeye(self):
    if self.is_running == 1:   
      self.run.config(state=DISABLED)
      self.kill.config(bg="red",fg="white")
      return
      
    self.run.config(state=DISABLED)
    path = "skyeye.exe -e " + self.image_path["text"] + " -c " + self.conf_path["text"]
    try:
      skyeye_process = subprocess.Popen(path)
      self.skyeye_id = skyeye_process.pid
      self.kill.config(state=NORMAL)
    except:
      pass
      
      
  def kill_skyeye(self):
    handle = win32api.OpenProcess(1,0,self.skyeye_id)
    win32process.TerminateProcess(handle,0)
    self.is_running = 0    
    self.run.config(state=NORMAL)
    self.kill.config(state=DISABLED)

    
  def execute_compileandrun(self):
    pass
  
  def execute_rebuildall(self):
    pass
  
  def execute_clean(self):
    pass
  
  def tools_compileroption(self):
    pass
  
  def tools_linkeroption(self):
    pass
  
  def tools_makefileoption(self):
    pass
  
  def window_max(self):
    pass
  
  def window_restore(self):
    pass
  
  
  def help_about(self):
    print "in help about"
  
  def destroy (self):
    self.root.destroy()
    
if __name__ == '__main__':
  try:
    root = Tix.Tk()
    test = skyeye(root)
    root.mainloop()
  except:
    pass