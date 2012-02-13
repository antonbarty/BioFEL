;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Apply image gamma
;;
function fel_browser_imagegamma, pstate, img

	;; Logarighmic
	if widget_info((*pstate).menu.Viewer_Logarithmic, /button_set) then begin
		img = alog10(img > 1)
	endif $
	
	;; Histogram equalise
	else if widget_info((*pstate).menu.Viewer_HistEqual, /button_set) then begin
		img = hist_equal(img)
	endif $
	
	;; Gamma
	else begin
		widget_control,(*pstate).field.gamma, GET_VALUE=gamma
		gamma = float(gamma)/100
		img = img^gamma
	endelse

	return, img
end
