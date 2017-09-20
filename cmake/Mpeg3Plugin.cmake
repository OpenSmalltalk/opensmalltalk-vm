set(LIB_MPEG3_DIR "${CrossPlatformPluginFolder}/Mpeg3Plugin/libmpeg")
set(LIB_MPEG3_SOURCES
    # Video
    "${LIB_MPEG3_DIR}/video/getpicture.c"
    "${LIB_MPEG3_DIR}/video/headers.c"
    "${LIB_MPEG3_DIR}/video/idct.c"
    "${LIB_MPEG3_DIR}/video/macroblocks.c"
    "${LIB_MPEG3_DIR}/video/mmxtest.c"
    "${LIB_MPEG3_DIR}/video/motion.c"
    "${LIB_MPEG3_DIR}/video/mpeg3video.c"
    "${LIB_MPEG3_DIR}/video/output.c"
    "${LIB_MPEG3_DIR}/video/reconstruct.c"
    "${LIB_MPEG3_DIR}/video/seek.c"
    "${LIB_MPEG3_DIR}/video/slice.c"
    "${LIB_MPEG3_DIR}/video//vlc.c"

    # Audio
    "${LIB_MPEG3_DIR}/audio/dct.c"
    "${LIB_MPEG3_DIR}/audio/header.c"
    "${LIB_MPEG3_DIR}/audio/layer1.c"
    "${LIB_MPEG3_DIR}/audio/layer2.c"
    "${LIB_MPEG3_DIR}/audio/layer3.c"
    "${LIB_MPEG3_DIR}/audio/mpeg3audio.c"
    "${LIB_MPEG3_DIR}/audio/pcm.c"
    "${LIB_MPEG3_DIR}/audio/synthesizers.c"
    "${LIB_MPEG3_DIR}/audio/tables.c"

    # Common
    "${LIB_MPEG3_DIR}/bitstream.c"
    "${LIB_MPEG3_DIR}/changesForSqueak.c"
    "${LIB_MPEG3_DIR}/libmpeg3.c"
    "${LIB_MPEG3_DIR}/mpeg3atrack.c"
    "${LIB_MPEG3_DIR}/mpeg3demux.c"
    "${LIB_MPEG3_DIR}/mpeg3io.c"
    "${LIB_MPEG3_DIR}/mpeg3title.c"
    "${LIB_MPEG3_DIR}/mpeg3vtrack.c"
)

include_directories(
    "${CrossPlatformPluginFolder}/Mpeg3Plugin/libmpeg"
    "${CrossPlatformPluginFolder}/Mpeg3Plugin/libmpeg/audio"
    "${CrossPlatformPluginFolder}/Mpeg3Plugin/libmpeg/video"
)
add_vm_plugin_auto(Mpeg3Plugin INTERNAL "${LIB_MPEG3_SOURCES}")
