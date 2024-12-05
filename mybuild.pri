QT += network

HEADERS += \
	$$PWD/src/eventdispatcher_libevent.h \
	$$PWD/src/eventdispatcher_libevent_p.h \
	$$PWD/src/eventdispatcher_libevent_config.h \
	$$PWD/src/eventdispatcher_libevent_config_p.h \
	$$PWD/src/libevent2-emul.h \
	$$PWD/src/qt4compat.h \
	$$PWD/src/tco.h \
	$$PWD/src/tco_impl.h \
	$$PWD/src/common.h

SOURCES += \
	$$PWD/src/eventdispatcher_libevent.cpp \
	$$PWD/src/eventdispatcher_libevent_p.cpp \
	$$PWD/src/timers_p.cpp \
	$$PWD/src/socknot_p.cpp \
	$$PWD/src/eventdispatcher_libevent_config.cpp

PRECOMPILED_HEADER = common.h

unix {
    #理论上只会链接tco_eventfd.cpp。下述system代码功能用来检查eventfd.h是否存在并且可以被当前编译器支持
    #eventfd.h 是 Linux 系统中的一个头文件，提供了 eventfd 系统调用，用于线程或进程之间的事件通知，比pipe更高效
    system('cc -E $$PWD/conftests/eventfd.h -o /dev/null 2> /dev/null') {
    message("SOURCES += tco_eventfd.cpp")
            SOURCES += $$PWD/src/tco_eventfd.cpp
    }
    else {
    message("SOURCES += tco_pipe.cpp")
            SOURCES += $$PWD/src/tco_pipe.cpp
    }
}
win32{
    SOURCES += $$PWD/src/tco_win32_libevent.cpp
    HEADERS += $$PWD/src/wsainit.h
}

INCLUDEPATH += $$PWD/src/

##
##必须链接的libevent相关库
##
#---将编译类型存储于一个变量中，所有库都可使用该变量，避免后续的CONFIG(debug, debug|release)代码---
buildType =
CONFIG(debug, debug|release):{
buildType = debug
}else{
buildType = release
}
message("buildType is set to $$buildType")
#----------------------

#---第三方库版本，库版本与编译器有关，编译器一般只用MSVC与GCC的64位版本
_3rdLib_compiler_name =
win32:_3rdLib_compiler_name = MSVC2022_64
unix:_3rdLib_compiler_name = GCC_9_4_64
message("_3rdLib_compiler_name is set to $$_3rdLib_compiler_name")
#----------------------

#---windows MSVC编译的库有时会依赖Visual Studio安装的Windows Kits中的系统库
winKitsLib_ver = 10.0.26100.0
message("winKitsLib_ver is set to $$winKitsLib_ver")
#----------------------

##libevent
libevent_ver = 2_2_1_alpha #2_1_12 #2_2_1_alpha
path_to_libevent = ../libevent
message("libevent_ver is set to $$libevent_ver")
message("path_to_libevent is set to $$path_to_libevent")
##
INCLUDEPATH += $$PWD/$$path_to_libevent/$$libevent_ver/$$_3rdLib_compiler_name/include
win32:LIBS += -L$$PWD/$$path_to_libevent/winKitsLib/$$winKitsLib_ver -lws2_32 -liphlpapi -ladvapi32 -lbcrypt -lshell32
win32:LIBS += -L$$PWD/$$path_to_libevent/$$libevent_ver/$$_3rdLib_compiler_name/lib/$$buildType -levent -levent_core -levent_extra
unix: LIBS += -L$$PWD/$$path_to_libevent/$$libevent_ver/$$_3rdLib_compiler_name/lib/$$buildType -levent -levent_core -levent_extra -levent_pthreads