#[[
	This is ACME @ACME_VERSION@ CMake Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
	========================================
	ACME CMake Functionality - like creating custom targets...
	----------------------------------------------------------
	But first - import ACME - this is the package config!
]]
include( "${CMAKE_CURRENT_LIST_DIR}/ACME-Targets.cmake" )
include( "${CMAKE_CURRENT_LIST_DIR}/ACME-Helpers.cmake" )
# I do not understand why using the target ACME::acme does not work in ex_proc!
get_target_property( ACME_acme ACME::acme LOCATION )
execute_process( COMMAND ${ACME_acme} "--version" )

#[[
	ACME can use includes just like any C preprocessor.  So the
	target of a compile run can depend on multiple sources.
	
	add_ACME_target( <TargetName> <MainSourceFile>
		USES_FILES <source2> [<sourceN>...]
		OUTPUT_DEPS <varName>	=> returns the created dependencies in a list
		OBJECT_DEPS	<files...>	=> files, that depend on the generated object file
		SYMBOL_DEPS	<files...>	=> files, that depend on the generated symbol list file(s)
		<ACME_OPTIONS> )

	This function is to be used to create an ACME-Target in the buildsystem.
	Such targets, in turn, can easily be added to another target as dependency.

	The basic parameters given above are self-explaining - 'TargetName' and 
	'MainSourceFile'.

	'USES_FILES' is to be used, if your 'MainSourceFile' includes other sources
	that don't need a Target for themselves - just like headers in CXX.  So, if
	your 'MainSourceFile' USES_FILES, put them here to have the dependency
	created.
	'OUTPUT_DEPS' lets you give a variable name, which will receive a list of
	the created outputs of this command.
	'OBJECT_DEPS' - list files here, that will get an object dependency added
	'SYMBOL_DEPS' - list files here, that will get all symbol file dependencies
	added

	'ACME_OPTIONS' are a separate topic.  Every Option ACME accepts should be
	usable, thus there are CMake counterparts.  More on that below.

	A second integration function let's you give all acme source files a custom
	build command, integrated into the Target, which they already belong to.

	add_ACME_builders( Target <ACME_OPTIONS> )

	As simple as that - on to the options:

	get_ACME_cmdLine( MainSourceFile <ACME_OPTIONS> )

	Flags:					(MSVC - flag omitted, read from CMake Variable...)
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
		FORMAT <(plain)|(cbm)|(apple)>	- set ACME output file format, defaults to "plain" -> this preselects the output extension between "prg" and "out"
		OUTPUT_EXTENSION <extension>	- the given extension will be used instead of "out" or "prg"
		SYMBOL_LIST <extension>			- creates a "--symbollist" file with given extension
		VICE_LABELS <extension>			- creates a "--vicelabels" file with given extension
		HEX_LISTING <extension>			- creates a "--hexlisting" file with given extension

	Multi Parameter Options:
		INCLUDE_PATHS					- add include paths via "-I"
		DEFINE_SYMBOLS					- add definitions via "-D"
]]
function( get_ACME_cmdLine MainSourceFile )
	set( _FORMAT_LIST plain cbm apple )
	set( _flg	NO_LABEL_INDENT NO_OLD_FOR NO_BIN_LEN 
				TYPE_CHECK USE_STDOUT COLOR FULLSTOP TEST )
	set( _sgl	VERBOSE FORMAT SET_PC OUTPUT_EXTENSION SYMBOL_LIST
				VICE_LABELS HEX_LISTING ) # OUTPUT_DEPS
	set( _mul	INCLUDE_PATHS DEFINE_SYMBOLS ) # OBJECT_DEPS SYMBOL_DEPS USES_FILES
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
		# ->	SET_PC
		if ( DEFINED ACME_SET_PC )
			list( APPEND ACME_FLAGS "--setpc" ${ACME_SET_PC} )
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
		#
		#	now, after "FORMAT" and "OUTPUT_EXTENSION", the output extension
		#	is set - so we can produce file names:
		#
			set( _inRel ${MainSourceFile} )
			cmake_path( GET _inRel STEM LAST_ONLY _inFn )	# plain filename
			cmake_path( ABSOLUTE_PATH _inRel OUTPUT_VARIABLE _in )
			cmake_path( RELATIVE_PATH _in BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE _inRel )
			cmake_path( ABSOLUTE_PATH _inRel BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} OUTPUT_VARIABLE _out )
			# +-> now, _in, _out, _inRel and _inFn are ready to be used ... last check: file exists?
			if ( NOT EXISTS ${_in} )
				message( ERROR "add_ACME_target: main source '${MainSourceFile}' is not found!" )
			endif()
			# ACME needs all file names as native paths, also the out-filename's extension must be found, first.
			cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_EXT_OUT} )
			cmake_path( NATIVE_PATH _in ACME_in )
			cmake_path( NATIVE_PATH _out ACME_out )
			# ... so, _out is the first output we'll generate ...'
			list( APPEND ACME_OUTPUTS ${_out} )
		#
		# the native paths of symbol list files and such need to get integrated
		# into the ACME command line:
		# ->	SYMBOL_LIST <ext> ... make acme spit out a symbol list
		if ( ACME_SYMBOL_LIST )
			cmake_path( REPLACE_EXTENSION ACME_out LAST_ONLY ${ACME_SYMBOL_LIST} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_FLAGS "--symbollist" "${_symFN}" )
			# this is a generated output file -> append to the list of outputs!
			cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_SYMBOL_LIST} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_OUTPUTS ${_symFN} )
		endif()
		# ->	VICE_LABELS <ext> ... make acme spit out a vice_labels file
		if ( ACME_VICE_LABELS )
			cmake_path( REPLACE_EXTENSION ACME_out LAST_ONLY ${ACME_VICE_LABELS} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_FLAGS "--vicelabels" "${_symFN}" )
			# this is a generated output file -> append to the list of outputs!
			cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_VICE_LABELS} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_OUTPUTS ${_symFN} )
		endif()
		# ->	HEX_LISTING <ext> ... make acme spit out a hex_listing file
		if ( ACME_HEX_LISTING )
			cmake_path( REPLACE_EXTENSION ACME_out LAST_ONLY ${ACME_HEX_LISTING} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_FLAGS "--hexlisting" "${_symFN}" )
			# this is a generated output file -> append to the list of outputs!
			cmake_path( REPLACE_EXTENSION _out LAST_ONLY ${ACME_HEX_LISTING} OUTPUT_VARIABLE _symFN )
			list( APPEND ACME_OUTPUTS ${_symFN} )
		endif()
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
	#
	# finally, add output switch and source file name,
	# so the command line is complete
	#
	list( APPEND ACME_FLAGS "-o" ${ACME_out} ${ACME_in} )
	# reduce parseable Args of parent function (is this necessary?)
	set( ARGN ${ACME_UNPARSED_ARGUMENTS} PARENT_SCOPE )
	return( PROPAGATE ACME_FLAGS ACME_OUTPUTS )
endfunction( get_ACME_cmdLine )

function( add_ACME_target TargetName MainSourceFile )
	# parse command line -> propagates ACME_FLAGS and ACME_OUTPUTS
	get_ACME_cmdLine( ${MainSourceFile} ${ARGN} )
	# add the main source file to the sources list
	list( APPEND ACME_SOURCES ${MainSourceFile} )
	# parse the rest of the command line
	set( _sgl	OUTPUT_DEPS )
	set( _mul	OBJECT_DEPS SYMBOL_DEPS USES_FILES )
	cmake_parse_arguments( ACME "" "${_sgl}" "${_mul}" ${ARGN} )
	# ->	USES_FILES ... those are all sources ...
	foreach( F IN LISTS ACME_USES_FILES )
		list( APPEND ACME_SOURCES ${F} )
	endforeach()
	#
	# Status update before doing the real work ...
		message( STATUS "add_ACME_target( '${TargetName}' '${MainSourceFile}' )\n=> cmdLine='${ACME_FLAGS}'" )
		_out_list( ACME_SOURCES "=> given sources:" )
		_out_list( ACME_OUTPUTS "=> outputs:" )
	#
	#	Step #2: create the assembly command
	#		-> produces dependency outputs / generated files
	#
		add_custom_command( OUTPUT ${ACME_OUTPUTS}
			COMMAND ACME::acme ${ACME_FLAGS}
			COMMAND_EXPAND_LISTS USES_TERMINAL
			MAIN_DEPENDENCY ${MainSourceFile}
			DEPENDS ACME::acme ${ACME_SOURCES}
			COMMENT "ACME: assemble ${MainSourceFile}" )
	#
	#	Step #3: create the dependency target, make give files dependent
	#
		add_custom_target( ${TargetName} DEPENDS ${ACME_OUTPUTS} SOURCES ${ACME_SOURCES} 
			COMMENT "ACME_target '${TargetName}': assembled ${MainSourceFile}" )
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

function( add_ACME_builders Target )
	list( JOIN ARGN "' '" _srcs)
	message( STATUS "add_ACME_builders( ${Target} '${_srcs}' )" )
	# we can continue filtering the Target's SOURCES for ACME files.
	# +-> by convention, or, let's say, it was asked for by the creator of ACME
	#	Marco Baye to name ACME-sources with the extension ".a", we can simply
	#	filter the sources of the target.
	get_target_property( _srcs ${Target} SOURCES )
	ACME_filter_list( INCLUDE _srcs _sl "^.*[.]a$" )
	# now, as "ACME headers or include files" are undefined per se, we should
	# scan all sources for inclusions.  Those, that do not appear in the
	# "included files" list should be made COMMAND_TARGETS.
	if ( _sl )
		# parse command line -> propagates ACME_FLAGS and ACME_OUTPUTS
		get_ACME_cmdLine( ${_sl} ${ARGN} )
		#
		# Repair Command Line, as it's now in a state for the first source file found
			list( POP_BACK ACME_FLAGS ) # input file name is the last option!
			list( POP_BACK ACME_FLAGS OUT_EXT ) # output file name
			cmake_path( GET OUT_EXT EXTENSION LAST_ONLY OUT_EXT ) # strip extension
			list( APPEND _EXTS ${OUT_EXT} )
			list( POP_BACK ACME_FLAGS ) # output file name flag "-o"
			while ( NOT _done )
			list( POP_BACK ACME_FLAGS _li ) # get last item
			file( TO_CMAKE_PATH ${_li} _lic )
			#message( STATUS "check ext: ${_lic}" )
			if ( IS_ABSOLUTE ${_lic} ) # is it an absolute path?
				list( POP_BACK ACME_FLAGS _wf )
				#message( STATUS "absolute file, flag: ${_wf}" )
				if ( _wf MATCHES "--vicelabels" )
					cmake_path( GET _li EXTENSION LAST_ONLY VICE_EXT )
					list( APPEND _EXTS ${VICE_EXT} )
				elseif( _wf MATCHES "--hexlisting" )
					cmake_path( GET _li EXTENSION LAST_ONLY HEX_EXT )
					list( APPEND _EXTS ${HEX_EXT} )
				else()
					cmake_path( GET _li EXTENSION LAST_ONLY SYM_EXT )
					list( APPEND _EXTS ${SYM_EXT} )
				endif()
			else() # not an abs path -> no more listing files
				list( APPEND ACME_FLAGS ${_li} )
				set( _done 1 )
			endif()
			endwhile()
			unset( _done )
		# now the command line is reduced to flags and settings
		# also, the variables OUT_EXT, VICE_EXT, HEX_EXT and SYM_EXT
		# are either set, or unset.
		#
		# check the sources for included files
		foreach( _f IN LISTS _sl )
			ACME_get_includes( ${_f} )
		endforeach()
		# any sources, that are also included, don't need an own build command,
		# so remove them from list
		foreach( _f IN LISTS SRC_INC )
			list( REMOVE_ITEM _sl ${_f} )
		endforeach()
		# build a list of file stems
		foreach( _f IN LISTS _sl )
			cmake_path( GET _f STEM LAST_ONLY _fs )
			list( APPEND _ssl ${_fs} )
		endforeach()
		ACME_out_list( _ssl "  ACME sources considered:" )
		# now the list of sources should resemble the needed ACME commands.
		#	->	we should be able to determine now, which project source files
		#		depend on any of the outputs.  We need to filter all c/pp source
		#		and header files for includes of our output file extensions.
		# -> get sources and headers into one list, check'em all...
		# -> build_list: upon finding included descendants of those acme sources,
		#	create a "build_list" and dependency lists.
		#	- build_list gets those filenames inserted, which are referenced
		#		+->	foreach of those filenames, an ACME_<filename>_REFS variable
		#			is created, the source files referring to the output are added
		#
			ACME_filter_list( INCLUDE _srcs _tsl ".*(h(pp)?)|(c(c|(pp)|(xx))?)$" )
			foreach( _f IN LISTS _tsl )
				# only read include lines
				file( STRINGS ${_f} _s REGEX "^[ \t]*[#][ \t]*include[ \t]*" )
				cmake_path( GET _f FILENAME _fn )
				#ACME_out_list( _s "considered lines of ${_fn}" )
				foreach( _sln IN LISTS _s )
					# check every include line -> grab filename
					string( REGEX REPLACE ".*[\"<]([^\">]+)[\">].*" "\\1" _sln "${_sln}" )
					cmake_path( GET _sln EXTENSION LAST_ONLY _slnx )
					#message( STATUS "check/replacement: ${_sln} -> ${_slnx}" )
					if( _slnx IN_LIST _EXTS )
						# only consider the line on matching extension
						cmake_path( GET _sln STEM LAST_ONLY _slnx )
						if ( _slnx IN_LIST _ssl ) # the stem is inside this project
							# an include was found - yay, the acme code is used somehow.
							# -> so this file needs to get an object_depends added
							set( _v "ACME_${_sln}_REFS" )	# create "ACME_<outfn>_REFS"
							list( APPEND ${_v} ${_f} )		# append source file to those refs
							list( APPEND _rssl ${_slnx} )	# mark STEM as "was included"
							#message( STATUS "include found in ${_fn}: ${_sln} <=> ${_slnx}" )
						endif()
					endif()
				endforeach()
			endforeach()
			list( REMOVE_DUPLICATES _rssl )
			ACME_out_list( _rssl "  ACME sources referenced:" )
		#
		# Now we know which stems are referenced.  These should be the ACME sources, that
		# only need a custom command creating the outputs.  Let's work those off, first...
		foreach( _fs IN LISTS _rssl )
			# find source file name
			foreach( _afnt IN LISTS _sl )
				cmake_path( GET _afnt STEM LAST_ONLY _afns )
				if ( _fs STREQUAL _afns )
					set( _afn ${_afnt} )
					break()
				endif()
			endforeach()

			# no reuse of old objects and byproducts ...
			unset( _obj )
			unset( _byp )
			ACME_PREPARE_BUILD_COMMAND()

			# now we can add the custom command ...
			add_custom_command( OUTPUT ${_obj}
				COMMAND ACME::acme ${ACME_FLAGS} ${ACME_FNLIST}
				MAIN_DEPENDENCY ${_afn}
				BYPRODUCTS "${_byp}"
				SOURCES ${SRC_inc} ${BIN_inc} ${_afn}
				COMMAND_EXPAND_LISTS USES_TERMINAL
				COMMENT "ACME: assemble ${_fs}" )

			# and make the dependent files depend on their objects
			unset( _refs )
			foreach( _ex IN LISTS _EXTS )
				if( DEFINED ACME_${_fs}${_ex}_REFS )
					set_property( SOURCE ${ACME_${_fs}${_ex}_REFS}
						APPEND PROPERTY OBJECT_DEPENDS ${_obj} )
					list( TRANSFORM ACME_${_fs}${_ex}_REFS REPLACE [=[(.*/)]=] "" )
					list( APPEND _refs ${ACME_${_fs}${_ex}_REFS} )
				endif()
			endforeach()
			if ( _refs )
				ACME_out_list( _refs "  '${_fs}' referenced in:" )
			endif()

			# finally add extra include dir
			cmake_path( GET _ofs PARENT_PATH _inc )
			target_include_directories( ${Target} PUBLIC ${_inc} )
			# and remove file from "to build"-list
			list( REMOVE_ITEM _sl ${_afn} )
		endforeach()

		# now if any sources are left over, create their custom command at least
		foreach( _afn IN LISTS _sl )
			# no reuse of old objects and byproducts ...
			unset( _obj )
			unset( _byp )
			# prepare the same variables as used above ...
			cmake_path( GET _afn STEM LAST_ONLY _fs )
			ACME_PREPARE_BUILD_COMMAND()
			# in this case, all objects are byproducts.  Anyhow, the last object
			# created may be a listing or whatever, so we'll make the last byproduct
			# the first object.
			list( POP_BACK _byp _obj )

			# now we can add the custom command ...
			add_custom_command( OUTPUT ${_obj}
				COMMAND ACME::acme ${ACME_FLAGS} ${ACME_FNLIST}
				MAIN_DEPENDENCY ${_afn}
				BYPRODUCTS ${_byp}
				SOURCES ${SRC_inc} ${BIN_inc} ${_afn}
				COMMAND_EXPAND_LISTS USES_TERMINAL
				COMMENT "ACME: assemble ${_fs}" )
			# add extra include dir
			cmake_path( GET _ofs PARENT_PATH _inc )
			target_include_directories( ${Target} PUBLIC ${_inc} )
			# add to list for custom target
			list( APPEND _all_fns ${_afn} )
			list( APPEND _all_objs ${_obj} )
			list( APPEND _all_byps ${_byp} )
			message( STATUS "  '${_fs}' unreferenced -> custom command created.")
		endforeach()

		if ( _all_fns OR _all_objs OR _all_byps )	# if we have a list of 'lone' ACME objects
			add_custom_target( ACME_lone_objects ALL
				DEPENDS ${_all_objs}
				BYPRODUCTS ${_all_byps}
				SOURCES ${_all_fns}
				COMMENT "building lonesome ACME source files ..." )
			add_dependencies( ${Target} ACME_lone_objects )
			message( STATUS "  Created 'ACME_lone_objects' Target for building unreferenced ACME files.")
		endif()
		message( STATUS "add_ACME_builders - all done!" )
	endif()
endfunction( add_ACME_builders )