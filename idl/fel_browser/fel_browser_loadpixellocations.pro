;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

pro fel_browser_loadpixellocations, pstate

	;; Select the file
	geometry_file = dialog_pickfile(filter='*.h5', path=(*pstate).global.directory)
		
	;; If no file, cleanup		
	if (geometry_file eq '') then begin
		buttonstate = widget_info((*pstate).menu.Correction_locations , /button_set)
		if NOT ptr_valid((*pstate).global.pixelLocationMap) AND buttonstate eq 1 then $
			widget_control, (*pstate).menu.Correction_locations, set_button=0
		return
	endif


	;; Load the geometry file
	x = read_h5(geometry_file, field='x')
	y = read_h5(geometry_file, field='y')
	
	
	;; Pixel size scaling
	desc = [ 	'1, base, , column', $
				'2, float, 1, label_left=Pixel size:, width=10, tag=pixel_size', $
				'1, base,, row', $
				'0, button, OK, Quit, Tag=OK', $
				'2, button, Cancel, Quit' $
	]
	
	a = cw_form(desc, /column, title='Image display')
	
	if a.OK ne 1 then begin		
		return
	endif

	x /= a.pixel_size
	y /= a.pixel_size
	
	
	;; Other needed variables
	panelOrder = [0]
	panelUsage = [0]
	gain = x
	gain[*] = 1

	;;
	;;	Destroy current pixel maps
	;;
	if ptr_valid((*pstate).global.pixelLocationMapX) then $
		ptr_free, (*pstate).global.pixelLocationMapX
	if ptr_valid((*pstate).global.pixelLocationMapY) then $
		ptr_free, (*pstate).global.pixelLocationMapY
	if ptr_valid((*pstate).global.pixelIntensityMap) then $
		ptr_free, (*pstate).global.pixelIntensityMap
	if ptr_valid((*pstate).global.pixelPanelUsage) then $
		ptr_free, (*pstate).global.pixelPanelUsage
	if ptr_valid((*pstate).global.pixelPanelOrder) then $
		ptr_free, (*pstate).global.pixelPanelOrder


	;; Replace with new pixel maps
	(*pstate).global.pixelLocationMapX = ptr_new(x, /no_copy)					
	(*pstate).global.pixelLocationMapY = ptr_new(y, /no_copy)					
	(*pstate).global.pixelPanelOrder = ptr_new(panelOrder, /no_copy)	
	(*pstate).global.pixelPanelUsage = ptr_new(panelUsage, /no_copy)	
	(*pstate).global.pixelIntensityMap = ptr_new(gain, /no_copy)					




end

