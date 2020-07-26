" partialnumber.vim: yet another line number option
"
" Last Change:	2020/07/26
" Version:		2.0
" Author:		Rick Howe <rdcxy754@ybb.ne.jp>
" Copyright:	(c) 2014-2020 by Rick Howe

if exists('g:loaded_partialnumber') || !has('signs') || v:version < 800
	finish
endif
let g:loaded_partialnumber = 2.0

let s:save_cpo = &cpo
set cpo&vim

command! -range -nargs=? -bar SetPNU
					\ call partialnumber#SetPNU(<line1>, <line2>, <f-args>)
command! -range -bar SetNoPNU call partialnumber#SetNoPNU(<line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: ts=4 sw=4
