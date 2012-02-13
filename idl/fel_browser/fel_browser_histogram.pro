;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Produce histogram plot
;;
pro fel_browser_histogram, pstate, xmin=xmin, xmax=xmax

	if NOT keyword_set(xmin) then $
		xmin = 0
	if NOT keyword_set(xmax) then $
		xmax = (*pstate).global.ccd_max

	;;
	;;	Histogram of image
	;;
		img = (*(*pstate).global.image_data) > 0
		h = histogram(img, min=0, max=(*pstate).global.ccd_max)
		h = float(h)/max(h)
		h[0:10] = 0
	
	;;
	;;	Plot it
	;;
		oldwin = !d.window
		wset, (*pstate).window.histogram
		loadct, 0, /silent
		
		xs = !d.x_size
		ys = !d.y_size
		box = bytarr(3,xs,ys)
		box_wx = ((xs*(xmax-xmin)/(*pstate).global.ccd_max) > 1) < xs-1
		box_xs = xs*xmin/(*pstate).global.ccd_max
		box[0,box_xs:box_xs+box_wx, *] = 15
		box[1,box_xs:box_xs+box_wx, *] = 40
		box[2,box_xs:box_xs+box_wx, *] = 15
		tv, box, true=1
		
		
		plot, h+1, xstyle=5, ystyle=5, xmargin=[0,0], ymargin=[0,0],/noerase,/yl
		if oldwin ne -1 then $
			wset, oldwin

end

