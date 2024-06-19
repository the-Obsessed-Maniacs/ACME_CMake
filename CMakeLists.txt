#[[
	This is ACME CMake Source Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
]]
cmake_minimum_required( VERSION 3.20..3.29 )
include( cmake/ACME-Source-Helpers.cmake )
#
# read ACME's current version from "Version.h"
read_ACME_info( "ACME/src/Version.h" )
message( NOTICE "ACME version data: Release=${RELEASE}, Codename=${CODENAME}"
	", changed=${CHANGE_DATE} ${CHANGE_YEAR}, URL=${HOME_PAGE}" )
#
# define Project
project( ACME
		 VERSION "${RELEASE}"
		 DESCRIPTION "ACME 6502++ cross assembler, code name '${CODENAME}', changed ${CHANGE_DATE} ${CHANGE_YEAR}"
		 HOMEPAGE_URL "${HOME_PAGE}"
		 LANGUAGES C CXX )
# ACME CMake options - mostly for CMake integration and packaging purposes
	option( ACME_PACKAGE_CREATOR_MODE "what the variable name sais..." off )
	if( ACME_PACKAGE_CREATOR_MODE AND MSVC AND CMAKE_MAKE_PROGRAM MATCHES "ninja" )
		option( ACME_TEST_SOURCE_PACKAGING "Add custom 'package_source' target for testing purposes..." off )
	endif()
	#if ( ACME_PACKAGE_CREATOR_MODE )
	#	set( CMAKE_BUILD_TYPE Release )
	#endif()

#
# prepare list with ACME's sources
set( acme_srcs
	acme.h		alu.h			config.h	cpu.h
	dynabuf.h	encoding.h		flow.h		global.h
	input.h		macro.h			mnemo.h		output.h
	platform.h	pseudoopcodes.h	section.h	symbol.h
	version.h
	
	acme.c		alu.c			cliargs.c	cpu.c
	dynabuf.c	encoding.c		flow.c		global.c
	input.c		macro.c			mnemo.c		output.c
	platform.c	pseudoopcodes.c	section.c	symbol.c
	tree.c		typesystem.c )
#
#	platform specifics:
#		I don't really know if I handle this right.  But
#		this works for me at least. (Yeah, right, Windows host...)
	if ( CMAKE_SYSTEM_NAME MATCHES ".*DOS.*" ) 
		message( AUTHOR_WARNING "DOS-build - Makefiles did not differ, should work.")
	elseif( MINGW )	
		list( APPEND acme_srcs		_dos.h		 )
	elseif( CMAKE_SYSTEM_NAME MATCHES ".*RISCos.*" )
		message( AUTHOR_WARNING "RISCos-build - Makefiles did not differ, should work.")
	elseif( CMAKE_SYSTEM_NAME MATCHES ".*AMIGA.*" )
		list( APPEND acme_srcs		_amiga.h	_amiga.c )
	elseif( NOT WIN32 AND NOT APPLE AND NOT LINUX AND NOT BSD )
		message( AUTHOR_WARNING "weird-SYSTEM-build - we don't know if this'll work...")
		list( APPEND acme_srcs		_std.h		_std.c )
	endif()
list( TRANSFORM acme_srcs PREPEND "ACME/src/" )
#
# create ACME target
set( ACME_ICON "ACME/src/win/logo.ico" )
add_executable( acme ${acme_srcs} )
executable_add_icon( acme ${ACME_ICON} )
#
# there's also toacme - gather sources:
set( toacme_srcs
	config.h	
	version.h	version.c	main.c
	ab.h		ab.c		ab3.c		f8ab.c
	acme.h		acme.c
	gighyp.h	giga.c		gighyp.c
	io.h		io.c
	mnemo.h		mnemo.c
	pet2iso.h	pet2iso.c
	platform.h	platform.c
	scr2iso.h	scr2iso.c

	vis.c		hypra.c		obj.c		prof.c )
list( TRANSFORM toacme_srcs PREPEND "ACME/contrib/toacme/src/" )
#
# create TOACME target
add_executable( toacme ${toacme_srcs} )
#
# let the source trees look a little more clean in an IDE
source_group( "Sources" REGULAR_EXPRESSION [[.*(c((cc)|(pp))?)$]] )
source_group( "Headers" REGULAR_EXPRESSION [[.*h(pp)?$]] )
#
# It would be nice to have all SVN files to be installed with the Project
# aswell. We'll define another target and sum it all up in there.
set( SVN_file_folders "ACME/ACME_lib" "ACME/docs" "ACME/contrib" "ACME/examples" )
foreach( _d IN LISTS SVN_file_folders )
	file( GLOB_RECURSE _fl RELATIVE_PATH ${CMAKE_CURRENT_SOURCE_DIR} "${_d}/*" )
	list( APPEND SVN_files ${_fl} )
endforeach()
add_custom_target( SVN_files_for_installation
	COMMAND ${CMAKE_COMMAND} -E true	# this target will always succeed.
	COMMENT "ACME companion files from SVN -> placeholder..."
	SOURCES ${SVN_files} )
source_group( TREE "${CMAKE_CURRENT_SOURCE_DIR}/ACME" PREFIX "" FILES ${SVN_files} )

#
# a try to get the CMake folder into the tree
# CMAKE_files: go into the installation
set( CMAKE_files
	cmake/ACME-Helpers.cmake	)
set( CMI cmake/ACME-CMAKE-INTEGRATION.cmake )
list( TRANSFORM CMAKE_files PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/" OUTPUT_VARIABLE _cmf )
# -> generate package Config File from ACME-CMAKE-INTEGRATION.cmake
# as we write on the ACME-CMAKE-INTEGRATION.cmake, this is not a configure, but a
# build step with an output!
string( JOIN "\n" _script 
	"set( ACME_VERSION @ACME_VERSION@ )"
	"file( STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/${CMI}"
	"	ACME_CMAKE_CONFIG NEWLINE_CONSUME )"
	"file( CONFIGURE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfig.cmake"
	"	CONTENT \${ACME_CMAKE_CONFIG} @ONLY )" )
file( CONFIGURE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/makeACMEConfig.cmake
		CONTENT ${_script} @ONLY )
add_custom_command( OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfig.cmake 
	COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/makeACMEConfig.cmake
	MAIN_DEPENDENCY ${CMI}
	USES_TERMINAL
	COMMENT "Build ${CMI}."
)
add_custom_target( CMAKE_Integration ALL
	COMMAND ${CMAKE_COMMAND} -E copy_if_different ${_cmf} "cmake"
	COMMAND_EXPAND_LISTS USES_TERMINAL
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfig.cmake
	BYPRODUCTS ${CMAKE_files}
	SOURCES ${_cmf} ${CMI} cmake/ACME-Source-Helpers.cmake
	COMMENT "Update CMake binary dir..." )
#
# another of those tries: updating docs ...
set( DOC_files
	docs/Source.txt docs/CMake.txt )
list( TRANSFORM DOC_files PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/" OUTPUT_VARIABLE _df )
add_custom_target( Documentation_Updates ALL
	COMMAND ${CMAKE_COMMAND} -E make_directory "docs"
	COMMAND ${CMAKE_COMMAND} -E copy_if_different ${_df} "docs"
	COMMAND_EXPAND_LISTS USES_TERMINAL
	BYPRODUCTS ${DOC_files}
	SOURCES ${_df} Readme.md
	COMMENT "Update Documentation binary dir..." )

#[[
	That was all needed to get ACME to build...
	... now on to testing, installation, and packaging ...

	Tests:	there are many, but I have not yet gained the knowledge about CTest
			needed to get this up and running	=> testing not yet implemented!
		
	Installation and Packaging:
	===========================
]]
# -> use the helper libraries
include( GNUInstallDirs )
if ( WIN32 )
	set( CMAKE_INSTALL_BINDIR . )
endif()
include( CMakePackageConfigHelpers )
# -> prepare cmake scripts install location
set( ConfigPackageLocation cmake )
#-> helps (at least on windows) to quickly find packages
#	from source builds/local installations
set( CMAKE_EXPORT_PACKAGE_REGISTRY True )
set( CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP True )
include( InstallRequiredSystemLibraries )

# install the ACME add toAcme executables and produce the export
install( TARGETS acme toacme DESTINATION ${CMAKE_INSTALL_BINDIR} EXPORT ACME_EXPORT )
# install original library, docs, syntaxes and toacme source contributions
install( DIRECTORY ${SVN_file_folders} DESTINATION . )
# install updated docs
install( DIRECTORY docs DESTINATION . )

# CMake package/module creation:
# -> create target installation file
install( EXPORT ACME_EXPORT NAMESPACE ACME::
	FILE ACME-Targets.cmake
	DESTINATION ${ConfigPackageLocation} )
# -> create basic version file
write_basic_package_version_file(
	${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfigVersion.cmake
	COMPATIBILITY AnyNewerVersion )
# finally install our scripts, functions, and the created files (Config/ConfigVersion)
install( DIRECTORY
	${CMAKE_CURRENT_BINARY_DIR}/cmake
	DESTINATION . )

#
# CPack configuration
if( ACME_PACKAGE_CREATOR_MODE )
	set( CPACK_PACKAGE_VERSION_MAJOR ${ACME_VERSION_MAJOR} )
	set( CPACK_PACKAGE_VERSION_MINOR ${ACME_VERSION_MINOR} )
	set( CPACK_PACKAGE_VENDOR "Sm0rbr0d Software" )
	set( CPACK_PACKAGE_DESCRIPTION ${PROJECT_DESCRIPTION} )
	#set( CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/ReadMe.1st" )
	set( CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/ACME/docs/COPYING" )
	set( CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/ACME/docs/Help.txt" )
	set( CPACK_PACKAGE_INSTALL_DIRECTORY "ACME" )
	set( CPACK_PACKAGE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} )
	if( WIN32 )
		set( CPACK_NSIS_ADD_REMOVE True )	# special NSIS / Windows options
		set( CPACK_NSIS_MODIFY_PATH True )
		set( CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL True )
		set( CPACK_NSIS_WELCOME_TITLE_3LINES True )
		set( CPACK_NSIS_URL_INFO_ABOUT ${HOME_PAGE} )
		set( CPACK_NSIS_BRANDING_TEXT "Packaged by: the Obsessed Maniacs ${CHANGE_YEAR}" )
		# NSIS uses the Icon as Installer-Icon.
		set( CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/${ACME_ICON}" )
		# but this way around it didn't work:
		#set( CPACK_NSIS_INSTALLED_ICON_NAME acme.exe )
		#if ( ACME_PACKAGE_CREATOR_MODE )
		#	set( CPACK_NSIS_IGNORE_LICENSE_PAGE off )
		#else()
			set( CPACK_NSIS_IGNORE_LICENSE_PAGE on )
		#endif()
	endif()
	#
	# Shortcuts are not needed, acme is mostly used within build environments ...
	#
	#set( CPACK_PACKAGE_EXECUTABLES acme ACME toacme toACME )
	#set( CPACK_CREATE_DESKTOP_LINKS "" )
	#set( CPACK_DESKTOP_SHORTCUTS "" )
	#set( CPACK_STARTUP_SHORTCUTS "" )
	#
	#-> the following failed!  Don't enable it...
	#set( CPACK_PACKAGE_ICON "${CMAKE_SOURCE_DIR}/${ACME_ICON}" )
	include( CPack )
	#[[
		Ninja-Builds and CPack in MSVC:
		->	ninja produces the targets "package" and "package_source",
			but obviously MSVC does not show any options to build those.
	]]
	if ( MSVC AND CMAKE_MAKE_PROGRAM MATCHES "ninja" )
		message( NOTICE "Ninjabuild in MSVC! => adding custom packaging targets..." )
		add_custom_target( Ninja_package COMMAND ${CMAKE_MAKE_PROGRAM} "package"
			COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-${CPACK_SYSTEM_NAME}.exe"
			DEPENDS acme toacme USES_TERMINAL
			COMMENT "Create installer package ..."
		)
		if ( ACME_TEST_SOURCE_PACKAGING )
			set_property( TARGET Ninja_package PROPERTY FOLDER "Packaging" )
			add_custom_target( Ninja_package_source COMMAND ${CMAKE_MAKE_PROGRAM} "package_source"
				DEPENDS acme toacme USES_TERMINAL
				COMMENT "Create source installer package ... (never actually worked until now)"
			)
			set_property( TARGET Ninja_package_source PROPERTY FOLDER "Packaging" )
		endif()
	endif()
endif()
