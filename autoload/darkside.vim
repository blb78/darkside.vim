
if exists('g:loaded_darkside')
	finish
endif
let g:loaded_darkside = 1

let s:cpo_save = &cpo
set cpo&vim

let s:invalid_coefficient = 'Invalid coefficient. Expected: 0.0 ~ 1.0'
let g:darkside_default_coeff = get(g:,'darkside_default_coeff',str2float('0.5'))
let g:darkside_delimiters = get(g:, 'darkside_delimiters', ['$',0])


function! s:hex2rgb(str)
	let str = substitute(a:str, '^#', '', '')
	return [eval('0x'.str[0:1]), eval('0x'.str[2:3]), eval('0x'.str[4:5])]
endfunction

let s:gray_converter = {
			\ 0:   231,
			\ 7:   254,
			\ 15:  256,
			\ 16:  231,
			\ 231: 256
			\ }

function! s:gray_contiguous(col)
	let val = get(s:gray_converter, a:col, a:col)
	if val < 231 || val > 256
		throw s:unsupported()
	endif
	return val
endfunction

function! s:gray_ansi(col)
	return a:col == 231 ? 0 : (a:col == 256 ? 231 : a:col)
endfunction

function! s:coeff(coeff)
	let coeff = a:coeff < 0 ?
				\ get(g:, 'darkside_default_coefficient', g:darkside_default_coeff) : a:coeff
	if coeff < 0 || coeff > 1
		throw 'Invalid g:darkside_default_coefficient. Expected: 0.0 ~ 1.0'
	endif
	return coeff
endfunction

function! s:error(msg)
	echohl ErrorMsg
	echo a:msg
	echohl None
endfunction

function! s:dim(coeff)
	let synid = synIDtrans(hlID('Normal'))
	let fg = synIDattr(synid, 'fg#')
	let bg = synIDattr(synid, 'bg#')

	if has('gui_running') || has('termguicolors') && &termguicolors || has('nvim') && $NVIM_TUI_ENABLE_TRUE_COLOR
		if a:coeff < 0 && exists('g:darkside_conceal_guifg')
			let dim = g:darkside_conceal_guifg
		elseif empty(fg) || empty(bg)
			throw s:unsupported()
		else
			let coeff = s:coeff(a:coeff)
			let fg_rgb = s:hex2rgb(fg)
			let bg_rgb = s:hex2rgb(bg)
			let dim_rgb = [
						\ bg_rgb[0] * coeff + fg_rgb[0] * (1 - coeff),
						\ bg_rgb[1] * coeff + fg_rgb[1] * (1 - coeff),
						\ bg_rgb[2] * coeff + fg_rgb[2] * (1 - coeff)]
			let dim = '#'.join(map(dim_rgb, 'printf("%x", float2nr(v:val))'), '')
		endif
		execute printf('hi DarksideDim guifg=%s guisp=bg', dim)
	elseif &t_Co == 256
		if a:coeff < 0 && exists('g:darkside_conceal_ctermfg')
			let dim = g:darkside_conceal_ctermfg
		elseif fg <= -1 || bg <= -1
			throw s:unsupported()
		else
			let coeff = s:coeff(a:coeff)
			let fg = s:gray_contiguous(fg)
			let bg = s:gray_contiguous(bg)
			let dim = s:gray_ansi(float2nr(bg * coeff + fg * (1 - coeff)))
		endif
		if type(dim) == 1
			execute printf('hi DarksideDim ctermfg=%s', dim)
		else
			execute printf('hi DarksideDim ctermfg=%d', dim)
		endif
	else
		throw 'Unsupported terminal. Sorry.'
	endif
endfunction

function! s:parse_coeff(coeff)
	let t = type(a:coeff)
	if t == 1
		if a:coeff =~ '^ *[0-9.]\+ *$'
			let c = str2float(a:coeff)
		else
			throw s:invalid_coefficient
		endif
	elseif index([0, 5], t) >= 0
		let c = t
	else
		throw s:invalid_coefficient
	endif
	return c
endfunction

function! s:clear_hl()
	while exists('w:darkside_match_ids') && !empty(w:darkside_match_ids)
		silent! call matchdelete(remove(w:darkside_match_ids, -1))
	endwhile
endfunction


function! s:lighten()
	if empty('g:darkside_delimiters')
		return
	endif

	return
endfunction

function! s:darken(startline,endline)
	let w:darkside_match_ids = get(w:, 'darkside_match_ids', [])
	let priority = get(g:, 'darkside_priority', 10)
	call add(w:darkside_match_ids, matchadd('DarksideDim', '\%<'.a:startline.'l', priority))
	if a:startline !=# '$' && a:endline > 0
		call add(w:darkside_match_ids, matchadd('DarksideDim', '\%>'.a:endline.'l', priority))
	endif
endfunction

function! s:start()
	try
		let s:lighten_coeff =
					\ g:darkside_default_coeff > 0 ?
					\ s:parse_coeff(g:darkside_default_coeff) : -1
		call s:dim(s:lighten_coeff)
	catch
		return s:error(v:exception)
	endtry

	:augroup darkside
	:	let was_on = exists('#darkside#CursorMoved')
	:	autocmd!
	:	if was_on
	:		autocmd CursorMoved,CursorMovedI * call s:lighten()
	:	endif
	:augroup END
	" FIXME: We cannot safely remove this group once Darkside started
	:augroup darkside_win_event
	:	autocmd!
	:	autocmd WinEnter * call s:reset()
	:	autocmd WinLeave * call s:darken('$',0)
	:augroup END
	doautocmd CursorMoved
endfunction

function! s:reset()
	call s:clear_hl()
	:augroup darkside
	:	autocmd!
	:augroup END
	call s:start()
endfunction

function! darkside#execute(bang)
	if a:bang
		call s:stop()
	else
		call s:start()
	endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
