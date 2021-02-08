#
# Copyright (C) 2020 The Falco Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#

set(LIBS_CMAKE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/libs-repo")
set(LIBS_CMAKE_WORKING_DIR "${CMAKE_BINARY_DIR}/libs-repo")

# this needs to be here at the top
if(USE_BUNDLED_DEPS)
  # explicitly force this dependency to use the bundled OpenSSL
  if(NOT MINIMAL_BUILD)
    set(USE_BUNDLED_OPENSSL ON)
  endif()
  set(USE_BUNDLED_JQ ON)
endif()

file(MAKE_DIRECTORY ${LIBS_CMAKE_WORKING_DIR})

# The falcosecurity/libs git reference (branch name, commit hash, or tag) To update falcosecurity/libs version for the next release, change the
# default below In case you want to test against another falcosecurity/libs version just pass the variable - ie., `cmake
# -DLIBS_VERSION=dev ..`
if(NOT LIBS_VERSION)
  set(LIBS_VERSION "81ffd301f28ee57368987b9215fe249a0b71e512")
  set(LIBS_CHECKSUM "SHA256=be7711e1687a466055cdc21a97714ee36b1efee3877836271e737b7d6db72e8b")
endif()
set(PROBE_VERSION "${LIBS_VERSION}")

# cd /path/to/build && cmake /path/to/source
execute_process(COMMAND "${CMAKE_COMMAND}" -DLIBS_VERSION=${LIBS_VERSION} -DLIBS_CHECKSUM=${LIBS_CHECKSUM}
                        ${LIBS_CMAKE_SOURCE_DIR} WORKING_DIRECTORY ${LIBS_CMAKE_WORKING_DIR})

# todo(leodido, fntlnz) > use the following one when CMake version will be >= 3.13

# execute_process(COMMAND "${CMAKE_COMMAND}" -B ${LIBS_CMAKE_WORKING_DIR} WORKING_DIRECTORY
# "${LIBS_CMAKE_SOURCE_DIR}")

execute_process(COMMAND "${CMAKE_COMMAND}" --build . WORKING_DIRECTORY "${LIBS_CMAKE_WORKING_DIR}")
set(LIBS_SOURCE_DIR "${LIBS_CMAKE_WORKING_DIR}/libs-prefix/src/libs")

# jsoncpp
set(JSONCPP_SRC "${LIBS_SOURCE_DIR}/userspace/libsinsp/third-party/jsoncpp")
set(JSONCPP_INCLUDE "${JSONCPP_SRC}")
set(JSONCPP_LIB_SRC "${JSONCPP_SRC}/jsoncpp.cpp")

# Add driver directory
add_subdirectory("${LIBS_SOURCE_DIR}/driver" "${PROJECT_BINARY_DIR}/driver")

# Add libscap directory
add_definitions(-D_GNU_SOURCE)
add_definitions(-DHAS_CAPTURE)
add_definitions(-DNOCURSESUI)
if(MUSL_OPTIMIZED_BUILD)
  add_definitions(-DMUSL_OPTIMIZED)
endif()
add_subdirectory("${LIBS_SOURCE_DIR}/userspace/libscap" "${PROJECT_BINARY_DIR}/userspace/libscap")

# Add libsinsp directory
add_subdirectory("${LIBS_SOURCE_DIR}/userspace/libsinsp" "${PROJECT_BINARY_DIR}/userspace/libsinsp")
add_dependencies(sinsp tbb b64 luajit)

# explicitly disable the tests of this dependency
set(CREATE_TEST_TARGETS OFF)

if(USE_BUNDLED_DEPS)
  add_dependencies(scap jq)
  if(NOT MINIMAL_BUILD)
    add_dependencies(scap curl grpc)
  endif()
endif()
