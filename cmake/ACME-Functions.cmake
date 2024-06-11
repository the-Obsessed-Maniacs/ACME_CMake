#[[
	This is ACME CMake Source Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
	========================================
	ACME CMake Functionality - like creating custom targets...

	ACME can use includes just like any C preprocessor.  So the
	target of a compile run can depend on multiple sources.
	
	add_ACME_target( <TargetName> <MainSourceFile> 
		SOURCES <source1> [<source2> ...]
		<ACME_OPTIONS>
	)
	=> see below for details

]]
include( "${CMAKE_CURRENT_LIST_DIR}/ACME-Helpers.cmake" )
#[[
	add_ACME_target( <TargetName> <MainSourceFile>
		USES_FILES <source2> [<sourceN>...]
		<ACME_OPTIONS> )

	This function is to be used to create an ACME-Target in the buildsystem.
	Such targets, in turn, can easily be added to another target as dependency.

	The basic parameters given above are self-explaining - 'TargetName' and 
	'MainSourceFile'.

	'USES_FILES' is to be used, if your 'MainSourceFile' includes other sources
	that don't need a Target for themselves - just like headers in CXX.  So, if
	your 'MainSourceFile' USES_FILES, put them here ...

	'ACME_OPTIONS' are a separate topic:

	Flags:						(MSVC - flag omitted, read from CMake Variable...)
		NO_LABEL_INDENT					- trigger "-Wno-label-indent"
		NO_OLD_FOR						- trigger "-Wno-old-for"
		NO_BIN_LEN						- trigger "-Wno-bin-len"
		TYPE_CHECK						- trigger "-Wtype-mismatch"
		USE_STDOUT						- trigger "--use-stdout"
		COLOR							- trigger "--color"
		FULLSTOP						- trigger "--fullstop"
		TEST							- trigger "--test"

	Single Parameter Options:
		VERBOSE <0..3>					- set ACME verbosity, defaults to "empty"
		SET_PC <address>				- for relocatable sources - set start address
		FORMAT <(plain)|(cbm)|			- set ACME output file format, defaults to "plain"
				(apple)|(hex)>			  -> this preselects the output extension between "prg" and "out"
		OUTPUT_EXTENSION <extension>	- the given extension will be used instead of "out" or "prg"
		SYMBOL_LIST <extension>			- creates a "--symbollist" file with given extension
		VICE_LABELS <extension>			- creates a "--vicelabels" file with given extension
		OUTPUT_DEPS <varName>			- returns the created dependencies in a list

	Multi Parameter Options:
		INCLUDE_PATHS					- add include paths via "-I"
		DEFINE_SYMBOLS					- add definitions via "-D"
		OBJECT_DEPS						- files, that depend on the generated object file
		SYMBOL_DEPS						- files, that depend on the generated symbol list file
]]
function( add_ACME_target TargetName MainSourceFile )
	# parse command line
	block( SCOPE_FOR VARIABLES PROPAGATE 
	# propagate the command line and the extensions
	ACME_FLAGS ACME_EXT_OUT ACME_EXT_SYM ACME_EXT_VICE
	# also propagate, whatever changes variables,
	ACME_OUTPUT_DEPS ACME_SOURCES
	# or cannot be put into a command line right away
	ACME_OBJECT_DEPS ACME_SYMBOL_DEPS )
		# prepare argument parsing
		set( _FORMAT_LIST plain cbm apple hex )
		set( _flg	NO_LABEL_INDENT NO_OLD_FOR NO_BIN_LEN 
					TYPE_CHECK USE_STDOUT COLOR FULLSTOP TEST )
		set( _sgl	VERBOSE FORMAT SET_PC OUTPUT_EXTENSION SYMBOL_LIST
					VICE_LABELS OUTPUT_DEPS )
		set( _mul	INCLUDE_PATHS DEFINE_SYMBOLS OBJECT_DEPS SYMBOL_DEPS SOURCES )
		cmake_parse_arguments( ACME "${_flg}" "${_sgl}" "${_mul}" ${ARGN} )
		#[[
		# check/repair all options - abort if not recoverable
		#	only checking and preparing options, here!
		]]
		# Flags: ... add to constructed flags
			if ( MSVC )
				list( APPEND ACME_FLAGS "--msvc" )
			endif()
			if ( ACME_NO_LABEL_INDENT )
				list( APPEND ACME_FLAGS "-Wno-label-indent" )
			endif()
			if ( ACME_NO_OLD_FOR )
				list( APPEND ACME_FLAGS "-Wno-old-for" )
			endif()
			if ( ACME_NO_BIN_LEN )
				list( APPEND ACME_FLAGS "-Wno-bin-len" )
			endif()
			if ( ACME_TYPE_CHECK )
				list( APPEND ACME_FLAGS "-Wtype-mismatch" )
			endif()
			if ( ACME_USE_STDOUT )
				list( APPEND ACME_FLAGS "--use-stdout" )
			endif()
			if ( ACME_COLOR )
				list( APPEND ACME_FLAGS "--color" )
			endif()
			if ( ACME_FULLSTOP )
				list( APPEND ACME_FLAGS "--fullstop" )
			endif()
			if ( ACME_TEST )
				list( APPEND ACME_FLAGS "--test" )
			endif()
		# SingleValueArgs:
			# ->	VERBOSE ... add to constructed flags
			if ( DEFINED ACME_VERBOSE AND ACME_VERBOSE GREATER 0 AND ACME_VERBOSE LESS 4 )
				list( APPEND ACME_FLAGS "-v${ACME_VERBOSE}" )
			endif()
			# ->	FORMAT ... optional.
			if ( DEFINED ACME_OUTPUT_EXTENSION )
				set( ACME_EXT_OUT ${ACME_OUTPUT_EXTENSION} )
			else()
				set( ACME_EXT_OUT "out" )	# sensitive default?
			endif()
			if ( DEFINED ACME_FORMAT )
				if( NOT ACME_FORMAT IN_LIST _FORMAT_LIST )
					list( GET _FORMAT_LIST 0 ACME_FORMAT )	# recover, don't fail!
					message( AUTHOR_WARNING	"READ_ACME_OPTIONS: 'FORMAT'-Parameter not recognized,"
										" recovered to default value=${ACME_FORMAT}" )
				endif()
				list( APPEND ACME_FLAGS "--format" ${ACME_FORMAT} )
				if ( ACME_FORMAT STREQUAL "cbm" AND NOT DEFINED ACME_OUTPUT_EXTENSION )
					set( ACME_EXT_OUT "prg" )
				endif()
			endif()
			# ->	SET_PC
			if ( DEFINED ACME_SET_PC )
				list( APPEND ACME_FLAGS "--setpc" ${ACME_SET_PC} )
			endif()
			# ->	SYMBOL_LIST <ext> ... make acme spit out a symbol list
			set( ACME_EXT_SYM ${ACME_SYMBOL_LIST} )
			# ->	VICE_LABELS <ext> ... make acme spit out a vice_labels file
			set( ACME_EXT_VICE ${ACME_VICE_LABELS} )
		# MultiValueArgs:
			# ->	INCLUDE_PATHS ... are only for ACME, thus transformation into
			#		ACME_FLAGS neccessary. PATH: also transformation to native!
			foreach( IP IN LISTS ACME_INCLUDE_PATHS )
				file( TO_NATIVE_PATH "${IP}" IP )
				list( APPEND ACME_FLAGS "-I" "'${IP}'" )
			endforeach()
			# ->	DEFINE_SYMBOLS ... are only for ACME, thus transformation into
			#		ACME_FLAGS neccessary.
			foreach ( SYM IN LISTS ACME_DEFINE_SYMBOLS )
				list( APPEND ACME_FLAGS "-D${SYM}" )
			endforeach()
		# add the main source file to the sources list
		list( PREPEND ACME_SOURCES ${MainSourceFile} )
	endblock()
	#
	#	Step #1: produce sensible output file names,
	#				extend ACME_FLAGS accordingly
	#
		set( _inRel ${MainSourceFile} )
		cmake_path( GET _inRel STEM LAST_ONLY _inFn )
		cmake_path( ABSOLUTE_PATH _inRel OUTPUT_VARIABLE _in )
		cmake_path( RELATIVE_PATH _in BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE _inRel )
		cmake_path( ABSOLUTE_PATH _inRel BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} OUTPUT_VARIABLE _out )
		cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_EXT_OUT} )
		if ( NOT EXISTS ${_in} )
			message( ERROR "add_ACME_target( ${TargetName} ${MainSourceFile} ... ) called, but main source is not found!" )
		endif()
		list( APPEND ACME_OUTPUTS "${_out}" )
		# ACME needs all file names as native paths
		cmake_path( NATIVE_PATH _in ACME_in )
		cmake_path( NATIVE_PATH _out ACME_out )
		# the native paths of symbol list files and such need to get integrated
		# into the ACME command line:
		if ( ACME_EXT_SYM )
			cmake_path( REPLACE_EXTENSION ACME_out LAST_ONLY ${ACME_EXT_SYM} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_FLAGS "--symbollist" "'${_symFN}'" )
			# this is a generated output file -> append to the list of outputs!
			cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_EXT_SYM} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_OUTPUTS ${_symFN} )
		endif()
		if ( ACME_EXT_VICE )
			cmake_path( REPLACE_EXTENSION ACME_out LAST_ONLY ${ACME_EXT_VICE} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_FLAGS "--vicelabels" "'${_symFN}'" )
			# this is a generated output file -> append to the list of outputs!
			cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_EXT_VICE} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_OUTPUTS ${_symFN} )
		endif()
	#
	# Status update before doing the real work ...
		message( STATUS "add_ACME_target( '${TargetName}' '${MainSourceFile}' )\n=> FLAGS='${ACME_FLAGS}'" )
		_out_list( ACME_SOURCES "=> given sources:" )
		_out_list( ACME_OUTPUTS "=> outputs:" )
	#
	#	Step #2: create the assembly command
	#		-> produces dependency outputs / generated files
	#
		add_custom_command( OUTPUT ${ACME_OUTPUTS}
			COMMAND ACME::acme ${ACME_FLAGS} -o ${ACME_out} ${ACME_in}
			COMMAND_EXPAND_LISTS USES_TERMINAL
			MAIN_DEPENDENCY ${MainSourceFile}
			DEPENDS ACME::acme ${ACME_SOURCES}
			COMMENT "ACME: assemble ${MainSourceFile}" )
	#
	#	Step #3: create the dependency target, make give files dependent
	#
		add_custom_target( ${TargetName} DEPENDS ${ACME_OUTPUTS} SOURCES ${ACME_SOURCES} 
			COMMENT "ACME_target '${TargetName}': assemble ${MainSourceFile}" )
		# treat given dependencies directly
		if ( DEFINED ACME_OBJECT_DEPS OR DEFINED ACME_SYMBOL_DEPS )
			message( STATUS "=> updating dependencies of dependent files..." )
			# some files depend on the object output
			if ( DEFINED ACME_OBJECT_DEPS )
				foreach( _f IN LISTS ACME_OBJECT_DEPS )
					set_property( SOURCE "${_f}" APPEND PROPERTY OBJECT_DEPENDS ${_out} )
				endforeach()
			endif()
			# some files depend on the label listings
			if ( DEFINED ACME_SYMBOL_DEPS )
				list( SUBLIST ACME_OUTPUTS 1 -1 SYM_OUT )
				foreach( _f IN LISTS ACME_SYMBOL_DEPS )
					foreach( _s IN LISTS SYM_OUT )
						set_property( SOURCE "${_f}" APPEND PROPERTY OBJECT_DEPENDS ${_s} )
					endforeach()
				endforeach()
			endif()
		endif()
	#
	#	Step #4: return requested data
	#
	if ( DEFINED ACME_OUTPUT_DEPS )
		set( ${ACME_OUTPUT_DEPS} ${ACME_OUTPUTS} PARENT_SCOPE )
	endif()
endfunction( add_ACME_target )

#[[
	Macro to get all ACME-Options out of a command line
	-> to be called from inside our functions, simply code-reuse
	-> defines the variables needed to run ACME during build

	A flag "MSVC" to trigger "--msvc" in the command line has been deliberately
	omitted.  A simple "if ( MSVC )" is used for auto-detection.

	Flags recognized:
		NO_LABEL_INDENT					- trigger "-Wno-label-indent"
		NO_OLD_FOR						- trigger "-Wno-old-for"
		NO_BIN_LEN						- trigger "-Wno-bin-len"
		TYPE_CHECK						- trigger "-Wtype-mismatch"
		USE_STDOUT						- trigger "--use-stdout"
		COLOR							- trigger "--color"
		FULLSTOP						- trigger "--fullstop"
		TEST							- trigger "--test"

	Single Parameter Options:
		VERBOSE <0..3>					- set ACME verbosity, defaults to "empty"
		FORMAT <(plain)|(cbm)|(apple)>	- set ACME output file format, defaults to "plain"
										  -> this preselects the output extension between "prg" and "out"
		SET_PC <address>				- for relocatable sources - set start address
		OUTPUT_HEX_LISTING <extension>	- output file will be processed into a hex listing
										  with the given extension
		SYMBOL_LIST <extension>			- creates a "--symbollist" file with given extension
		VICE_LABELS <extension>			- creates a "--vicelabels" file with given extension
		OUTPUT_DEPS <varName>			- returns the created dependencies (i.e. all created files) in a list
		OUTPUT_TARGET <varName>			- returns the created target in ${varName}

	Multi Parameter Options:
		INCLUDE_PATHS					- add include paths via "-I"
		DEFINE_SYMBOLS					- add definitions via "-D"
		OBJECT_DEPS						- files, that depend on the generated object file(s)
		SYMBOL_DEPS						- files, that depend on the generated symbol list file(s)
]]
macro( READ_ACME_OPTIONS )
endmacro( READ_ACME_OPTIONS )