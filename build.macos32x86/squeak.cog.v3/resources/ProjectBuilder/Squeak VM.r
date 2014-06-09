#include <Carbon.r>

resource 'STR ' (1001, purgeable) {    
   "Squeak, a pure object oriented programming environment "
   "based on Smalltalk-80 and work done at Apple and Disney"
}; 

resource 'open' (128)
{
   'FAST', { '????','****' , 'STim', 'STch', 'SOBJ', 'TEXT', 'HTML', 'RTF ', 'ttro', 'JPEG', 'TIFF', 'PICT',
    'URL ', 'ZIP ', 'zip ', 'BINA', 'GIFf', 'PNGf', 'MP3 ', 'MP3!', 'MP3U', 'MPEG', 'mp3!', 'MPG2', 'MPG3', 
    'MPG ', 'Mp3 ', 'M3U ', 'SRCS', 'Chng', 'HPS5' }
};

resource 'kind' (1000)
{
   'FAST',
   verUS,
   {
      'apnm',      "Squeak",
      'STim',                 "Squeak Image File",
      'STch',                 "Squeak Changes File",
      'SOBJ',                 "Squeak Script File"
   }
};
