function radial_average, data, r, x=x, y=y, loc=loc


	;;
	;;	Create radiual distance array
	;;
		if keyword_set(x) AND keyword_set(y) then begin
			d = sqrt(x*x+y*y)
		endif $
		else if n_elements(r) ne 0 then begin
			d = r
		endif $
		else begin
			s = size(data,/dim)
			d = dist(s[0],s[1])
			d = shift(d,s[0]/2,s[1]/2)
		endelse
		


	;;
	;;	Sort distances
	;;
		dmin = 0
		dmax = max(d)
		
		hd = histogram(d, min=0, max=dmax, reverse_indices=ii, _extra=extra, locations=loc)

	;;
	;;	Output array
	;;
		avg = hd*0.


	;;
	;;	Compute radial average
	;;
		
		for i = 1, n_elements(hd)-1 do begin
		  	if ii[i] NE ii[i+1] then $
				avg[i] = total(data[ii[ii[i]:ii[i+1]-1]])/hd[i]
		endfor


	;;
	;;	Return average
	;;
		return, avg
	
end
	