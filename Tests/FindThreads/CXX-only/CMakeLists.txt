cmake_minimum_required(VERSION 3.10)
project(FindThreads_CXX-only CXX)

find_package(Threads REQUIRED)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../../../Modules/CheckForPthreads.c
               ${CMAKE_CURRENT_BINARY_DIR}/CheckForPthreads.cxx)

if (NOT WIN32)
  add_executable(thr ${CMAKE_CURRENT_BINARY_DIR}/CheckForPthreads.cxx)
  target_link_libraries(thr Threads::Threads)
endif ()
