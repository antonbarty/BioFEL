;; Anton Barty
function remap_pixels, data, x, y, center=center, missing_data=missing_data

	;; Missing data value
	if NOT KEYWORD_SET(missing_data) then $
		missing_data = 0

	;; Check the arrays make sense
	dimd = size(data, /dim)
	dimx = size(x, /dim)
	dimy = size(y, /dim)
	if dimd[0] ne dimx[0] OR dimd[0] ne dimy[0] OR dimd[1] ne dimx[1] OR dimd[1] ne dimy[1]  then begin
		print,'Array size error: array sizes do not match!'
		print, 'dimd=',dimd
		print, 'dimx=',dimx
		print, 'dimy=',dimy
		stop
	endif
	
	;; What size output array?
	;; (This will be different for centered and non-centered images)
	if KEYWORD_SET(center) then begin
		max_x_side = max(abs([max(x),min(x)]))
		max_y_side = max(abs([max(y),min(y)]))
		new_nx = 2*(max_x_side + 1)
		new_ny = 2*(max_y_side + 1)		
		x_offset = -max_x_side
		y_offset = -max_y_side
	endif $

	else begin
		new_nx = max(x)-min(x) + 2
		new_ny = max(y)-min(y) + 2
		x_offset = min(x) 
		y_offset = min(y) 
	endelse
	
	tempx = x - x_offset
	tempy = y - y_offset
	
	
	;; Image remap
	result = fltarr(new_nx, new_ny)
	result[*] = missing_data
	result[tempx, tempy] = data
	
	;; Return result
	return, result
	
end