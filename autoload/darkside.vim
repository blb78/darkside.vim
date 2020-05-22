if exists('g:loaded_darkside')
	finish
endif

let g:loaded_darkside = 1
let s:invalid_coefficient = 'Invalid coefficient. Expected: 0.0 ~ 1.0'
let s:darkside_coeff = get(g:,'darkside_coeff', 0.5)
let s:lightside_start = get(g:,'darkside_lightside_start','^\s*$\n\zs')
let s:lightside_end = get(g:,'darkside_lightside_end','^\s*$')
let s:blacklist = get(g:,'darkside_blacklist',[])
let s:special_cases = get(g:,'darkside_special_cases',{})
let s:options = get(g:,'darkside_options',{'motion':'section'})

let s:cpo_save = &cpo
set cpo&vim


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
	let coeff = a:coeff < 0 ? s:darkside_coeff : a:coeff
	if coeff < 0 || coeff > 1
		throw 'Invalid g:darkside_coefficient. Expected: 0.0 ~ 1.0'
	endif
	return coeff
endfunction

function! s:error(msg)
	echohl ErrorMsg
	echo a:msg
	echohl None
endfunction

function! s:createGroup(coeff)
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

function! s:byMotion()
	return has_key(s:options,'motion')
endfunction

function s:findSection()
	normal! l[[
	let b = exists('*getcurpos')? getcurpos() : getpos('.')
	normal! ]]h
	let e = exists('*getcurpos')? getcurpos() : getpos('.')
	return [b[1],b[2],e[1],e[2]]
endfunction

function s:findParagraph()
	normal! l{
	let b = exists('*getcurpos')? getcurpos() : getpos('.')
	normal! }h
	let e = exists('*getcurpos')? getcurpos() : getpos('.')
	return [b[1],b[2],e[1],e[2]]
endfunction

function s:findSentence()
	normal! l(
	let b = exists('*getcurpos')? getcurpos() : getpos('.')
	normal! )h
	let e = exists('*getcurpos')? getcurpos() : getpos('.')
	return [b[1],b[2],e[1],e[2]]
endfunction

function! s:define()
	let s:pos = exists('*getcurpos')? getcurpos() : getpos('.')
	let s:position =[line('1'),1,line('$'),1]
	"let xy = string(pos[1].' '.pos[2])
	"call s:prompt(xy)
	if s:byMotion()
		if s:options.motion ==# 'sentence'
			let s:position = s:findSentence()
		elseif s:options.motion ==# 'paragraph'
			let s:position = s:findParagraph()
		else
			let s:position = s:findSection()
		endif
	else
		" s:start =  has_key(s:special_cases,&ft) ? searchpos(s:special_cases[&ft]['lightside_start'],'ncpb') : searchpos(s:lightside_start, 'cbW')
		" call setpos('.', pos)
		" s:end = has_key(s:special_cases,&ft) ?  searchpos(s:special_cases[&ft]['lightside_end'],'W') :searchpos(s:lightside_end, 'W')
	endif
	call setpos('.', s:pos)
	return s:position
endfunction

function! s:empty(line)
	return (a:line =~# '^\s*$')
endfunction

function! s:clear_hl()
	while exists('w:darkside_match_ids') && !empty(w:darkside_match_ids)
		silent! call matchdelete(remove(w:darkside_match_ids, -1))
	endwhile
endfunction

function s:skip()
	let pos = exists('*getcurpos')? getcurpos() : getpos('.')
	let cursor = {'lnum':pos[1],'col':pos[2]}
	let l:lightside = {'start':{'lnum':w:selection[0],'col':w:selection[1]},'end':{'lnum':w:selection[2],'col':w:selection[3]}}
	if cursor.lnum >= l:lightside.start.lnum && cursor.lnum <= l:lightside.end.lnum
		if s:options.motion !=# 'sentence' | return 1 | endif
		if cursor.col >= l:lightside.start.col && cursor.col<= l:lightside.end.col
			return 1
		endif
	endif
	return 0
endfunction

function! s:lighten()
	if index(s:blacklist,&ft)>=0
		call s:clear_hl()
		return
	endif

	if !exists('w:selection')
		let w:selection = [0, 0, 0, 0]
	endif

	if exists('s:lightside') && s:skip()
		return
	endif

	" let curr = [line('.'), line('$')]
	" if curr ==# w:selection[0 : 1]
	" 	return
	" endif

	let s:lightside = s:define()
	" if s:lightside ==# w:selection[2 : 3]
	" 	return
	" endif

	call s:clear_hl()
	call call('s:darkenAround', s:lightside)
	let w:selection = s:lightside
endfunction

function! s:darkenAround(startline,startcol,endline,endcol)
	let w:darkside_match_ids = get(w:, 'darkside_match_ids', [])
	let priority = get(g:, 'darkside_priority', 10)
	call add(w:darkside_match_ids, matchadd('DarksideDim', '\%<'.a:startline .'l', priority))
	if a:endline > 0
		call add(w:darkside_match_ids, matchadd('DarksideDim', '\%>'.a:endline .'l', priority))
	endif
	if s:options.motion ==# 'sentence'
		call add(w:darkside_match_ids, matchadd('DarksideDim', '\%'.a:startline .'l\%<'.a:startcol.'c', priority))
		call add(w:darkside_match_ids, matchadd('DarksideDim', '\%'.a:endline .'l\%>'.a:endcol.'c', priority))
	endif
endfunction

function! s:highlightGroup()
	try
		call s:createGroup(s:darkside_coeff)
	catch
		call s:stop()
		return s:error( v:exception)
	endtry
endfunction

function! s:start()
	call s:highlightGroup()
	:augroup darkside
	:	autocmd!
	:	autocmd CursorMoved,CursorMovedI * call s:lighten()
	:	autocmd ColorScheme * call s:highlightGroup()
	:augroup END
	" FIXME: We cannot safely remove this group once Darkside started
	:augroup darkside_win_event
	:	autocmd!
	:	autocmd WinEnter * call s:reset()
	:	autocmd WinLeave * call s:darken(line('$'),0)
	:augroup END
	doautocmd CursorMoved
endfunction

function! s:reset()
	call s:stop()
	call s:start()
endfunction

function! s:stop()
	call s:clear_hl()
	:augroup darkside
	:	autocmd!
	:augroup END
	augroup! darkside
	unlet! w:selection w:darkside_match_ids
endfunction

function! darkside#execute(bang)
	if a:bang
		call s:stop()
	else
		call s:start()
	endif
endfunction

function! s:prompt(string)
	call inputsave()
	let name = input('Enter name: '.a:string)
	call inputrestore()
endfunction
let &cpo = s:cpo_save
unlet s:cpo_save
