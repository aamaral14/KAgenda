cmake_minimum_required(VERSION 3.16)

project(gmailcalendarplugin)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Network NetworkAuth)

qt6_standard_project_setup()

qt6_add_qml_module(gmailcalendarplugin
    URI com.github.kagenda
    VERSION 1.0
    SOURCES
        src/GmailBackend.cpp
        src/GmailBackend.h
    PLUGIN_TARGET gmailcalendarplugin
)

target_link_libraries(gmailcalendarplugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Network
    Qt6::NetworkAuth
)

install(TARGETS gmailcalendarplugin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)