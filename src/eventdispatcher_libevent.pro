QT      -= gui
TARGET   = eventdispatcher_libevent
TEMPLATE = lib
DESTDIR  = ../lib
CONFIG  += staticlib create_prl precompile_header
# CONFIG  += create_prl precompile_header


HEADERS += \
	eventdispatcher_libevent.h \
	eventdispatcher_libevent_p.h \
	eventdispatcher_libevent_config.h \
	eventdispatcher_libevent_config_p.h \
	libevent2-emul.h \
	qt4compat.h \
	tco.h \
	tco_impl.h \
	common.h

SOURCES += \
	eventdispatcher_libevent.cpp \
	eventdispatcher_libevent_p.cpp \
	timers_p.cpp \
	socknot_p.cpp \
	eventdispatcher_libevent_config.cpp

#预编译头文件，可加快编译速度
PRECOMPILED_HEADER = common.h

#用来定一个变量，随后可被使用
headers.files = eventdispatcher_libevent.h eventdispatcher_libevent_config.h

# CONFIG  -= staticlib

QMAKE_CXXFLAGS_RELEASE = $$QMAKE_CFLAGS_RELEASE_WITH_DEBUGINFO #realease模式下也可以生成pdb文件
QMAKE_LFLAGS_RELEASE = $$QMAKE_LFLAGS_RELEASE_WITH_DEBUGINFO

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
path_to_libevent = ../../libevent
message("libevent_ver is set to $$libevent_ver")
message("path_to_libevent is set to $$path_to_libevent")
##
win32:LIBS += -L$$PWD/$$path_to_libevent/winKitsLib/$$winKitsLib_ver -lws2_32 -liphlpapi -ladvapi32 -lbcrypt -lshell32
INCLUDEPATH += $$PWD/$$path_to_libevent/$$libevent_ver/$$_3rdLib_compiler_name/include
win32:LIBS += -L$$PWD/$$path_to_libevent/$$libevent_ver/$$_3rdLib_compiler_name/lib/$$buildType -levent -levent_core -levent_extra
unix: LIBS += -L$$PWD/$$path_to_libevent/$$libevent_ver/$$_3rdLib_compiler_name/lib/$$buildType -levent -levent_core -levent_extra -levent_pthreads

unix {
    # CONFIG += create_pc

    #理论上只会链接tco_eventfd.cpp。下述system代码功能是检查 eventfd.h 文件是否可以被预处理器正确处理
    #若可以，则也说明eventfd.h存在并且可以被当前编译器支持
    #eventfd.h 是 Linux 系统中的一个头文件，提供了 eventfd 系统调用，用于线程或进程之间的事件通知。
    #如果系统支持 eventfd.h，可以使用更高效的 eventfd 实现（如 tco_eventfd.cpp）。
    #如果系统不支持 eventfd.h（例如在非 Linux 系统上），则需要使用其他方式实现相同功能（如基于管道的实现 tco_pipe.cpp）。
    system('cc -E $$PWD/conftests/eventfd.h -o /dev/null 2> /dev/null') {
    message("SOURCES += tco_eventfd.cpp")
            SOURCES += tco_eventfd.cpp
    }
    else {
    message("SOURCES += tco_pipe.cpp")
            SOURCES += tco_pipe.cpp
    }

    # system('pkg-config --exists libevent') {
    # message("pkg-config --exists libevent")
    #         CONFIG    += link_pkgconfig
    #         PKGCONFIG += libevent
    # }
    # else {
    # message("pkg-config --exists libevent else")
    #         system('cc -E $$PWD/conftests/libevent2.h -o /dev/null 2> /dev/null') {
    #                 DEFINES += SJ_LIBEVENT_MAJOR=2
    #         }
    #         else:system('cc -E $$PWD/conftests/libevent1.h -o /dev/null 2> /dev/null') {
    #                 DEFINES += SJ_LIBEVENT_MAJOR=1
    #         }
    #         else {
    #                 warning("Assuming libevent 1.x")
    #                 DEFINES += SJ_LIBEVENT_MAJOR=1
    #         }

    #         LIBS += -levent_core
    # }

    # target.path  = /usr/lib
    # headers.path = /usr/include

    # QMAKE_PKGCONFIG_NAME        = eventdispatcher_libevent
    # QMAKE_PKGCONFIG_DESCRIPTION = "Libevent-based event dispatcher for Qt"
    # QMAKE_PKGCONFIG_LIBDIR      = $$target.path
    # QMAKE_PKGCONFIG_INCDIR      = $$headers.path
    # QMAKE_PKGCONFIG_DESTDIR     = pkgconfig
}
else {
    # LIBS        += -levent
    # headers.path = $$DESTDIR
    # target.path  = $$DESTDIR
}

win32{
    SOURCES += tco_win32_libevent.cpp
    HEADERS += wsainit.h
    LIBS    += $$QMAKE_LIBS_NETWORK #添加qt网络模块的库文件到链接器，使用QT += network更为推荐
    # CONFIG  -= staticlib
    # CONFIG  += dll

    #用chatGPT认识了该pro配置，该pro未引入libevent库，故手动引入
    #编译为静态库时，不会链接下述这些库。但仍然需要头文件，因为eventdispatcher_libevent使用了头文件定义的一些函数符号
    #相应地，当需要编译为动态库，或者被其他动态库或可执行程序链接时，也同时要链接下述库
    # LIBS += -L$$PWD/libevent/winKitsLib/$$winKitsLib_ver -lws2_32 -liphlpapi -ladvapi32 -lbcrypt -lshell32
    # LIBS += -L$$PWD/libevent/$$libevent_ver/$$_3rdLib_compiler_name/lib/$$buildType -levent -levent_core -levent_extra
}

# INSTALLS += target headers
