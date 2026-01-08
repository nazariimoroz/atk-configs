cmake_minimum_required(VERSION 3.21)

project(some-new-and-fancy-name
  VERSION 0.1.0
  LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

file(GLOB_RECURSE HDR RELATIVE "${PROJECT_SOURCE_DIR}" src/*.h)
file(GLOB_RECURSE SRC RELATIVE "${PROJECT_SOURCE_DIR}" src/*.cpp)
file(GLOB_RECURSE SLT RELATIVE "${PROJECT_SOURCE_DIR}" ui/*.slint)

add_executable(${PROJECT_NAME} ${SRC})

function(collect_all_targets root_dir out_var)
  get_property(_tgts DIRECTORY "${root_dir}" PROPERTY BUILDSYSTEM_TARGETS)

  get_property(_subdirs DIRECTORY "${root_dir}" PROPERTY SUBDIRECTORIES)
  foreach(_sd IN LISTS _subdirs)
    collect_all_targets("${_sd}" _child_tgts)
    list(APPEND _tgts ${_child_tgts})
  endforeach()

  list(REMOVE_DUPLICATES _tgts)
  set(${out_var} "${_tgts}" PARENT_SCOPE)
endfunction()

collect_all_targets("${CMAKE_CURRENT_SOURCE_DIR}" ALL_TARGETS)
# message(STATUS "All build targets: ${ALL_TARGETS}")
