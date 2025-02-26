cmake_minimum_required(VERSION 3.16)

include(RunCMake)

set(RunCMake_GENERATOR "Ninja Multi-Config")
set(RunCMake_GENERATOR_IS_MULTI_CONFIG 1)

# Sanitize NINJA_STATUS since we expect default behavior.
unset(ENV{NINJA_STATUS})

function(check_files dir)
  cmake_parse_arguments(_check_files "" "" "INCLUDE;EXCLUDE" ${ARGN})

  set(expected ${_check_files_INCLUDE})
  list(FILTER expected EXCLUDE REGEX "^$")
  list(REMOVE_DUPLICATES expected)
  list(SORT expected)

  file(GLOB_RECURSE actual "${dir}/*")
  list(FILTER actual EXCLUDE REGEX "/CMakeFiles/|\\.ninja$|/CMakeCache\\.txt$|/target_files[^/]*\\.cmake$|/\\.ninja_[^/]*$|/cmake_install\\.cmake$|\\.ilk$|\\.manifest$|\\.odx$|\\.pdb$|\\.exp$|/install_manifest\\.txt$|/\\.qt/(QtDeploySupport|QtDeployTargets)[^/]*\\.cmake$")
  foreach(f IN LISTS _check_files_INCLUDE _check_files_EXCLUDE)
    if(EXISTS ${f})
      list(APPEND actual ${f})
    endif()
  endforeach()
  list(REMOVE_DUPLICATES actual)
  list(SORT actual)

  if(NOT "${expected}" STREQUAL "${actual}")
    string(REPLACE ";" "\n  " expected_formatted "${expected}")
    string(REPLACE ";" "\n  " actual_formatted "${actual}")
    string(APPEND RunCMake_TEST_FAILED "Actual files did not match expected\nExpected:\n  ${expected_formatted}\nActual:\n  ${actual_formatted}\n")
  endif()

  set(RunCMake_TEST_FAILED "${RunCMake_TEST_FAILED}" PARENT_SCOPE)
endfunction()

function(check_file_contents filename expected)
  if(NOT EXISTS "${filename}")
    string(APPEND RunCMake_TEST_FAILED "File ${filename} does not exist\n")
  else()
    file(READ "${filename}" actual)
    if(NOT actual MATCHES "${expected}")
      string(REPLACE "\n" "\n  " expected_formatted "${expected}")
      string(REPLACE "\n" "\n  " actual_formatted "${actual}")
      string(APPEND RunCMake_TEST_FAILED "Contents of ${filename} do not match expected\nExpected:\n  ${expected_formatted}\nActual:\n  ${actual_formatted}\n")
    endif()
  endif()

  set(RunCMake_TEST_FAILED "${RunCMake_TEST_FAILED}" PARENT_SCOPE)
endfunction()

function(run_cmake_configure case)
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/${case}-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")
  run_cmake(${case})
endfunction()

function(run_cmake_build case suffix config)
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/${case}-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  set(tgts)
  foreach(tgt IN LISTS ARGN)
    list(APPEND tgts --target ${tgt})
  endforeach()
  if(config)
    set(config_arg --config ${config})
  else()
    set(config_arg)
  endif()
  run_cmake_command(${case}-${suffix}-build "${CMAKE_COMMAND}" --build . ${config_arg} ${tgts})
endfunction()

function(run_ninja case suffix file)
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/${case}-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  run_cmake_command(${case}-${suffix}-ninja "${RunCMake_MAKE_PROGRAM}" -f "${file}" ${ARGN})
endfunction()

###############################################################################

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/Simple-build)
# IMPORTANT: Setting RelWithDebInfo as the first item in CMAKE_CONFIGURATION_TYPES
# generates a build.ninja file with that configuration
set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=RelWithDebInfo\\;Debug\\;Release\\;MinSizeRel;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(Simple)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_ninja(Simple targets-default build.ninja -t targets)
run_ninja(Simple targets-debug build-Debug.ninja -t targets)
run_ninja(Simple targets-release build-Debug.ninja -t targets)
run_cmake_build(Simple debug-target Debug simpleexe)
run_ninja(Simple debug-target build-Debug.ninja simplestatic)
get_filename_component(simpleshared_Release "${TARGET_FILE_simpleshared_Release}" NAME)
run_cmake_build(Simple release-filename Release ${simpleshared_Release})
file(RELATIVE_PATH simpleexe_Release "${RunCMake_TEST_BINARY_DIR}" "${TARGET_FILE_simpleexe_Release}")
run_ninja(Simple release-file build-Release.ninja ${simpleexe_Release})
run_cmake_build(Simple all-configs Release simplestatic:all)
run_ninja(Simple default-build-file build.ninja simpleexe)
run_cmake_build(Simple all-clean Release clean:all)
run_cmake_build(Simple debug-subdir Debug SimpleSubdir/all)
run_ninja(Simple debug-in-release-graph-target build-Release.ninja simpleexe2:Debug)
run_ninja(Simple release-in-minsizerel-graph-subdir build-MinSizeRel.ninja SimpleSubdir/all:Release)
run_cmake_build(Simple all-subdir Release SimpleSubdir/all:all)
run_ninja(Simple minsizerel-top build-MinSizeRel.ninja all)
run_cmake_build(Simple debug-in-release-graph-top Release all:Debug)
run_ninja(Simple all-clean-again build-Debug.ninja clean:all)
run_ninja(Simple all-top build-RelWithDebInfo.ninja all:all)
# Leave enough time for the timestamp to change on second-resolution systems
execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 1)
file(TOUCH "${RunCMake_TEST_BINARY_DIR}/empty.cmake")
run_ninja(Simple reconfigure-config build-Release.ninja simpleexe)
execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 1)
file(TOUCH "${RunCMake_TEST_BINARY_DIR}/empty.cmake")
run_ninja(Simple reconfigure-noconfig build.ninja simpleexe)
run_ninja(Simple default-build-file-clean build.ninja clean)
run_ninja(Simple default-build-file-clean-minsizerel build.ninja clean:MinSizeRel)
run_ninja(Simple default-build-file-all build.ninja all)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SimpleDefaultBuildAlias-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release\\;MinSizeRel\\;RelWithDebInfo;-DCMAKE_DEFAULT_BUILD_TYPE=Release;-DCMAKE_DEFAULT_CONFIGS=all;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(SimpleDefaultBuildAlias)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_ninja(SimpleDefaultBuildAlias target build.ninja simpleexe)
run_ninja(SimpleDefaultBuildAlias all build.ninja all)
run_ninja(SimpleDefaultBuildAlias clean build.ninja clean)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SimpleDefaultBuildAliasList-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_DEFAULT_BUILD_TYPE=Release;-DCMAKE_DEFAULT_CONFIGS=Debug\\;Release;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(SimpleDefaultBuildAliasList)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_ninja(SimpleDefaultBuildAliasList target-configs build.ninja simpleexe)
# IMPORTANT: This tests cmake --build . with no config using build.ninja
run_cmake_build(SimpleDefaultBuildAliasList all-configs "" all)
run_ninja(SimpleDefaultBuildAliasList all-relwithdebinfo build.ninja all:RelWithDebInfo)
run_ninja(SimpleDefaultBuildAliasList clean-configs build.ninja clean)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SimpleDefaultBuildAliasListCross-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_DEFAULT_BUILD_TYPE=RelWithDebInfo;-DCMAKE_DEFAULT_CONFIGS=all;-DCMAKE_CROSS_CONFIGS=Debug\\;Release")
run_cmake_configure(SimpleDefaultBuildAliasListCross)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_ninja(SimpleDefaultBuildAliasListCross target-configs build.ninja simpleexe)

unset(RunCMake_TEST_BINARY_DIR)

set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release;-DCMAKE_CROSS_CONFIGS=Debug\\;Release\\;RelWithDebInfo")
run_cmake(InvalidCrossConfigs)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release;-DCMAKE_DEFAULT_BUILD_TYPE=RelWithDebInfo")
run_cmake(InvalidDefaultBuildFileConfig)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=Debug\\;Release;-DCMAKE_DEFAULT_BUILD_TYPE=Release;-DCMAKE_DEFAULT_CONFIGS=Debug\\;Release\\;RelWithDebInfo")
run_cmake(InvalidDefaultConfigsCross)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS "-DCMAKE_DEFAULT_BUILD_TYPE=Release;-DCMAKE_DEFAULT_CONFIGS=all")
run_cmake(InvalidDefaultConfigsNoCross)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_OPTIONS "-DCMAKE_DEFAULT_BUILD_TYPE=Release")
run_cmake(DefaultBuildFileConfig)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SimpleNoCross-build)
run_cmake_configure(SimpleNoCross)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(SimpleNoCross debug-target Debug simpleexe)
run_ninja(SimpleNoCross debug-target build-Debug.ninja simplestatic:Debug)
run_ninja(SimpleNoCross relwithdebinfo-in-release-graph-target build-Release.ninja simplestatic:RelWithDebInfo)
run_cmake_build(SimpleNoCross relwithdebinfo-in-release-graph-all Release all:RelWithDebInfo)
run_cmake_build(SimpleNoCross relwithdebinfo-in-release-graph-clean Release clean:RelWithDebInfo)
run_ninja(SimpleNoCross all-target build-Debug.ninja simplestatic:all)
run_ninja(SimpleNoCross all-all build-Debug.ninja all:all)
run_cmake_build(SimpleNoCross all-clean Debug clean:all)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/SimpleCrossConfigs-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=Debug\\;Release")
run_cmake_configure(SimpleCrossConfigs)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_ninja(SimpleCrossConfigs release-in-release-graph build-Release.ninja simpleexe)
run_cmake_build(SimpleCrossConfigs debug-in-release-graph Release simpleexe:Debug)
run_cmake_build(SimpleCrossConfigs relwithdebinfo-in-release-graph Release simpleexe:RelWithDebInfo)
run_ninja(SimpleCrossConfigs relwithdebinfo-in-relwithdebinfo-graph build-RelWithDebInfo.ninja simpleexe:RelWithDebInfo)
run_ninja(SimpleCrossConfigs release-in-relwithdebinfo-graph build-RelWithDebInfo.ninja simplestatic:Release)
run_cmake_build(SimpleCrossConfigs all-in-relwithdebinfo-graph RelWithDebInfo simplestatic:all)
run_ninja(SimpleCrossConfigs clean-all-in-release-graph build-Release.ninja clean:all)
run_cmake_build(SimpleCrossConfigs all-all-in-release-graph Release all:all)
run_cmake_build(SimpleCrossConfigs all-relwithdebinfo-in-release-graph Release all:RelWithDebInfo)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/PostBuild-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(PostBuild)
unset(RunCMake_TEST_OPTIONS)
run_cmake_build(PostBuild release Release Exe)
run_cmake_build(PostBuild debug-in-release-graph Release Exe:Debug)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/LongCommandLine-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(LongCommandLine)
unset(RunCMake_TEST_OPTIONS)
run_cmake_build(LongCommandLine release Release custom)
run_cmake_build(LongCommandLine release-config Release exe:Debug)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/Framework-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(Framework)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(Framework framework Debug all)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/FrameworkDependencyAutogen-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(FrameworkDependencyAutogen)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(FrameworkDependencyAutogen framework Release test2:Debug)

set(RunCMake_TEST_NO_CLEAN 1)
set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/CustomCommandGenerator-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release\\;MinSizeRel\\;RelWithDebInfo;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(CustomCommandGenerator)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(CustomCommandGenerator debug Debug generated)
run_cmake_command(CustomCommandGenerator-debug-generated "${TARGET_FILE_generated_Debug}")
run_ninja(CustomCommandGenerator release build-Release.ninja generated)
run_cmake_command(CustomCommandGenerator-release-generated "${TARGET_FILE_generated_Release}")
run_ninja(CustomCommandGenerator debug-clean build-Debug.ninja clean)
run_cmake_build(CustomCommandGenerator release-clean Release clean)
run_cmake_build(CustomCommandGenerator debug-in-release-graph Release generated:Debug)
run_cmake_command(CustomCommandGenerator-debug-in-release-graph-generated "${TARGET_FILE_generated_Debug}")
run_ninja(CustomCommandGenerator debug-clean-again build-Debug.ninja clean:Debug)
run_ninja(CustomCommandGenerator release-in-debug-graph build-Debug.ninja generated:Release)
run_cmake_command(CustomCommandGenerator-release-in-debug-graph-generated "${TARGET_FILE_generated_Release}")
unset(RunCMake_TEST_NO_CLEAN)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/CustomCommandsAndTargets-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(CustomCommandsAndTargets)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(CustomCommandsAndTargets release-command Release SubdirCommand)
#FIXME Get this working
#run_ninja(CustomCommandsAndTargets minsizerel-command build-MinSizeRel.ninja CustomCommandsAndTargetsSubdir/SubdirCommand)
run_ninja(CustomCommandsAndTargets debug-command build-Debug.ninja TopCommand)
run_ninja(CustomCommandsAndTargets release-target build-Release.ninja SubdirTarget)
run_cmake_build(CustomCommandsAndTargets debug-target Debug TopTarget)
run_cmake_build(CustomCommandsAndTargets debug-in-release-graph-postbuild Release SubdirPostBuild:Debug)
run_ninja(CustomCommandsAndTargets release-postbuild build-Release.ninja SubdirPostBuild)
run_cmake_build(CustomCommandsAndTargets debug-targetpostbuild Debug TopTargetPostBuild)
run_ninja(CustomCommandsAndTargets release-targetpostbuild build-Release.ninja SubdirTargetPostBuild)
run_cmake_build(CustomCommandsAndTargets release-clean Release clean:all)
run_ninja(CustomCommandsAndTargets release-leaf-custom build-Release.ninja LeafCustom.txt)
run_cmake_build(CustomCommandsAndTargets release-clean Release clean:all)
run_ninja(CustomCommandsAndTargets release-leaf-exe build-Release.ninja LeafExe)
run_cmake_build(CustomCommandsAndTargets release-clean Release clean:all)
run_ninja(CustomCommandsAndTargets release-leaf-byproduct build-Release.ninja main.c)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/CustomCommandOutputGenex-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release\\;MinSizeRel\\;RelWithDebInfo;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(CustomCommandOutputGenex)
set(RunCMake_TEST_NO_CLEAN 1)
unset(RunCMake_TEST_OPTIONS)
# echo_raw
run_ninja(CustomCommandOutputGenex echo_raw-debug build-Debug.ninja echo_raw:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_raw-debug-in-release-graph build-Release.ninja echo_raw:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_genex
run_ninja(CustomCommandOutputGenex echo_genex-debug build-Debug.ninja echo_genex:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_genex-debug-in-release-graph build-Release.ninja echo_genex:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_genex_out
run_ninja(CustomCommandOutputGenex echo_genex_out-debug build-Debug.ninja echo_genex_out:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_genex_out-debug-in-release-graph build-Release.ninja echo_genex_out:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_depend*
run_ninja(CustomCommandOutputGenex echo_depend-debug build-Debug.ninja echo_depend:Debug)
run_ninja(CustomCommandOutputGenex echo_depend_out-debug build-Debug.ninja echo_depend_out_Debug.txt)
run_ninja(CustomCommandOutputGenex echo_depend_cmd-debug build-Debug.ninja echo_depend_cmd_Debug.txt)
run_ninja(CustomCommandOutputGenex echo_depend-debug-in-release-graph build-Release.ninja echo_depend:Debug)
run_ninja(CustomCommandOutputGenex echo_depend_out-debug-in-release-graph build-Release.ninja echo_depend_out_Debug.txt)
run_ninja(CustomCommandOutputGenex echo_depend_cmd-debug-in-release-graph build-Release.ninja echo_depend_cmd_Debug.txt)
# depend_echo_raw
run_ninja(CustomCommandOutputGenex depend_echo_raw-debug build-Debug.ninja depend_echo_raw:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex depend_echo_raw-debug-in-release-graph build-Release.ninja depend_echo_raw:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# depend_echo_genex
run_ninja(CustomCommandOutputGenex depend_echo_genex-debug build-Debug.ninja depend_echo_genex:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex depend_echo_genex-debug-in-release-graph build-Release.ninja depend_echo_genex:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# depend_echo_genex_out
run_ninja(CustomCommandOutputGenex depend_echo_genex_out-debug build-Debug.ninja depend_echo_genex_out:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex depend_echo_genex_out-debug-in-release-graph build-Release.ninja depend_echo_genex_out:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# depend_echo_genex_cmd
run_ninja(CustomCommandOutputGenex depend_echo_genex_cmd-debug build-Debug.ninja depend_echo_genex_cmd:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex depend_echo_genex_cmd-debug-in-release-graph build-Release.ninja depend_echo_genex_cmd:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# no_cross_output
run_ninja(CustomCommandOutputGenex echo_no_cross_output-debug build-Debug.ninja echo_no_cross_output:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_no_cross_output-debug-in-release-graph build-Release.ninja echo_no_cross_output:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# no_cross_output_if
run_ninja(CustomCommandOutputGenex echo_no_cross_output_if-debug build-Debug.ninja echo_no_cross_output_if:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_no_cross_output_if-debug-in-release-graph build-Release.ninja echo_no_cross_output_if:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# no_cross_byproduct
run_ninja(CustomCommandOutputGenex echo_no_cross_byproduct-debug build-Debug.ninja echo_no_cross_byproduct:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_no_cross_byproduct-debug-in-release-graph build-Release.ninja echo_no_cross_byproduct:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# no_cross_byproduct_if
run_ninja(CustomCommandOutputGenex echo_no_cross_byproduct_if-debug build-Debug.ninja echo_no_cross_byproduct_if:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_no_cross_byproduct_if-debug-in-release-graph build-Release.ninja echo_no_cross_byproduct_if:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_dbg
run_ninja(CustomCommandOutputGenex echo_dbg-debug build-Debug.ninja echo_dbg)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_dbg-release build-Release.ninja echo_dbg)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_dbg-debug-in-release-graph build-Release.ninja echo_dbg:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_dbgx
run_ninja(CustomCommandOutputGenex echo_dbgx-debug build-Debug.ninja echo_dbgx)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_dbgx-release build-Release.ninja echo_dbgx)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_dbgx-debug-in-release-graph build-Release.ninja echo_dbgx:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_depend_target
run_ninja(CustomCommandOutputGenex echo_depend_target-debug-prep build-Debug.ninja echo:Debug)
run_ninja(CustomCommandOutputGenex echo_depend_target-debug build-Debug.ninja echo_depend_target)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_depend_target-release-prep build-Release.ninja echo:Release)
run_ninja(CustomCommandOutputGenex echo_depend_target-release build-Release.ninja echo_depend_target)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_depend_target-debug-in-release-graph-prep build-Release.ninja echo:Release)
run_ninja(CustomCommandOutputGenex echo_depend_target-debug-in-release-graph build-Release.ninja echo_depend_target:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_target_raw
run_ninja(CustomCommandOutputGenex echo_target_raw-debug build-Debug.ninja echo_target_raw:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_target_raw-debug-in-release-graph build-Release.ninja echo_target_raw:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_target_genex
run_ninja(CustomCommandOutputGenex echo_target_genex-debug build-Debug.ninja echo_target_genex:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_target_genex-debug-in-release-graph build-Release.ninja echo_target_genex:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_target_genex_out
run_ninja(CustomCommandOutputGenex echo_target_genex_out-debug build-Debug.ninja echo_target_genex_out:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex echo_target_genex_out-debug-in-release-graph build-Release.ninja echo_target_genex_out:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# echo_target_depend*
run_ninja(CustomCommandOutputGenex echo_target_depend-debug build-Debug.ninja echo_target_depend:Debug)
run_ninja(CustomCommandOutputGenex echo_target_depend_out-debug build-Debug.ninja echo_target_depend_out:Debug)
run_ninja(CustomCommandOutputGenex echo_target_depend_cmd-debug build-Debug.ninja CMakeFiles/echo_target_depend_cmd-Debug) # undocumented
run_ninja(CustomCommandOutputGenex echo_target_depend-debug-in-release-graph build-Release.ninja echo_target_depend:Debug)
run_ninja(CustomCommandOutputGenex echo_target_depend_out-debug-in-release-graph build-Release.ninja echo_target_depend_out:Debug)
run_ninja(CustomCommandOutputGenex echo_target_depend_cmd-debug-in-release-graph build-Release.ninja CMakeFiles/echo_target_depend_cmd-Debug) # undocumented
# target_no_cross_*
run_ninja(CustomCommandOutputGenex target_no_cross_byproduct-debug build-Debug.ninja target_no_cross_byproduct:Debug)
run_ninja(CustomCommandOutputGenex clean-debug-graph build-Debug.ninja -t clean)
run_ninja(CustomCommandOutputGenex target_no_cross_byproduct-debug-in-release-graph build-Release.ninja target_no_cross_byproduct:Debug)
run_ninja(CustomCommandOutputGenex clean-release-graph build-Release.ninja -t clean)
# target_post_build
run_ninja(CustomCommandOutputGenex target_post_build-debug build-Debug.ninja target_post_build)
unset(RunCMake_TEST_NO_CLEAN)

unset(RunCMake_TEST_BINARY_DIR)

run_cmake(CustomCommandDepfile)
run_cmake(CustomCommandDepfileAsOutput)
run_cmake(CustomCommandDepfileAsByproduct)

set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all")
run_cmake(PerConfigSources)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/PostfixAndLocation-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(PostfixAndLocation)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(PostfixAndLocation release-in-release-graph Release mylib:Release)
run_cmake_build(PostfixAndLocation debug-in-release-graph Release mylib:Debug)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/Clean-build)
run_cmake_configure(Clean)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(Clean release Release)
run_ninja(Clean release-notall build-Release.ninja exenotall)
run_cmake_build(Clean release-clean Release clean)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/AdditionalCleanFiles-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release\\;MinSizeRel\\;RelWithDebInfo;-DCMAKE_CROSS_CONFIGS=all")
run_cmake_configure(AdditionalCleanFiles)
unset(RunCMake_TEST_OPTIONS)
run_cmake_build(AdditionalCleanFiles release-clean Release clean)
run_ninja(AdditionalCleanFiles all-clean build-Debug.ninja clean:all)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/Install-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_INSTALL_PREFIX=${RunCMake_TEST_BINARY_DIR}/install;-DCMAKE_CROSS_CONFIGS=all;-DCMAKE_DEFAULT_CONFIGS=Debug\\;Release")
run_cmake_configure(Install)
unset(RunCMake_TEST_OPTIONS)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(Install release-install Release install)
run_ninja(Install debug-in-release-graph-install build-Release.ninja install:Debug)
file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}/install")
run_ninja(Install default-install build.ninja install)
file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}/install")
run_ninja(Install all-install build.ninja install:all)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/ExcludeFromAll-build)
run_cmake_configure(ExcludeFromAll)
include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
run_cmake_build(ExcludeFromAll all "" all:all)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/ExternalProject-build)
set(RunCMake_TEST_OPTIONS "-DCMAKE_CROSS_CONFIGS=all;-DCMAKE_DEFAULT_CONFIGS=Debug\\;Release")
run_cmake_configure(ExternalProject)
unset(RunCMake_TEST_OPTIONS)
run_cmake_build(ExternalProject release-in-debug-graph "Debug" all:Release)
run_cmake_build(ExternalProject debug-in-release-graph "Release" all:Debug)

# FIXME Get this working
#set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/AutoMocExecutable-build)
#run_cmake_configure(AutoMocExecutable)
#run_cmake_build(AutoMocExecutable debug-in-release-graph Release exe)

# Need to test this manually because run_cmake() adds --no-warn-unused-cli
set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/NoUnusedVariables-build)
run_cmake_command(NoUnusedVariables ${CMAKE_COMMAND} ${CMAKE_CURRENT_LIST_DIR}
  -G "Ninja Multi-Config"
  "-DRunCMake_TEST=NoUnusedVariables"
  "-DCMAKE_CROSS_CONFIGS=all"
  "-DCMAKE_DEFAULT_BUILD_TYPE=Debug"
  "-DCMAKE_DEFAULT_CONFIGS=all"
  )
unset(RunCMake_TEST_BINARY_DIR)

set(RunCMake_TEST_OPTIONS "-DCMAKE_CONFIGURATION_TYPES=Debug\\;Release;-DCMAKE_CROSS_CONFIGS=all;-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
run_cmake(CompileCommands)
unset(RunCMake_TEST_OPTIONS)

set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/OutputPathPrefix-build)
run_cmake_with_options(OutputPathPrefix "-DCMAKE_NINJA_OUTPUT_PATH_PREFIX=OutputPathPrefix-build")
set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR})
set(RunCMake_TEST_NO_CLEAN 1)
run_cmake_command(OutputPathPrefix-all-ninja "${RunCMake_MAKE_PROGRAM}" -f OutputPathPrefix-build/build.ninja OutputPathPrefix-build/all)
run_cmake_command(OutputPathPrefix-clean-ninja "${RunCMake_MAKE_PROGRAM}" -f OutputPathPrefix-build/build.ninja OutputPathPrefix-build/clean)
unset(RunCMake_TEST_NO_CLEAN)
unset(RunCMake_TEST_BINARY_DIR)

# cmake --install test
block()
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/cmake--install-build)
  run_cmake_with_options(cmake--install
    -DCMAKE_INSTALL_PREFIX=${RunCMake_TEST_BINARY_DIR}/install
    -DCMAKE_CROSS_CONFIGS=all
    -DCMAKE_DEFAULT_CONFIGS=Debug\\\\;Release
    )
  set(RunCMake_TEST_NO_CLEAN 1)
  run_cmake_command(cmake--install-build ${CMAKE_COMMAND} --build .)
  run_cmake_command(cmake--install-install ${CMAKE_COMMAND} --install .)
endblock()

# CudaSimple uses separable compilation, which is currently only supported on NVCC.
if(CMake_TEST_CUDA)
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/CudaSimple-build)
  run_cmake_configure(CudaSimple)
  include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
  run_cmake_build(CudaSimple debug-target Debug simplecudaexe)
  run_ninja(CudaSimple all-clean build-Debug.ninja clean:Debug)
endif()

if(CMake_TEST_Qt_version)
  set(QtX Qt${CMake_TEST_Qt_version})
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/QtX-build)
  set(RunCMake_TEST_OPTIONS
    "-DCMAKE_CROSS_CONFIGS=all"
    "-Dwith_qt_version:STRING=${CMake_TEST_Qt_version}"
    "-D${QtX}Core_DIR=${${QtX}Core_DIR}"
    "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
  )

  foreach(use_better_graph IN ITEMS ON OFF)
    foreach(target_config IN ITEMS Debug Release RelWithDebInfo)
      foreach(ninja_config IN ITEMS Debug Release RelWithDebInfo)
        block()
          set(target_config_suffix "_${target_config}")
          if (use_better_graph)
            set(autogen_files_config_suffix "${target_config_suffix}")
          else()
            set(autogen_files_config_suffix "")
          endif()
          set(prefix "QtX")
          set(case "${target_config}-in-${ninja_config}-better-graph-${use_better_graph}")
          set(test_path "${prefix}-${case}")
          set(RunCMake_TEST_VARIANT_DESCRIPTION "-${case}-configure")
          set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/${test_path}-build)
          run_cmake_with_options(QtX ${RunCMake_TEST_OPTIONS}
            "-DCMAKE_AUTOGEN_BETTER_GRAPH_MULTI_CONFIG=${use_better_graph}")
          unset(RunCMake_TEST_VARIANT_DESCRIPTION)
          include(${RunCMake_TEST_BINARY_DIR}/target_files.cmake)
          run_cmake_build(${test_path} "" ${ninja_config} exe:${target_config})
          check_files("${RunCMake_TEST_BINARY_DIR}"
          INCLUDE
            "${AUTOGEN_FILES${target_config_suffix}}"
            "${TARGET_FILE_exe${target_config_suffix}}"
            "${TARGET_OBJECT_FILES_exe${target_config_suffix}}"
          )
          if (DEFINED RunCMake_TEST_FAILED AND NOT RunCMake_TEST_FAILED STREQUAL "")
            message(FATAL_ERROR "RunCMake_TEST_FAILED:${RunCMake_TEST_FAILED}")
          else()
            message(STATUS "${test_path}-check-files - PASSED")
          endif()

          check_file_contents("${RunCMake_TEST_BINARY_DIR}/exe_autogen/deps${autogen_files_config_suffix}"
                              "exe_autogen/timestamp${autogen_files_config_suffix}")
          if (DEFINED RunCMake_TEST_FAILED AND NOT RunCMake_TEST_FAILED STREQUAL "")
            message(FATAL_ERROR "RunCMake_TEST_FAILED:${RunCMake_TEST_FAILED}")
          endif()
        endblock()
      endforeach()
    endforeach()
  endforeach()

  if(CMake_TEST_${QtX}Core_Version VERSION_GREATER_EQUAL 5.15.0)
    foreach(use_better_graph IN ITEMS ON OFF)
      foreach(target_config IN ITEMS Debug Release RelWithDebInfo)
        foreach(ninja_config IN ITEMS Debug Release RelWithDebInfo)
          set(prefix "QtX")
          set(case "${target_config}-in-${ninja_config}-better-graph-${use_better_graph}")
          set(test_path "${prefix}-${case}")
          if (use_better_graph)
            set(autogen_files_config_suffix "_${target_config}")
          else()
            set(autogen_files_config_suffix "")
          endif()
          set(RunCMake_TEST_VARIANT_DESCRIPTION "-automoc-check")
          run_ninja(${test_path} "" build-${ninja_config}.ninja -t query exe_autogen/timestamp${autogen_files_config_suffix})
        endforeach()
      endforeach()
    endforeach()
  endif()
endif()
