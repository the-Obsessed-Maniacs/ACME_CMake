#[[
	This is ACME CMake Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
################################################
	CMake helper functions and macros ...
]]

#[[ list_filter() - shorthand for "copy to outList, filter outList"
	]]
	macro( ACME_filter_list includeExclude inList outList regExp )
		set( ${outList} ${${inList}} )
		list( FILTER ${outList} ${includeExclude} REGEX ${regExp} )
	endmacro( ACME_filter_list )
#[[ function to output a list (CMake debugging)
	]]
	function( ACME_out_list list text )
		set( _i 0 )
		set( _max 100 )
		list( LENGTH ${list} _l )
		if( _l )
			set( _line "${text} " )
			string( LENGTH "${_line}" _ll )
			while( _i LESS _l )
				list( GET ${list} ${_i} _it )
				string( LENGTH ${_it} _itl )
				math( EXPR _il "${_ll}+2+${_itl}" )
				if( _i EQUAL 0 AND _il GREATER_EQUAL _max )	# first item too long?
					message( STATUS ${text} )	# +-> output text first
					set( _line "  " )
					set( _ll 2 )
					math( EXPR _il "2+${_itl}" )
				endif()
				if( _ll EQUAL 2 OR _i EQUAL 0 ) # no empty lines if data is too long
					string( APPEND _line ${_it} )
				elseif( _il LESS _max )
					string( APPEND _line ", ${_it}" )
				else()
					message( STATUS ${_line} )
					set( _line "  ${_it}" )
				endif()
				string( LENGTH "${_line}" _ll )
				math( EXPR _i "${_i}+1" )
			endwhile()
			if ( _ll )
				message( STATUS ${_line} )
			endif()
		else()
			message( STATUS "${text} - List '${list}' is empty." )
		endif()
	endfunction( ACME_out_list )
#[[ function to grep data
	]]
	function( ACME_grep_list LIST VAR RE )
		set( x ${${LIST}} )
		list( FILTER x INCLUDE REGEX ${RE} )
		string( REGEX REPLACE ${RE} "\\1" x "${x}" )
		set( ${VAR} ${x} PARENT_SCOPE )
	endfunction( ACME_grep_list )

#[[ function to find include files from one ACME source file
	]]
	function( ACME_find_inc _f )
		unset( _SRC PARENT_SCOPE )
		unset( _BIN PARENT_SCOPE )
		# read source file
		file( STRINGS ${_f} _c )
		# get abs. dir
		cmake_path( GET _f PARENT_PATH _dir )
		# get acme-includes of file
		# -> get only local include lines (i.e. !src "include.a" )
		ACME_filter_list( INCLUDE _c _SRC "^[ \t]*[!](src)|(source)[ \t]+\".*" )
		list( TRANSFORM _SRC REPLACE ".*\"([^\"]+)\".*" "\\1" )
		list( TRANSFORM _SRC PREPEND "${_dir}/" )
		# get acme-bin-includes of file
		ACME_filter_list( INCLUDE _c _BIN "^[ \t]*[!](bin)|(binary)[ \t]+\".*" )
		list( TRANSFORM _BIN REPLACE ".*\"([^\"]+)\".*" "\\1" )
		list( TRANSFORM _BIN PREPEND "${_dir}/" )
		return( PROPAGATE _SRC _BIN )
	endfunction( ACME_find_inc )

#[[ function to find include files from an ACME source file,
	recursively checking the included files for further
	inclusions
	]]
	function( ACME_get_includes _f )
		list( APPEND _f2c ${_f} )
		while( _f2c )
			list( POP_FRONT _f2c _cf )
			ACME_find_inc( ${_cf} )
			# append found source includes to the check list, but only if they
			# have not yet been checked:
			foreach( _sf IN LISTS _SRC )
				list( FIND SRC_INC ${_sf} _was )
				if ( _was LESS 0 )
					list( APPEND _f2c ${_sf} )
				endif()
			endforeach()
			list( APPEND SRC_inc ${_SRC} )
			list( APPEND BIN_inc ${_BIN} )
		endwhile()
		list( REMOVE_DUPLICATES SRC_inc )
		list( REMOVE_DUPLICATES BIN_inc )
		return( PROPAGATE SRC_inc BIN_inc )
	endfunction( ACME_get_includes )

#[[	Macro to check and set outputs (needed in add_ACME_builders())
	]]
	macro( ACME_ADDSORTOUTPUT ex flag )
		list( PREPEND ACME_FNLIST ${flag} "${_ofsn}${${ex}}" )
		if ( DEFINED ACME_${_fs}${${ex}}_REFS )
			set( _obj ${_ofs}${${ex}} )
		else()
			set( _byp ${_ofs}${${ex}} )
		endif()
	endmacro( ACME_ADDSORTOUTPUT )

#[[	Macro to save typing in add_ACME_builders
	]]
	macro( ACME_PREPARE_BUILD_COMMAND )
		cmake_path( RELATIVE_PATH _afn OUTPUT_VARIABLE _rfn )
		cmake_path( REMOVE_EXTENSION _rfn LAST_ONLY )
		cmake_path( ABSOLUTE_PATH _rfn BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			OUTPUT_VARIABLE _ofs )
		cmake_path( NATIVE_PATH _afn NORMALIZE _sfn )
		cmake_path( NATIVE_PATH _ofs NORMALIZE _ofsn )
		# we need a full ACME command line.  Build it!
		set( ACME_FNLIST ${_sfn} )
		ACME_ADDSORTOUTPUT( OUT_EXT -o )
		if ( DEFINED HEX_EXT )
			ACME_ADDSORTOUTPUT( HEX_EXT --hexlisting )
		endif()
		if ( DEFINED SYM_EXT )
			ACME_ADDSORTOUTPUT( SYM_EXT --symbollist )
		endif()
		if ( DEFINED VICE_EXT )
			ACME_ADDSORTOUTPUT( VICE_EXT --vicelabels )
		endif()
		# now get the includes of this acme source again ...
		unset( SRC_inc )
		unset( BIN_inc )
		ACME_get_includes( ${_afn} )
	endmacro( ACME_PREPARE_BUILD_COMMAND )