add_executable(Example Example.f90)
target_link_libraries(Example PRIVATE ezinterpv90 vgrid rmn)
target_include_directories(Example PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/../src)

add_dependencies(check Example)
add_test(NAME Example COMMAND Example WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

#add_executable(SpeedConvertP SpeedConvertP.f90)
#target_link_libraries(SpeedConvertP PRIVATE ezinterpv90 vgrid rmn)
#target_include_directories(SpeedConvertP PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/../src)

add_executable(TestVI TestVI.f90)
target_link_libraries(TestVI PRIVATE ezinterpv90 vgrid rmn)
target_include_directories(TestVI PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/../src)

add_dependencies(check TestVI)
add_test(NAME TestVI COMMAND TestVI WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
