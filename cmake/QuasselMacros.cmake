# This file contains various macros useful for building Quassel.
#
# (C) 2014 by the Quassel Project <devel@quassel-irc.org>
#
# The qt4_use_modules function was taken from CMake's Qt4Macros.cmake:
# (C) 2005-2009 Kitware, Inc.
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

############################
# Macros for dealing with Qt
############################

# CMake gained this function in 2.8.10. To be able to use older versions, we've copied
# this here. If present, the function from CMake will take precedence and our copy will be ignored.
function(qt4_use_modules _target _link_type)
    if ("${_link_type}" STREQUAL "LINK_PUBLIC" OR "${_link_type}" STREQUAL "LINK_PRIVATE")
        set(modules ${ARGN})
        set(link_type ${_link_type})
    else()
        set(modules ${_link_type} ${ARGN})
    endif()
    foreach(_module ${modules})
        string(TOUPPER ${_module} _ucmodule)
        set(_targetPrefix QT_QT${_ucmodule})
        if (_ucmodule STREQUAL QAXCONTAINER OR _ucmodule STREQUAL QAXSERVER)
            if (NOT QT_Q${_ucmodule}_FOUND)
                message(FATAL_ERROR "Can not use \"${_module}\" module which has not yet been found.")
            endif()
            set(_targetPrefix QT_Q${_ucmodule})
        else()
            if (NOT QT_QT${_ucmodule}_FOUND)
                message(FATAL_ERROR "Can not use \"${_module}\" module which has not yet been found.")
            endif()
            if ("${_ucmodule}" STREQUAL "MAIN")
                message(FATAL_ERROR "Can not use \"${_module}\" module with qt4_use_modules.")
            endif()
        endif()
        target_link_libraries(${_target} ${link_type} ${${_targetPrefix}_LIBRARIES})
        set_property(TARGET ${_target} APPEND PROPERTY INCLUDE_DIRECTORIES ${${_targetPrefix}_INCLUDE_DIR} ${QT_HEADERS_DIR} ${QT_MKSPECS_DIR}/default)
        set_property(TARGET ${_target} APPEND PROPERTY COMPILE_DEFINITIONS ${${_targetPrefix}_COMPILE_DEFINITIONS})
    endforeach()
endfunction()

# Some wrappers for simplifying dual-Qt support

function(qt_use_modules)
    if (USE_QT5)
        qt5_use_modules(${ARGN})
    else()
        qt4_use_modules(${ARGN})
    endif()
endfunction()

function(qt_wrap_ui _var)
    if (USE_QT5)
        qt5_wrap_ui(var ${ARGN})
    else()
        qt4_wrap_ui(var ${ARGN})
    endif()
    set(${_var} ${${_var}} ${var} PARENT_SCOPE)
endfunction()

function(qt_add_resources _var)
    if (USE_QT5)
        qt5_add_resources(var ${ARGN})
    else()
        qt4_add_resources(var ${ARGN})
    endif()
    set(${_var} ${${_var}} ${var} PARENT_SCOPE)
endfunction()

function(qt_add_dbus_interface _var)
    if (USE_QT5)
        qt5_add_dbus_interface(var ${ARGN})
    else()
        qt4_add_dbus_interface(var ${ARGN})
    endif()
    set(${_var} ${${_var}} ${var} PARENT_SCOPE)
endfunction()

function(qt_add_dbus_adaptor _var)
    if (USE_QT5)
        qt5_add_dbus_adaptor(var ${ARGN})
    else()
        qt4_add_dbus_adaptor(var ${ARGN})
    endif()
    set(${_var} ${${_var}} ${var} PARENT_SCOPE)
endfunction()

######################################
# Macros for dealing with translations
######################################

# This generates a .ts from a .po file
macro(generate_ts outvar basename)
  set(input ${basename}.po)
  set(output ${CMAKE_BINARY_DIR}/po/${basename}.ts)
  add_custom_command(OUTPUT ${output}
          COMMAND ${QT_LCONVERT_EXECUTABLE}
          ARGS -i ${input}
               -of ts
               -o ${output}
          WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/po
# This is a workaround to add (duplicate) strings that lconvert missed to the .ts
          COMMAND ${QT_LUPDATE_EXECUTABLE}
          ARGS -silent
               ${CMAKE_SOURCE_DIR}/src/
               -ts ${output}
          DEPENDS ${basename}.po)
  set(${outvar} ${output})
endmacro(generate_ts outvar basename)

# This generates a .qm from a .ts file
macro(generate_qm outvar basename)
  set(input ${CMAKE_BINARY_DIR}/po/${basename}.ts)
  set(output ${CMAKE_BINARY_DIR}/po/${basename}.qm)
  add_custom_command(OUTPUT ${output}
          COMMAND ${QT_LRELEASE_EXECUTABLE}
          ARGS -silent
               ${input}
          DEPENDS ${basename}.ts)
  set(${outvar} ${output})
endmacro(generate_qm outvar basename)
