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
add_executable( acme ${acme_srcs} )
executable_add_icon( acme "ACME/src/win/logo.ico" )
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
source_group( "Source" REGULAR_EXPRESSION [[.*(c((cc)|(pp))?)$]] )
source_group( "Header" REGULAR_EXPRESSION [[.*h(pp)?$]] )
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

# install the ACME add toAcme executables and produce the export
install( TARGETS acme toacme DESTINATION ${CMAKE_INSTALL_BINDIR} EXPORT ACME_EXPORT )
# install library, docs, syntaxes and toacme source contributions
install( DIRECTORY "ACME/ACME_lib" DESTINATION "." )
install( DIRECTORY "ACME/docs" DESTINATION "." )
install( DIRECTORY "ACME/contrib" DESTINATION "." )

# CMake package/module creation:
# -> create target installation file
install( EXPORT ACME_EXPORT NAMESPACE ACME::
	FILE ACME-Targets.cmake
	DESTINATION ${ConfigPackageLocation} )
# -> create basic version file
write_basic_package_version_file(
	${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfigVersion.cmake
	COMPATIBILITY AnyNewerVersion )
# -> generate package Config File
string( JOIN "\n" ACME_CMAKE_CONFIG
"#[[\n\tACME CMake Integration"
"\n\t======================"
"\n\tPackage Version: @ACME_VERSION@\n]]"
"\ninclude( \"\${CMAKE_CURRENT_LIST_DIR}/ACME-Targets.cmake\" )"
"\ninclude( \"\${CMAKE_CURRENT_LIST_DIR}/ACME-Functions.cmake\" )" )
file( CONFIGURE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfig.cmake
	CONTENT ${ACME_CMAKE_CONFIG} @ONLY )

# finally install our scripts, functions, and the created files (Config/ConfigVersion)
install( FILES
	cmake/ACME-Helpers.cmake
	cmake/ACME-Functions.cmake
	${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfig.cmake
	${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfigVersion.cmake
	DESTINATION ${ConfigPackageLocation} )
#[[
	MODERN CMAKE says: DON'T DO THIS!
	=================================
	# -> create a Targets-Export file
	export( EXPORT ACME_EXPORT
		FILE ${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMETargets.cmake
		NAMESPACE ACME::
	)
	# -> create the package configuration file
	configure_package_config_file( cmake/ACMEConfig.in.cmake
		${CMAKE_CURRENT_BINARY_DIR}/cmake/ACMEConfig.cmake
		INSTALL_DESTINATION ${ConfigPackageLocation}
	)
]]
#
# CPack configuration
include( InstallRequiredSystemLibraries )
set( CPACK_PACKAGE_VERSION_MAJOR ${ACME_VERSION_MAJOR} )
set( CPACK_PACKAGE_VERSION_MINOR ${ACME_VERSION_MINOR} )
#set( CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/ReadMe.1st" )
#set( CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/Copying" )
#set( CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/ReadMe.1st" )
set( CPACK_PACKAGE_INSTALL_DIRECTORY "ACME" )
set( CPACK_PACKAGE_EXECUTABLES acme toacme )
#set( CPACK_DESKTOP_SHORTCUTS "" )
#set( CPACK_STARTUP_SHORTCUTS "" )
#if( WIN32 )
#	# special NSIS / Windows options the creator likes
#	set( CPACK_NSIS_MODIFY_PATH off )
#	if ( ACME_PACKAGE_CREATOR_MODE )
#		set( CPACK_NSIS_IGNORE_LICENSE_PAGE off )
#	else()
#		set( CPACK_NSIS_IGNORE_LICENSE_PAGE on )
#	endif()
#endif()
include( CPack )
#[[
	Ninja-Builds and CPack in MSVC:
	->	ninja produces the targets "package" and "package_source",
		but obviously MSVC does not show any options to build those.
]]
if ( MSVC AND CMAKE_MAKE_PROGRAM MATCHES "ninja" )
	message( NOTICE "Ninjabuild in MSVC! => adding custom packaging targets..." )
	add_custom_target( Ninja_package COMMAND ${CMAKE_MAKE_PROGRAM} "package"
		DEPENDS acme toacme USES_TERMINAL
		COMMENT "Create installer package ..."
	)
	set_property( TARGET Ninja_package PROPERTY FOLDER "Packaging" )
	if ( ACME_TEST_SOURCE_PACKAGING )
		add_custom_target( Ninja_package_source COMMAND ${CMAKE_MAKE_PROGRAM} "package_source"
			DEPENDS acme toacme USES_TERMINAL
			COMMENT "Create source installer package ... (never actually worked until now)"
		)
		set_property( TARGET Ninja_package_source PROPERTY FOLDER "Packaging" )
	endif()
endif()
