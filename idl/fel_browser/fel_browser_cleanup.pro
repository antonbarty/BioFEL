;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



;;
;;	Cleanup dirty laundry
;;
pro fel_browser_cleanup, topID

	widget_control, topID, get_uvalue=pstate
	
	ptr_free, (*pstate).global.filenames
	ptr_free, (*pstate).global.image_data
	ptr_free, (*pstate).global.background_data
	ptr_free, (*pstate).global.metadata
	ptr_free, (*pstate).global.pixelIntensityMap

	ptr_free, (*pstate).global.pixelLocationMapX
	ptr_free, (*pstate).global.pixelLocationMapY
	ptr_free, (*pstate).global.pixelIntensityMap
	ptr_free, (*pstate).global.pixelPanelOrder

	
	print,'Saving current state'
	global = (*pstate).global 
	save, global, fi=(*pstate).global.inifile


	print,'Quitting FEL browser'
	ptr_free, pstate

end


