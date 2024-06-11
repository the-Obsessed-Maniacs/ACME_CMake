#[[
	This is ACME CMake Source Integration.

	Wrapped around ACME by Stefan Kaps 2024.
		St0fF/Neoplasia^theObsessedManiacs
################################################
	CMake helper functions and macros ...
]]
include( "${CMAKE_CURRENT_LIST_DIR}/ACME-Helpers.cmake" )
#[[ 
	macro to gather ACME information from the version.h file
]]
	macro( read_ACME_info _FN )
		file( STRINGS ${_FN} _VI REGEX [[^#[ \t]*define[ \t\r\n]*]] )
		list( JOIN _VI "\n" _dbg )
		grep_list( _VI RELEASE		"^.*RELEASE[ \t]+\"(.*)\".*$" )
		grep_list( _VI CODENAME		"^.*CODENAME[ \t]+\"(.*)\".*$" )
		grep_list( _VI CHANGE_DATE	"^.*CHANGE_DATE[ \t]+\"(.*)\".*$" )
		grep_list( _VI CHANGE_YEAR	"^.*CHANGE_YEAR[ \t]+\"(.*)\".*$" )
		grep_list( _VI HOME_PAGE	"^.*HOME_PAGE[ \t]+\"(.*)\".*$" )
	endmacro( read_ACME_info )

#[[
	function to add an icon to an exe
	-> if somebody knows how, add more platforms...
]]
	function( executable_add_icon Target IconFile )
		cmake_path( GET IconFile FILENAME IconFn )
		cmake_path( ABSOLUTE_PATH IconFn BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			NORMALIZE OUTPUT_VARIABLE IconOut )
		if ( WIN32 )
			configure_file( "${IconFile}" "${IconOut}" COPYONLY )
			string( JOIN "\n" RSC
				"// Iconfile (64/32/16)"
				"ID ICON \"@IconFn@\""
				"// Infos for windows"
				"1 VERSIONINFO"
				"FILEVERSION     @RELEASE@"
				"PRODUCTVERSION  @RELEASE@"
				"FILEFLAGSMASK   0x3fL"
				"FILEFLAGS       0x0L"
				"FILEOS          0x40004L"
				"FILETYPE        0x2L"
				"FILESUBTYPE     0x0L"
				"BEGIN"
				"  BLOCK \"StringFileInfo\""
				"  BEGIN"
				"    BLOCK \"040904E4\""
				"    BEGIN"
				"      VALUE \"CompanyName\", \"Smørbrød Software\""
				"      VALUE \"FileDescription\", \"Acme crossassembler\""
				"      VALUE \"FileVersion\", \"@RELEASE@ @CODENAME@\""
				"      VALUE \"InternalName\", \"ACME crossassembler\""
				"      VALUE \"LegalCopyright\", \"Copyright © @CHANGE_YEAR@ Marco Baye\""
				"      VALUE \"OriginalFilename\", \"acme.exe\""
				"      VALUE \"ProductName\", \"ACME Crossassembler\""
				"      VALUE \"ProductVersion\", \"@RELEASE@ @CODENAME@\""
				"      VALUE \"ProductLicence\",\"GNU General Public License\""
				"      VALUE \"WindowsPort\",\"ACME CMake Integration by St0fF/NPL^tOM\""
				"    END"
				"  END"
				"  BLOCK \"VarFileInfo\""
				"  BEGIN"
				"    VALUE \"Translation\", 0x409, 1252"
				"  END"
				"END"
				)
			file( CONFIGURE OUTPUT "${IconOut}.rc" CONTENT ${RSC} @ONLY )
			target_sources( ${Target} PRIVATE "${IconOut}" "${IconOut}.rc" )
		endif()
	endfunction( executable_add_icon )
