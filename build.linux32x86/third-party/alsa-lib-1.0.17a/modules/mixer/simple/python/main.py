#!/usr/bin/python
#  -*- coding: utf-8 -*-
#  -*- Python -*-

from os.path import dirname
from pyalsa.alsacontrol import Control
from sys import path
path.insert(0, dirname(__file__))

def alsacode(module):
  execfile(dirname(__file__)+'/'+module+'.py', globals())
  
ctl = Control(device)
info = ctl.cardInfo()
#mixername = info['mixername']
components = info['components']
del ctl

if components.find('HDA:') >= 0:
  module = 'hda'
else:
  raise ValueError, "Mixer for this hardware is not implemented in python"

alsacode(module)
