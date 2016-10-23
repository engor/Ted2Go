
Namespace emscripten

#If __TARGET__="emscripten"

#Import "<emscripten.h>"

Extern

Alias em_callback_func:Void()
Alias em_arg_callback_func:Void(Void Ptr)
Alias em_str_callback_func:Void(String)

Function emscripten_run_script:Void( script:CString )
Function emscripten_run_script_int:Int( script:CString )
Function emscripten_run_script_string:CString( script:CString )
Function emscripten_async_run_script:Void( script:CString,millis:Int )
Function emscripten_async_load_script:Void( script:CString,onload:em_callback_func,onerror:em_callback_func )
Function emscripten_set_main_loop:Void( func:em_callback_func,fps:Int,simulate_infinite_loop:Int )
Function emscripten_set_main_loop_arg:Void( func:em_callback_func,arg:Void Ptr,fps:Int,simulate_infinite_loop:Int )
Function emscripten_push_main_loop_blocker:Void( func:em_arg_callback_func,arg:Void Ptr )
Function emscripten_push_uncounted_main_loop_blocker:Void( func:em_arg_callback_func,arg:Void Ptr )
Function emscripten_cancel_main_loop:Void()
Function emscripten_set_main_loop_timing:Void( mode:Int,value:Int )
Function emscripten_get_main_loop_timing:Void( mode:Int Ptr,value:Int Ptr )
Function emscripten_set_main_loop_expected_blockers:Void( num:Int )
Function emscripten_async_call:Void( func:em_arg_callback_func,arg:Byte Ptr,millis:Int )
Function emscripten_force_exit:Void( status:Int )
Function emscripten_get_device_pixel_ratio:Double()
Function emscripten_set_canvas_size:Void( width:Int,height:Int )
Function emscripten_get_canvas_size:Void( width:Int Ptr,height:Int Ptr,fullScreen:Int Ptr )
Function emscripten_get_now:Double()

#Endif
