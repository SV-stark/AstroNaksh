cmake_minimum_required(VERSION 3.10.2)
 
 project(swisseph)
 
 add_library( # Sets the name of the library.
              swisseph
 
              # Sets the library as a shared library.
              SHARED
 
              # C files are now local to the Android project
              swisseph/swedate.c
              swisseph/swehouse.c
              swisseph/swejpl.c
              swisseph/swemmoon.c
              swisseph/swemplan.c
              swisseph/sweph.c
              swisseph/swephlib.c
              swisseph/swecl.c
              swisseph/swehel.c
 )
 
 target_link_libraries( # Specifies the target library.
                        swisseph
 
                        # Links the target library to the log library
                        # included in the NDK.
                        log )
