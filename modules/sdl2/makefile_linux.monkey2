
Namespace sdl2

#Import "<libpthread.a>"
#Import "<libdl.a>"
#Import "<libX11.a>"
#Import "<libXext.a>"
#Import "<libXi.a>"
#Import "<libpulse.a>"

'source files
#Import "SDL/src/atomic/SDL_atomic.c"
#Import "SDL/src/atomic/SDL_spinlock.c"

#Import "SDL/src/audio/disk/SDL_diskaudio.c"

#Import "SDL/src/audio/dummy/SDL_dummyaudio.c"
#Import "SDL/src/audio/pulseaudio/SDL_pulseaudio.c"
'#Import "SDL/src/audio/dsp/SDL_dspaudio.c"

#Import "SDL/src/audio/SDL_audio.c"
#Import "SDL/src/audio/SDL_audiocvt.c"
#Import "SDL/src/audio/SDL_audiodev.c"
#Import "SDL/src/audio/SDL_audiotypecvt.c"
#Import "SDL/src/audio/SDL_mixer.c"
#Import "SDL/src/audio/SDL_wave.c"

#Import "SDL/src/cpuinfo/SDL_cpuinfo.c"

#Import "SDL/src/dynapi/SDL_dynapi.c"

#Import "SDL/src/events/SDL_clipboardevents.c"
#Import "SDL/src/events/SDL_dropevents.c"
#Import "SDL/src/events/SDL_events.c"
#Import "SDL/src/events/SDL_gesture.c"
#Import "SDL/src/events/SDL_keyboard.c"
#Import "SDL/src/events/SDL_mouse.c"
#Import "SDL/src/events/SDL_quit.c"
#Import "SDL/src/events/SDL_touch.c"
#Import "SDL/src/events/SDL_windowevents.c"

#Import "SDL/src/filesystem/unix/SDL_sysfilesystem.c"

#Import "SDL/src/file/SDL_rwops.c"

#Import "SDL/src/haptic/linux/SDL_syshaptic.c"

#Import "SDL/src/haptic/SDL_haptic.c"

#Import "SDL/src/joystick/linux/SDL_sysjoystick.c"

#Import "SDL/src/joystick/SDL_joystick.c"
#Import "SDL/src/joystick/SDL_gamecontroller.c"

#Import "SDL/src/loadso/dlopen/SDL_sysloadso.c"

#Import "SDL/src/power/macosx/SDL_syspower.c"

#Import "SDL/src/power/SDL_power.c"

'#Import "SDL/src/render/opengl/SDL_render_gl.c"
'#Import "SDL/src/render/opengl/SDL_shaders_gl.c"

#Import "SDL/src/render/software/SDL_blendfillrect.c"
#Import "SDL/src/render/software/SDL_blendline.c"
#Import "SDL/src/render/software/SDL_blendpoint.c"
#Import "SDL/src/render/software/SDL_drawline.c"
#Import "SDL/src/render/software/SDL_drawpoint.c"
#Import "SDL/src/render/software/SDL_render_sw.c"
#Import "SDL/src/render/software/SDL_rotate.c"

#Import "SDL/src/render/SDL_render.c"
#Import "SDL/src/render/SDL_yuv_mmx.c"
#Import "SDL/src/render/SDL_yuv_sw.c"

#Import "SDL/src/stdlib/SDL_getenv.c"
#Import "SDL/src/stdlib/SDL_iconv.c"
#Import "SDL/src/stdlib/SDL_malloc.c"
#Import "SDL/src/stdlib/SDL_qsort.c"
#Import "SDL/src/stdlib/SDL_stdlib.c"
#Import "SDL/src/stdlib/SDL_string.c"

#Import "SDL/src/thread/pthread/SDL_syscond.c"
#Import "SDL/src/thread/pthread/SDL_sysmutex.c"
#Import "SDL/src/thread/pthread/SDL_syssem.c"
#Import "SDL/src/thread/pthread/SDL_systhread.c"
#Import "SDL/src/thread/pthread/SDL_systls.c"

#Import "SDL/src/thread/SDL_thread.c"

#Import "SDL/src/timer/unix/SDL_systimer.c"

#Import "SDL/src/timer/SDL_timer.c"

#Import "SDL/src/video/dummy/SDL_nullevents.c"
#Import "SDL/src/video/dummy/SDL_nullframebuffer.c"
#Import "SDL/src/video/dummy/SDL_nullvideo.c"

#Import "SDL/src/video/x11/imKStoUCS.c"
#Import "SDL/src/video/x11/SDL_x11clipboard.c"
#Import "SDL/src/video/x11/SDL_x11dyn.c"
#Import "SDL/src/video/x11/SDL_x11events.c"
#Import "SDL/src/video/x11/SDL_x11framebuffer.c"
#Import "SDL/src/video/x11/SDL_x11keyboard.c"
#Import "SDL/src/video/x11/SDL_x11messagebox.c"
#Import "SDL/src/video/x11/SDL_x11modes.c"
#Import "SDL/src/video/x11/SDL_x11mouse.c"
#Import "SDL/src/video/x11/SDL_x11opengl.c"
#Import "SDL/src/video/x11/SDL_x11opengles.c"
#Import "SDL/src/video/x11/SDL_x11shape.c"
#Import "SDL/src/video/x11/SDL_x11touch.c"
#Import "SDL/src/video/x11/SDL_x11video.c"
#Import "SDL/src/video/x11/SDL_x11window.c"
#Import "SDL/src/video/x11/SDL_x11xinput2.c"

#Import "SDL/src/video/SDL_blit.c"
#Import "SDL/src/video/SDL_blit_0.c"
#Import "SDL/src/video/SDL_blit_1.c"
#Import "SDL/src/video/SDL_blit_A.c"
#Import "SDL/src/video/SDL_blit_auto.c"
#Import "SDL/src/video/SDL_blit_copy.c"
#Import "SDL/src/video/SDL_blit_N.c"
#Import "SDL/src/video/SDL_blit_slow.c"
#Import "SDL/src/video/SDL_bmp.c"
#Import "SDL/src/video/SDL_clipboard.c"
#Import "SDL/src/video/SDL_fillrect.c"
#Import "SDL/src/video/SDL_pixels.c"
#Import "SDL/src/video/SDL_rect.c"
#Import "SDL/src/video/SDL_RLEaccel.c"
#Import "SDL/src/video/SDL_shape.c"
#Import "SDL/src/video/SDL_stretch.c"
#Import "SDL/src/video/SDL_surface.c"
#Import "SDL/src/video/SDL_video.c"

#Import "SDL/src/SDL_assert.c"
#Import "SDL/src/SDL_error.c"
#Import "SDL/src/SDL_hints.c"
#Import "SDL/src/SDL_log.c"
#Import "SDL/src/SDL.c"
