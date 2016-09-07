
Namespace sdl2

#Import "<libdl.a>"

'#Import "SDL/jniLibs/armeabi-v7a/libSDL2.so"

#Import "SDL/src/main/android/SDL_android_main.c"

#rem
SDL.c                                
SDL_assert.c                         
SDL_error.c                          
SDL_hints.c                          
SDL_log.c                            
SDL_audio.c                          
SDL_audiocvt.c                       
SDL_audiodev.c                       
SDL_audiotypecvt.c                   
SDL_mixer.c                          
SDL_wave.c                           
SDL_androidaudio.c                   
SDL_dummyaudio.c                     
SDL_atomic.c                         
SDL_spinlock.c                       
SDL_android.c                        
SDL_cpuinfo.c                        
SDL_dynapi.c                         
SDL_clipboardevents.c                
SDL_dropevents.c                     
SDL_events.c                         
SDL_gesture.c                        
SDL_keyboard.c                       
SDL_mouse.c                          
SDL_quit.c                           
SDL_touch.c                          
SDL_windowevents.c                   
SDL_rwops.c                          
SDL_haptic.c                         
SDL_syshaptic.c                      
SDL_gamecontroller.c                 
SDL_joystick.c                       
SDL_sysjoystick.c                    
SDL_sysloadso.c                      
SDL_power.c                          
SDL_syspower.c                       
SDL_sysfilesystem.c                  
SDL_d3dmath.c                        
SDL_render.c                         
SDL_yuv_mmx.c                        
SDL_yuv_sw.c                         
SDL_render_d3d.c                     
SDL_render_d3d11.c                   
SDL_render_gl.c                      
SDL_shaders_gl.c                     
SDL_render_gles.c                    
SDL_render_gles2.c                   
es2funcs.h: In function 'GLES2_LoadFu
nder_gles2.c:294:45: warning: assignm
ms) data->func=func;                 
              ^                      
es2funcs.h:56:1: note: in expansion o
 (GLuint, GLsizei, const GLchar* cons
                                     
SDL_shaders_gles2.c                  
SDL_render_psp.c                     
SDL_blendfillrect.c                  
SDL_blendline.c                      
SDL_blendpoint.c                     
SDL_drawline.c                       
SDL_drawpoint.c                      
SDL_render_sw.c                      
SDL_rotate.c                         
SDL_getenv.c                         
SDL_iconv.c                          
SDL_malloc.c                         
SDL_qsort.c                          
SDL_stdlib.c                         
SDL_string.c                         
SDL_thread.c                         
SDL_syscond.c                        
SDL_sysmutex.c                       
SDL_syssem.c                         
SDL_systhread.c                      
SDL_systls.c                         
SDL_timer.c                          
SDL_systimer.c                       
SDL_RLEaccel.c                       
SDL_blit.c                           
SDL_blit_0.c                         
SDL_blit_1.c                         
SDL_blit_A.c                         
SDL_blit_N.c                         
SDL_blit_auto.c                      
SDL_blit_copy.c                      
SDL_blit_slow.c                      
SDL_bmp.c                            
SDL_clipboard.c                      
SDL_egl.c                            
SDL_fillrect.c                       
SDL_pixels.c                         
SDL_rect.c                           
SDL_shape.c                          
SDL_stretch.c                        
SDL_surface.c                        
SDL_video.c                          
SDL_androidclipboard.c               
SDL_androidevents.c                  
SDL_androidgl.c                      
SDL_androidkeyboard.c                
SDL_androidmessagebox.c              
SDL_androidmouse.c                   
SDL_androidtouch.c                   
SDL_androidvideo.c                   
SDL_androidwindow.c                  
SDL_test_assert.c                    
SDL_test_common.c                    
SDL_test_compare.c                   
SDL_test_crc32.c                     
SDL_test_font.c                      
SDL_test_fuzzer.c                    
SDL_test_harness.c                   
SDL_test_imageBlit.c                 
SDL_test_imageBlitBlend.c            
SDL_test_imageFace.c                 
SDL_test_imagePrimitives.c           
SDL_test_imagePrimitivesBlend.c      
SDL_test_log.c                       
SDL_test_md5.c                       
SDL_test_random.c                    
#end

#rem
	$(wildcard $(LOCAL_PATH)/src/*.c) \
	$(wildcard $(LOCAL_PATH)/src/audio/*.c) \
	$(wildcard $(LOCAL_PATH)/src/audio/android/*.c) \
	$(wildcard $(LOCAL_PATH)/src/audio/dummy/*.c) \
	$(LOCAL_PATH)/src/atomic/SDL_atomic.c \
	$(LOCAL_PATH)/src/atomic/SDL_spinlock.c.arm \
	$(wildcard $(LOCAL_PATH)/src/core/android/*.c) \
	$(wildcard $(LOCAL_PATH)/src/cpuinfo/*.c) \
	$(wildcard $(LOCAL_PATH)/src/dynapi/*.c) \
	$(wildcard $(LOCAL_PATH)/src/events/*.c) \
	$(wildcard $(LOCAL_PATH)/src/file/*.c) \
	$(wildcard $(LOCAL_PATH)/src/haptic/*.c) \
	$(wildcard $(LOCAL_PATH)/src/haptic/dummy/*.c) \
	$(wildcard $(LOCAL_PATH)/src/joystick/*.c) \
	$(wildcard $(LOCAL_PATH)/src/joystick/android/*.c) \
	$(wildcard $(LOCAL_PATH)/src/loadso/dlopen/*.c) \
	$(wildcard $(LOCAL_PATH)/src/power/*.c) \
	$(wildcard $(LOCAL_PATH)/src/power/android/*.c) \
	$(wildcard $(LOCAL_PATH)/src/filesystem/android/*.c) \
	$(wildcard $(LOCAL_PATH)/src/render/*.c) \
	$(wildcard $(LOCAL_PATH)/src/render/*/*.c) \
	$(wildcard $(LOCAL_PATH)/src/stdlib/*.c) \
	$(wildcard $(LOCAL_PATH)/src/thread/*.c) \
	$(wildcard $(LOCAL_PATH)/src/thread/pthread/*.c) \
	$(wildcard $(LOCAL_PATH)/src/timer/*.c) \
	$(wildcard $(LOCAL_PATH)/src/timer/unix/*.c) \
	$(wildcard $(LOCAL_PATH)/src/video/*.c) \
	$(wildcard $(LOCAL_PATH)/src/video/android/*.c) \
	$(wildcard $(LOCAL_PATH)/src/test/*.c))

#end

#Import "SDL/src/SDL_assert.c"
#Import "SDL/src/SDL_error.c"
#Import "SDL/src/SDL_hints.c"
#Import "SDL/src/SDL_log.c"
#Import "SDL/src/SDL.c"

#Import "SDL/src/audio/SDL_audio.c"
#Import "SDL/src/audio/SDL_audiocvt.c"
#Import "SDL/src/audio/SDL_audiodev.c"
#Import "SDL/src/audio/SDL_audiotypecvt.c"
#Import "SDL/src/audio/SDL_mixer.c"
#Import "SDL/src/audio/SDL_wave.c"
#Import "SDL/src/audio/android/SDL_androidaudio.c"
#Import "SDL/src/audio/dummy/SDL_dummyaudio.c"

#Import "SDL/src/atomic/SDL_atomic.c"
#Import "SDL/src/atomic/SDL_spinlock.c"

#Import "SDL/src/core/android/SDL_android.c"

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

#Import "SDL/src/file/SDL_rwops.c"

#Import "SDL/src/filesystem/android/SDL_sysfilesystem.c"

#Import "SDL/src/haptic/SDL_haptic.c"
#Import "SDL/src/haptic/dummy/SDL_syshaptic.c"

#Import "SDL/src/joystick/SDL_gamecontroller.c"
#Import "SDL/src/joystick/SDL_joystick.c"
#Import "SDL/src/joystick/android/SDL_sysjoystick.c"

#Import "SDL/src/loadso/dlopen/SDL_sysloadso.c"

#Import "SDL/src/power/SDL_power.c"
#Import "SDL/src/power/android/SDL_syspower.c"

#Import "SDL/src/render/SDL_render.c"
#Import "SDL/src/render/opengl/SDL_render_gl.c"
#Import "SDL/src/render/opengl/SDL_shaders_gl.c"
#Import "SDL/src/render/opengles/SDL_render_gles.c"
#Import "SDL/src/render/opengles2/SDL_render_gles2.c"
#Import "SDL/src/render/opengles2/SDL_shaders_gles2.c"

#Import "SDL/src/render/SDL_yuv_mmx.c"
#Import "SDL/src/render/SDL_yuv_sw.c"
#Import "SDL/src/render/software/SDL_blendfillrect.c"
#Import "SDL/src/render/software/SDL_blendline.c"
#Import "SDL/src/render/software/SDL_blendpoint.c"
#Import "SDL/src/render/software/SDL_drawline.c"
#Import "SDL/src/render/software/SDL_drawpoint.c"
#Import "SDL/src/render/software/SDL_render_sw.c"
#Import "SDL/src/render/software/SDL_rotate.c"

#Import "SDL/src/stdlib/SDL_getenv.c"
#Import "SDL/src/stdlib/SDL_iconv.c"
#Import "SDL/src/stdlib/SDL_malloc.c"
#Import "SDL/src/stdlib/SDL_qsort.c"
#Import "SDL/src/stdlib/SDL_stdlib.c"
#Import "SDL/src/stdlib/SDL_string.c"

#Import "SDL/src/thread/SDL_thread.c"
#Import "SDL/src/thread/pthread/SDL_syscond.c"
#Import "SDL/src/thread/pthread/SDL_sysmutex.c"
#Import "SDL/src/thread/pthread/SDL_syssem.c"
#Import "SDL/src/thread/pthread/SDL_systhread.c"
#Import "SDL/src/thread/pthread/SDL_systls.c"

#Import "SDL/src/timer/SDL_timer.c"
#Import "SDL/src/timer/unix/SDL_systimer.c"

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
#Import "SDL/src/video/SDL_egl.c"
#Import "SDL/src/video/SDL_fillrect.c"
#Import "SDL/src/video/SDL_pixels.c"
#Import "SDL/src/video/SDL_rect.c"
#Import "SDL/src/video/SDL_RLEaccel.c"
#Import "SDL/src/video/SDL_shape.c"
#Import "SDL/src/video/SDL_stretch.c"
#Import "SDL/src/video/SDL_surface.c"
#Import "SDL/src/video/SDL_video.c"
#Import "SDL/src/video/android/SDL_androidclipboard.c"
#Import "SDL/src/video/android/SDL_androidevents.c"
#Import "SDL/src/video/android/SDL_androidgl.c"
#Import "SDL/src/video/android/SDL_androidkeyboard.c"
#Import "SDL/src/video/android/SDL_androidmessagebox.c"
#Import "SDL/src/video/android/SDL_androidmouse.c"
#Import "SDL/src/video/android/SDL_androidtouch.c"
#Import "SDL/src/video/android/SDL_androidvideo.c"
#Import "SDL/src/video/android/SDL_androidwindow.c"
#Import "SDL/src/video/dummy/SDL_nullevents.c"
#Import "SDL/src/video/dummy/SDL_nullframebuffer.c"
#Import "SDL/src/video/dummy/SDL_nullvideo.c"
