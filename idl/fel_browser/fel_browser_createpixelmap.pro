;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



;;
;;	Pixel maps
;;
pro fel_browser_createpixelmap, pstate, dimensions, compute=compute

	if n_elements(dimensions) eq 0 then $
		dimensions = 0

	;;
	;;	Destroy current pixel maps
	;;	- If values change, they are no longer valid
	;;	- new ones will be computed if they don't exist
	;;
		ptr_free, (*pstate).global.pixelLocationMapX
		ptr_free, (*pstate).global.pixelLocationMapY
		ptr_free, (*pstate).global.pixelIntensityMap
		ptr_free, (*pstate).global.pixelOffsetMap
		ptr_free, (*pstate).global.pixelPanelOrder



	;;
	;;	Configuration routine we call depends on the system being used
	;;
		case (*pstate).setup.camera of 
			'XCAM' : begin
				fel_browser_createpixelmap_xcam, pstate, dimensions, compute=compute
			end
	
			'pnCCD' : begin
				fel_browser_createpixelmap_pnCCD, pstate, dimensions, compute=compute
			end
		endcase

end


