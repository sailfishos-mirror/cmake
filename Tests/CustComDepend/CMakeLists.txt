cmake_minimum_required(VERSION 3.10)
project(CustComDepend)
include_directories("${CustComDepend_SOURCE_DIR}")
add_definitions(-D_CRT_SECURE_NO_DEPRECATE=1)
set(EXECUTABLE_OUTPUT_PATH ${CustComDepend_BINARY_DIR}/bin)
add_executable(foo foo.cxx)
add_custom_command(
  OUTPUT ${CustComDepend_BINARY_DIR}/bar.c
  COMMAND $<TARGET_FILE:foo>
  ${CustComDepend_BINARY_DIR}/bar.c
  DEPENDS $<TARGET_FILE:foo>
)

add_library(bar SHARED ${CustComDepend_BINARY_DIR}/bar.c)
