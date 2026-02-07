cmake_minimum_required(VERSION 3.10.2)

project(swisseph)

add_library( # Sets the name of the library.
             swisseph

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             ../../../../../swisseph_src/swedate.c
             ../../../../../swisseph_src/swehouse.c
             ../../../../../swisseph_src/swejpl.c
             ../../../../../swisseph_src/swemmoon.c
             ../../../../../swisseph_src/swemplan.c
             ../../../../../swisseph_src/sweph.c
             ../../../../../swisseph_src/swephlib.c
             ../../../../../swisseph_src/swecl.c
             ../../../../../swisseph_src/swehel.c
)

target_link_libraries( # Specifies the target library.
                       swisseph

                       # Links the target library to the log library
                       # included in the NDK.
                       log )
