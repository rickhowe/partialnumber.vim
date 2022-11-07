" partialnumber.vim: yet another line number option
"
" Last Change: 2022/11/08
" Version:     2.1
" Author:      Rick Howe (Takumi Ohtani) <rdcxy754@ybb.ne.jp>
" Copyright:   (c) 2015-2022 by Rick Howe

if exists('g:loaded_partialnumber') || !has('signs') || v:version < 800
  finish
endif
let g:loaded_partialnumber = 2.1

let s:save_cpo = &cpo
set cpo&vim

command! -range -nargs=? -bar SetPNU
                    \ call partialnumber#SetPNU(<line1>, <line2>, <f-args>)
command! -range -bar SetNoPNU call partialnumber#SetNoPNU(<line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: ts=2 sw=0 sts=-1 et
