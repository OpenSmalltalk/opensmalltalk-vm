#!/usr/bin/python
#  -*- coding: utf-8 -*-
#  -*- Python -*-

alsacode('common')

CONTROLS = {
'Headphone Playback Switch//0//'+MIXERS:["Headphone", 0, 1, "StandardElement"],
'IEC958 Playback Switch//0//'+MIXERS:["IEC958", 0, 2, "StandardElement"],
'Front Playback Volume//0//'+MIXERS:["Front", 0, 3, "StandardElement"],
'Front Playback Switch//0//'+MIXERS:["Front", 0, 3, "StandardElement"],
'Surround Playback Volume//0//'+MIXERS:["Surround", 0, 4, "StandardElement"],
'Surround Playback Switch//0//'+MIXERS:["Surround", 0, 4, "StandardElement"],
'Center Playback Volume//0//'+MIXERS:["Center", 0, 5, "StandardElement"],
'Center Playback Switch//0//'+MIXERS:["Center", 0, 5, "StandardElement"],
'LFE Playback Volume//0//'+MIXERS:["LFE", 0, 6, "StandardElement"],
'LFE Playback Switch//0//'+MIXERS:["LFE", 0, 6, "StandardElement"],
'Line Playback Volume//0//'+MIXERS:["Line", 0, 7, "StandardElement"],
'Line Playback Switch//0//'+MIXERS:["Line", 0, 7, "StandardElement"],
'CD Playback Volume//0//'+MIXERS:["CD", 0, 8, "StandardElement"],
'CD Playback Switch//0//'+MIXERS:["CD", 0, 8, "StandardElement"],
'Mic Playback Volume//0//'+MIXERS:["Mic", 0, 9, "StandardElement"],
'Mic Playback Switch//0//'+MIXERS:["Mic", 0, 9, "StandardElement"],
'PC Speaker Playback Volume//0//'+MIXERS:["PC Speaker", 0, 10, "StandardElement"],
'PC Speaker Playback Switch//0//'+MIXERS:["PC Speaker", 0, 10, "StandardElement"],
'Front Mic Playback Volume//0//'+MIXERS:["Front Mic", 0, 11, "StandardElement"],
'Front Mic Playback Switch//0//'+MIXERS:["Front Mic", 0, 11, "StandardElement"],
'Capture Switch//0//'+MIXERS:["Capture", 0, 12, "StandardElement"],
'Capture Volume//0//'+MIXERS:["Capture", 0, 12, "StandardElement"],
'Capture Switch//1//'+MIXERS:["Capture", 1, 13, "StandardElement"],
'Capture Volume//1//'+MIXERS:["Capture", 1, 13, "StandardElement"],
'Capture Switch//2//'+MIXERS:["Capture", 2, 14, "StandardElement"],
'Capture Volume//2//'+MIXERS:["Capture", 2, 14, "StandardElement"],
'Input Source//0//'+MIXERS:["Input Source", 0, 15, "EnumElementCapture"],
'Input Source//1//'+MIXERS:["Input Source", 1, 16, "EnumElementCapture"],
'Input Source//2//'+MIXERS:["Input Source", 2, 17, "EnumElementCapture"],
}

def event(evmask, helem, melem):
  return eventHandler(evmask, helem, melem)

init()
