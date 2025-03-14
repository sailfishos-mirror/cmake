cmake_minimum_required(VERSION 3.10)

project(Qt4Targets)

find_package(Qt4 REQUIRED)

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

add_executable(Qt4Targets WIN32 main.cpp)
target_link_libraries(Qt4Targets Qt4::QtGui)

if (WIN32)
  if (TARGET Qt4::QAxServer)
    add_executable(activeqtexe WIN32 activeqtexe.cpp)
    set_property(TARGET activeqtexe PROPERTY QT4_NO_LINK_QTMAIN ON)
    target_link_libraries(activeqtexe Qt4::QAxServer Qt4::QtGui)
  endif()
endif()

# Qt4 moc does not support utf8 paths in _parameter files generated by
# qt4_wrap_cpp and qt4_generate_moc
# https://bugreports.qt.io/browse/QTBUG-35480
# Do a simple check if there is are non ASCII character in the build path
string(REGEX MATCH "[^ -~]+" NON_ASCII_BDIR ${CMAKE_CURRENT_BINARY_DIR})
if(NON_ASCII_BDIR)
  message(WARNING "Build path contains non ASCII characters. Skipping Qt4 test.")
  return()
endif()

qt4_generate_moc(main_gen_test.cpp
  "${CMAKE_CURRENT_BINARY_DIR}/main_gen_test.moc"
  TARGET Qt4GenerateMacroTest
)
add_executable(Qt4GenerateMacroTest WIN32 main_gen_test.cpp "${CMAKE_CURRENT_BINARY_DIR}/main_gen_test.moc")
set_property(TARGET Qt4GenerateMacroTest PROPERTY AUTOMOC OFF)
target_include_directories(Qt4GenerateMacroTest PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/interface")
target_link_libraries(Qt4GenerateMacroTest Qt4::QtGui)

qt4_wrap_cpp(moc_file mywrapobject.h
  TARGET Qt4WrapMacroTest
)
add_executable(Qt4WrapMacroTest WIN32 main_wrap_test.cpp ${moc_file})
set_property(TARGET Qt4WrapMacroTest PROPERTY AUTOMOC OFF)
target_include_directories(Qt4WrapMacroTest PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/interface")
target_link_libraries(Qt4WrapMacroTest Qt4::QtGui)

macro(test_incremental def)
  set(timeformat "%Y%j%H%M%S")
  try_compile(RESULT
    "${CMAKE_CURRENT_BINARY_DIR}/IncrementalMocBuild_${def}"
    "${CMAKE_CURRENT_SOURCE_DIR}/IncrementalMoc"
    IncrementalMoc
    CMAKE_FLAGS -D${def}=0 "-DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}"
    OUTPUT_VARIABLE output
    )
  file(TIMESTAMP "${CMAKE_CURRENT_BINARY_DIR}/IncrementalMocBuild_${def}/moc_foo.cpp" tsvar_before "${timeformat}")
  if (NOT tsvar_before)
    message(SEND_ERROR
      "Unable to read timestamp from moc file from first build with -D${def}!\n"
      "try_compile output:\n${output}"
      )
  endif()

  execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 2) # Ensure that the timestamp will change.

  try_compile(RESULT
    "${CMAKE_CURRENT_BINARY_DIR}/IncrementalMocBuild_${def}"
    "${CMAKE_CURRENT_SOURCE_DIR}/IncrementalMoc"
    IncrementalMoc
    CMAKE_FLAGS -D${def}=1 "-DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}"
    OUTPUT_VARIABLE output
    )
  file(TIMESTAMP "${CMAKE_CURRENT_BINARY_DIR}/IncrementalMocBuild_${def}/moc_foo.cpp" tsvar_after "${timeformat}")
  if (NOT tsvar_after)
    message(SEND_ERROR
      "Unable to read timestamp from moc file from second build!\n"
      "try_compile output:\n${output}"
      )
  endif()

  if (NOT tsvar_after GREATER tsvar_before)
    message(SEND_ERROR "Rebuild did not re-create moc file with -D${def}. Before: ${tsvar_before}. After: ${tsvar_after}")
  endif()
endmacro()

test_incremental(ADD_TARGET_DEF)
test_incremental(ADD_DIR_DEF)
