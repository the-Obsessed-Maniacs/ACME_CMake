#[[
	This is ACME CMake Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
################################################
	CMake helper functions and macros ...
]]

#[[
	list_filter() - shorthand for "copy to outList, filter outList"
]]
	macro( list_filter includeExclude inList outList regExp )
		set( ${outList} ${${inList}} )
		list( FILTER ${outList} ${includeExclude} REGEX ${regExp} )
	endmacro( list_filter )
#[[
	function to output a list (CMake debugging)
]]
	function( _out_list list text )
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
	endfunction( _out_list )
#[[
	function to grep data
]]
	function( grep_list LIST VAR RE )
		set( x ${${LIST}} )
		list( FILTER x INCLUDE REGEX ${RE} )
		string( REGEX REPLACE ${RE} "\\1" x "${x}" )
		set( ${VAR} ${x} PARENT_SCOPE )
	endfunction( grep_list )
