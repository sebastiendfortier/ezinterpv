set(FICHIER_F90 
   VerticalGrid_90.F90
   VerticalInterpolation_90.F90
   VertInterpConstants_90.F90)

set(PROJECT_MODULE_FILES 
   ${CMAKE_CURRENT_BINARY_DIR}/verticalgrid_90_class8.mod 
   ${CMAKE_CURRENT_BINARY_DIR}/verticalgrid_90_class.mod 
   ${CMAKE_CURRENT_BINARY_DIR}/verticalinterpolation_90_class8.mod 
   ${CMAKE_CURRENT_BINARY_DIR}/verticalinterpolation_90_class.mod 
   ${CMAKE_CURRENT_BINARY_DIR}/verticalinterpolationconstants_90.mod)

add_library(ezinterpv STATIC ${FICHIER_F90})
add_dependencies(ezinterpv ${PROJECT_NAME}_build_info)
set_target_properties(ezinterpv PROPERTIES
   VERSION ${PROJECT_VERSION}
   PUBLIC_HEADER "${PROJECT_INCLUDE_FILES}"
   INTERFACE_COMPILE_DEFINITIONS HAVE_EZINTERPV=${PROJECT_VERSION}
   POSITION_INDEPENDENT_CODE ON
   OUTPUT_NAME ezinterpv90)

  
   target_link_libraries(ezinterpv rmn::rmn vgrid::vgrid)
add_library(ezinterpv::ezinterpv ALIAS ezinterpv)
     
install(TARGETS ezinterpv
   EXPORT ${PROJECT_NAME}-targets
   LIBRARY DESTINATION lib
   ARCHIVE DESTINATION lib
   PUBLIC_HEADER DESTINATION include
   INCLUDES DESTINATION include)

install(FILES ${PROJECT_MODULE_FILES} DESTINATION include)
      