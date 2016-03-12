
Namespace sdl2

#import "<libdsound.a>"
#import "<libxinput.a>"
#import "<libdinput.a>"

#import "<libole32.a>"
#import "<liboleaut32.a>"
#import "<libimm32.a>"
#import "<libwinmm.a>"
#import "<libgdi32.a>"
#import "<libuser32.a>"
#import "<libkernel32.a>"
#import "<libversion.a>"

'source files
#import "SDL/src/atomic/SDL_atomic.c"
#import "SDL/src/atomic/SDL_spinlock.c"

#import "SDL/src/audio/disk/SDL_diskaudio.c"

#import "SDL/src/audio/dummy/SDL_dummyaudio.c"

#Import "SDL/src/audio/directsound/SDL_directsound.c"
'#Import "SDL/src/audio/xaudio2/SDL_xaudio2.c"	'xaudio2.h is missing from MINGW!
'#import "SDL/src/audio/winmm/SDL_winmm.c"

#import "SDL/src/audio/SDL_audio.c"
#import "SDL/src/audio/SDL_audiocvt.c"
#import "SDL/src/audio/SDL_audiodev.c"
#import "SDL/src/audio/SDL_audiotypecvt.c"
#import "SDL/src/audio/SDL_mixer.c"
#import "SDL/src/audio/SDL_wave.c"

#import "SDL/src/core/windows/SDL_windows.c"
#import "SDL/src/core/windows/SDL_xinput.c"

#import "SDL/src/cpuinfo/SDL_cpuinfo.c"

#import "SDL/src/dynapi/SDL_dynapi.c"

#import "SDL/src/events/SDL_clipboardevents.c"
#Import "SDL/src/events/SDL_dropevents.c"
#import "SDL/src/events/SDL_events.c"
#import "SDL/src/events/SDL_gesture.c"
#import "SDL/src/events/SDL_keyboard.c"
#import "SDL/src/events/SDL_mouse.c"
#import "SDL/src/events/SDL_quit.c"
#import "SDL/src/events/SDL_touch.c"
#import "SDL/src/events/SDL_windowevents.c"

#import "SDL/src/filesystem/windows/SDL_sysfilesystem.c"

#import "SDL/src/file/SDL_rwops.c"

#import "SDL/src/haptic/windows/SDL_dinputhaptic.c"
#import "SDL/src/haptic/windows/SDL_windowshaptic.c"
#import "SDL/src/haptic/windows/SDL_xinputhaptic.c"

#import "SDL/src/haptic/SDL_haptic.c"

#import "SDL/src/joystick/windows/SDL_dinputjoystick.c"
#import "SDL/src/joystick/windows/SDL_mmjoystick.c"
#import "SDL/src/joystick/windows/SDL_windowsjoystick.c"
#import "SDL/src/joystick/windows/SDL_xinputjoystick.c"

#import "SDL/src/joystick/SDL_joystick.c"
#Import "SDL/src/joystick/SDL_gamecontroller.c"

#import "SDL/src/loadso/windows/SDL_sysloadso.c"

#import "SDL/src/power/windows/SDL_syspower.c"

#import "SDL/src/power/SDL_power.c"

#Import "SDL/src/render/opengl/SDL_render_gl.c"
#Import "SDL/src/render/opengl/SDL_shaders_gl.c"

#Import "SDL/src/render/opengles2/SDL_render_gles2.c"
#Import "SDL/src/render/opengles2/SDL_shaders_gles2.c"

#Import "SDL/src/render/direct3d/SDL_render_d3d.c"
#Import "SDL/src/render/direct3d11/SDL_render_d3d11.c"

#import "SDL/src/render/software/SDL_blendfillrect.c"
#import "SDL/src/render/software/SDL_blendline.c"
#import "SDL/src/render/software/SDL_blendpoint.c"
#import "SDL/src/render/software/SDL_drawline.c"
#import "SDL/src/render/software/SDL_drawpoint.c"
#import "SDL/src/render/software/SDL_render_sw.c"
#import "SDL/src/render/software/SDL_rotate.c"

#import "SDL/src/render/SDL_d3dmath.c"
#import "SDL/src/render/SDL_render.c"
#import "SDL/src/render/SDL_yuv_mmx.c"
#import "SDL/src/render/SDL_yuv_sw.c"

#Import "SDL/src/stdlib/SDL_getenv.c"
#import "SDL/src/stdlib/SDL_iconv.c"
#import "SDL/src/stdlib/SDL_malloc.c"
#import "SDL/src/stdlib/SDL_qsort.c"
#Import "SDL/src/stdlib/SDL_stdlib.c"
#import "SDL/src/stdlib/SDL_string.c"

#import "SDL/src/thread/generic/SDL_syscond.c"

#import "SDL/src/thread/windows/SDL_sysmutex.c"
#import "SDL/src/thread/windows/SDL_syssem.c"
#import "SDL/src/thread/windows/SDL_systhread.c"
#import "SDL/src/thread/windows/SDL_systls.c"

#import "SDL/src/thread/SDL_thread.c"

#import "SDL/src/timer/windows/SDL_systimer.c"

#import "SDL/src/timer/SDL_timer.c"

#import "SDL/src/video/windows/SDL_windowsclipboard.c"
#import "SDL/src/video/windows/SDL_windowsevents.c"
#import "SDL/src/video/windows/SDL_windowsframebuffer.c"
#import "SDL/src/video/windows/SDL_windowskeyboard.c"
#import "SDL/src/video/windows/SDL_windowsmessagebox.c"
#import "SDL/src/video/windows/SDL_windowsmodes.c"
#import "SDL/src/video/windows/SDL_windowsmouse.c"
#Import "SDL/src/video/windows/SDL_windowsopengl.c"
#import "SDL/src/video/windows/SDL_windowsopengles.c"
#import "SDL/src/video/windows/SDL_windowsshape.c"
#import "SDL/src/video/windows/SDL_windowsvideo.c"
#import "SDL/src/video/windows/SDL_windowswindow.c"

#import "SDL/src/video/dummy/SDL_nullevents.c"
#import "SDL/src/video/dummy/SDL_nullframebuffer.c"
#import "SDL/src/video/dummy/SDL_nullvideo.c"

#import "SDL/src/video/SDL_blit.c"
#import "SDL/src/video/SDL_blit_0.c"
#import "SDL/src/video/SDL_blit_1.c"
#Import "SDL/src/video/SDL_blit_A.c"
#import "SDL/src/video/SDL_blit_auto.c"
#import "SDL/src/video/SDL_blit_copy.c"
#import "SDL/src/video/SDL_blit_N.c"
#import "SDL/src/video/SDL_blit_slow.c"
#Import "SDL/src/video/SDL_bmp.c"
#Import "SDL/src/video/SDL_clipboard.c"
#Import "SDL/src/video/SDL_egl.c"
#Import "SDL/src/video/SDL_fillrect.c"
#import "SDL/src/video/SDL_pixels.c"
#import "SDL/src/video/SDL_rect.c"
#import "SDL/src/video/SDL_RLEaccel.c"
#import "SDL/src/video/SDL_shape.c"
#import "SDL/src/video/SDL_stretch.c"
#import "SDL/src/video/SDL_surface.c"
#import "SDL/src/video/SDL_video.c"

#Import "SDL/src/SDL_assert.c"
#import "SDL/src/SDL_error.c"
#import "SDL/src/SDL_hints.c"
#import "SDL/src/SDL_log.c"
#Import "SDL/src/SDL.c"

'Really?!?...
#import "SDL/src/libm/e_atan2.c"
#import "SDL/src/libm/e_log.c"
#import "SDL/src/libm/e_pow.c"
#import "SDL/src/libm/e_rem_pio2.c"
#import "SDL/src/libm/e_sqrt.c"
#import "SDL/src/libm/k_cos.c"
#import "SDL/src/libm/k_rem_pio2.c"
#import "SDL/src/libm/k_sin.c"
#import "SDL/src/libm/k_tan.c"
#import "SDL/src/libm/s_atan.c"
#import "SDL/src/libm/s_copysign.c"
#import "SDL/src/libm/s_cos.c"
#import "SDL/src/libm/s_fabs.c"
#import "SDL/src/libm/s_floor.c"
#import "SDL/src/libm/s_scalbn.c"
#import "SDL/src/libm/s_sin.c"
#import "SDL/src/libm/s_tan.c"
