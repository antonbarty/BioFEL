;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Procedure to display file metadata
;;
pro fel_browser_displaycomments, pstate, tabledata

	if ptr_valid((*pstate).global.metadata) eq 0 then $
		return
		
	metadata = (*(*pstate).global.metadata)
	metacolumns = (*pstate).global.metadata_columns		
	s = size(metadata, /dim)
	nfiles = (*pstate).global.nfiles


	selected_field = [metacolumns.filename]
	column_names = ['Filename']
	column_widths = [7*max(strlen(metadata[*,metacolumns.filename]))]
	
	if widget_info((*pstate).menu.Comment_datetime, /button_set)  then begin 
		selected_field = [selected_field, metacolumns.time]
		column_names = [column_names, 'Date/Time']
		column_widths = [column_widths, 150]
	endif
	if widget_info((*pstate).menu.Comment_sample, /button_set) then begin
		selected_field = [selected_field, metacolumns.sample]
		column_names = [column_names, 'Sample']
		column_widths = [column_widths, 100]
	endif
	if widget_info((*pstate).menu.Comment_position, /button_set) then begin
		selected_field = [selected_field, metacolumns.position]
		column_names = [column_names, 'Position']
		column_widths = [column_widths, 150]
	endif
	if widget_info((*pstate).menu.Comment_Comment1, /button_set) then begin
		selected_field = [selected_field, metacolumns.comment1]
		column_names = [column_names, 'Comment 1']
		column_widths = [column_widths, 300]
	endif
	if widget_info((*pstate).menu.Comment_Comment2, /button_set) then begin
		selected_field = [selected_field, metacolumns.comment2]
		column_names = [column_names, 'Comment 2']
		column_widths = [column_widths, 300]
	endif
	if widget_info((*pstate).menu.Comment_timestamps, /button_set) then begin
		selected_field = [selected_field, metacolumns.timestamps]
		column_names = [column_names, 'Timestamps']
		column_widths = [column_widths, 200]
	endif
	if widget_info((*pstate).menu.Comment_Hits, /button_set) then begin
		selected_field = [selected_field, metacolumns.Hits]
		column_names = [column_names, 'Hit info']
		column_widths = [column_widths, 100]
	endif
	if widget_info((*pstate).menu.Comment_HitStrength, /button_set) then begin
		selected_field = [selected_field, metacolumns.HitStrength]
		column_names = [column_names, 'Hit strength']
		column_widths = [column_widths, 100]
	endif
	if widget_info((*pstate).menu.Comment_Tag, /button_set) then begin
		selected_field = [selected_field, metacolumns.tag]
		column_names = [column_names, 'Tag']
		column_widths = [column_widths, 50]
	endif
	if widget_info((*pstate).menu.Comment_ExposureTime, /button_set) then begin
		selected_field = [selected_field, metacolumns.exposuretime]
		column_names = [column_names, 'Exposure (sec)']
		column_widths = [column_widths, 100]
	endif
	if widget_info((*pstate).menu.Comment_CCDbinning, /button_set) then begin
		selected_field = [selected_field, metacolumns.binning]
		column_names = [column_names, 'Binning']
		column_widths = [column_widths, 100]
	endif
	if widget_info((*pstate).menu.Comment_CCDtemp, /button_set) then begin
		selected_field = [selected_field, metacolumns.CCDtemp]
		column_names = [column_names, 'Temperature']
		column_widths = [column_widths, 100]
	endif
	if widget_info((*pstate).menu.Comment_PulsesCounted, /button_set) then begin
		selected_field = [selected_field, metacolumns.PulsesCounted]
		column_names = [column_names, 'N Pulses']
		column_widths = [column_widths, 75]
	endif
	

	tabledata = metadata[*,selected_field]
	ncol = n_elements(selected_field)
	if ncol eq 1 then $
		column_widths = [400-30]
	WIDGET_CONTROL, (*pstate).table.files, table_ysize = nfiles
	WIDGET_CONTROL, (*pstate).table.files, table_xsize = ncol
	WIDGET_CONTROL, (*pstate).table.files, scr_xsize=total(column_widths)+30; 100*ncol+200
	WIDGET_CONTROL, (*pstate).table.files, column_widths = column_widths
	WIDGET_CONTROL, (*pstate).table.files, column_labels = column_names
	WIDGET_CONTROL, (*pstate).table.files, SET_VALUE=transpose(tabledata)
	
end
