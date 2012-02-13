;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Event loop
;;
pro fel_definebeamstop_gui_event, event

  	WIDGET_CONTROL, event.top, GET_UVALUE=pState
  	sState = (*pState)
	s = size(sState.image,/dim)
	
	case event.id of 
		
		sState.drawID : begin

			;; Mouse down
				if event.type eq 0 and event.press eq 1 then begin
					click_r = sqrt((event.x-(*pstate).cx)^2 + (event.y-(*pstate).cy)^2)
					;; Clicking within r/4 of centre moves the centre
					if click_r lt (*pstate).r/4 then begin
						(*pstate).dragging = 1 
						widget_control, (*pstate).drawID, draw_motion_events=1
					endif $
					;; Clicking within r/4 of the radius changes the radius
					else if abs(click_r - (*pstate).r) lt (*pstate).r/4 then begin
						(*pstate).dragging = 2
						widget_control, (*pstate).drawID, draw_motion_events=1
					endif
				endif

			;; Mouse up
				if event.type eq 1 and event.release eq 1 then begin
					(*pstate).dragging = 0
					widget_control, (*pstate).drawID, draw_motion_events=0
				endif
			
			;; Dragging and doing something
				if event.type eq 2 and (*pstate).dragging ne 0 then begin
					;; Moving the centre
					if (*pstate).dragging eq 1 then begin
						(*pstate).cx = event.x
						(*pstate).cy = event.y
					endif $
					;; Changing radius
					else if (*pstate).dragging eq 2 then begin
						(*pstate).r = sqrt((event.x-(*pstate).cx)^2 + (event.y-(*pstate).cy)^2)
						if ((*pstate).star gt 0) then begin
							(*pstate).star = fix((*pstate).r / 10) > 1
						endif
					endif
					
					;; Redraw circle
					oldwin = !d.window
					wset, (*pstate).draw_window
					tv, (*pstate).preview
					xc = (*pstate).cx+(*pstate).r*(*pstate).circ_x
					yc = (*pstate).cy+(*pstate).r*(*pstate).circ_y
					plots, xc, yc, /dev, thick=2
					if ((*pstate).star gt 0) then begin
						for i=0, (*pstate).star-1 do begin
							theta = i*!dtor*(180/(*pstate).star)
							xl = [-1000*cos(theta),1000*cos(theta)]+(*pstate).cx
							yl = [-1000*sin(theta),1000*sin(theta)]+(*pstate).cy
							plots, xl, yl, /dev 
						endfor
					endif
					
					cx_pix = (*pstate).sub_start[0] + (*pstate).cx
					cy_pix = (*pstate).sub_start[1] + (*pstate).cy
					cr_pix = (*pstate).r
					text = strcompress(string('centre = ( ',cx_pix,', ',cy_pix,' ), r=', cr_pix),/remove_all) 
					xyouts, 10,10,text, /dev
					if oldwin ne -1 then $
						wset, oldwin
				endif
				
		end		
		
		sState.doneID : begin
			widget_control, event.top, /destroy
		end


		else: begin
			help, event, /str
		end
		
	endcase  
	
end






;;
;;	FEL define beamstop GUI
;;
function fel_definebeamstop_gui, image, cx=cx, cy=cy, cr=cr, star=star

	oldwin = !d.window

	;;
	;;	Base widget
	;;
		base = WIDGET_BASE(title='Beamstop definition', /column)
		WIDGET_CONTROL, /MANAGED, base

	;;
	;;	Size to make image
	;;
		s = size(image, /dim)
		screensize = get_screen_size()
	
		if NOT KEYWORD_SET(star) then begin
			sub_size_x = min([s[0],512])
			sub_size_y = min([s[0],512])
		endif $
		else begin
			sub_size_x = min([s[0],screensize[0]-100])
			sub_size_y = min([s[1],screensize[1]-100])
			star = 4
		endelse
		
		sub_start_x = (s[0]-sub_size_x)/2
		sub_start_y = (s[1]-sub_size_y)/2
		
	;;
	;;	Previews,etc	
	;;
		preview = image[(s[0]-sub_size_x)/2:(s[0]+sub_size_x)/2-1, (s[1]-sub_size_y)/2:(s[1]+sub_size_y)/2-1]
		preview = bytscl(preview)
		
		theta = 2*!dtor*findgen(181)
		circ_x = cos(theta)
		circ_y = sin(theta)
		

	;;
	;;	Create draw window
	;;
		draw = widget_draw(base, xsize=sub_size_x, ysize=sub_size_y, /button_events)
		WIDGET_CONTROL, base, /REAL
		WIDGET_CONTROL, draw, get_value=draw_window

	;;
	;;	Done button
	;;
	
		done = widget_button(base, value='done')		


	;;
	;;	Default circle
	;;
		if KEYWORD_SET(cx) then cx = cx*s[0] - sub_start_x $
			else cx = sub_size_x/2
		if KEYWORD_SET(cy) then cy = cy*s[1] - sub_start_y $
			else cy = sub_size_y/2
		if KEYWORD_SET(cr) then cr = cr*s[0] $
			else cr = 0.05*s[0]
		if NOT KEYWORD_SET(star) then $
			star=0


	;;
	;;	Info structure
	;;
		sState = {image: image, $
				  preview : preview, $
				  circ_x : circ_x, $
				  circ_y : circ_y, $
				  
				  cx : cx, $
				  cy : cy, $
				  r : cr, $
				  dragging : 0, $
				  star : star, $
				  
				  sub_start : [sub_start_x, sub_start_y], $
				  sub_size : [sub_size_x, sub_size_y], $
				  
				  drawID : draw, $
				  doneID : done, $
				  draw_window: draw_window $
				 }
				 
		pstate = ptr_new(sState)
		WIDGET_CONTROL, base, SET_UVALUE=pstate

 	;;
 	;;	Set up window
 	;;
 		wset, draw_window
	    tv, preview
		plots, sState.cx+sState.r*sState.circ_x, sState.cy+sState.r*sState.circ_y, thick=2, /dev
		if (star gt 0) then begin
			for i=0, star-1 do begin
				theta = i*!dtor*(180/star)
				xl = [-1000*cos(theta),1000*cos(theta)]+cx
				yl = [-1000*sin(theta),1000*sin(theta)]+cy
				plots, xl, yl, /dev 
			endfor
		endif
		
	;;
	;;	Print current centre
	;;
		cx_pix = sub_start_x + (*pstate).cx
		cy_pix = sub_start_y + (*pstate).cy
		cr_pix = (*pstate).r
		text = strcompress(string('centre = ( ',cx_pix,', ',cy_pix,' ), r=', cr_pix),/remove_all) 
		xyouts, 10,10,text, /dev

		if oldwin ne -1 then $
			wset, oldwin
			
	;;
	;;	Run the GUI in blocking mode
	;;
    	XMANAGER, 'fel_definebeamstop_gui', base, event='fel_definebeamstop_gui_event'


	;;
	;;	Return new result
	;;
		cx_pix = sub_start_x + (*pstate).cx
		cy_pix = sub_start_y + (*pstate).cy
		cr_pix = (*pstate).r
		
		;cx_rel = float(cx_pix) / s[0]
		;cy_rel = float(cy_pix) / s[1]
		;cr_rel = float(cr_pix) / s[0]
		
		return, [cx_pix, cy_pix, cr_pix]			
	
end
