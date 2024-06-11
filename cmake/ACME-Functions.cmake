#[[
	This is ACME CMake Source Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
	========================================
	ACME CMake Functionality - like creating custom targets...

	ACME can use includes just like any C preprocessor.  So the
	target of a compile run can depend on multiple sources.
	
	add_ACME_target( <TargetName> <MainSourceFile> 
		ADD_SOURCES <source1> [<source2> ...]
		<ACME_OPTIONS>
	)

]]
include( "${CMAKE_CURRENT_LIST_DIR}/ACME-Helpers.cmake" )
#[[

]]
function( add_ACME_target TargetName MainSourceFile )
	# parse command line
	block( SCOPE_FOR VARIABLES PROPAGATE 
	# propagate the command line and the extensions
	ACME_FLAGS ACME_EXT_OUT ACME_EXT_HEX ACME_EXT_SYM ACME_EXT_VICE
	# also propagate, whatever changes variables,
	ACME_OUTPUT_DEPS ACME_OUTPUT_TARGET ACME_SOURCES
	# or cannot be put into a command line right away
	ACME_OBJECT_DEPS ACME_SYMBOL_DEPS )
		# prepare argument parsing
		set( _FORMAT_LIST plain cbm apple )
		set( _flg	NO_LABEL_INDENT NO_OLD_FOR NO_BIN_LEN 
					TYPE_CHECK USE_STDOUT COLOR FULLSTOP TEST )
		set( _sgl	VERBOSE FORMAT SET_PC OUTPUT_HEX_LISTING SYMBOL_LIST
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
			set( ACME_EXT_OUT "out" )	# sensitive default?
			if ( DEFINED ACME_FORMAT )
				if( NOT ACME_FORMAT IN_LIST _FORMAT_LIST )
					list( GET _FORMAT_LIST 0 ACME_FORMAT )	# recover, don't fail!
					message( WARNING	"READ_ACME_OPTIONS: 'FORMAT'-Parameter not recognized,"
										" recovered to default value=${ACME_FORMAT}" )
				endif()
				list( APPEND ACME_FLAGS "--format" ${ACME_FORMAT} )
				if ( ACME_FORMAT STREQUAL "cbm" )
					set( ACME_EXT_OUT "prg" )
				endif()
			endif()
			# ->	SET_PC
			if ( DEFINED ACME_SET_PC )
				list( APPEND ACME_FLAGS "--setpc" ${ACME_SET_PC} )
			endif()
			# ->	OUTPUT_HEX_LISTING ...
			set( ACME_EXT_HEX ${ACME_OUTPUT_HEX_LISTING} )
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
		# ACME needs all file names as native paths
		cmake_path( NATIVE_PATH _in ACME_in )
		cmake_path( NATIVE_PATH _out ACME_out )
	#
	# Status update after interpreting arguments
	message( STATUS "add_ACME_target( ${TargetName} )\n=> FLAGS='${ACME_FLAGS}'" )
	_out_list( ACME_SOURCES "=> given sources: " )
	#
	#	Step #2: create the assembly command
	#		-> produces dependency outputs / generated files
	#
		add_custom_command( OUTPUT ${ACME_OUTPUTS}
			COMMAND ACME::acme ${ACME_FLAGS} -o ${ACME_out} ${ACME_in}
			COMMAND_EXPAND_LISTS USES_TERMINAL
			MAIN_DEPENDENCY ${MainSourceFile}
			DEPENDS ACME::acme ${ACME_SOURCES}
			COMMENT "ACME: assemble ${srcIn}" )

	#
	#	Step #2: 
	#		-> 
	#

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