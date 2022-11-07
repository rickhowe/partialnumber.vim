" partialnumber.vim: yet another line number option
"
" Last Change: 2022/11/08
" Version:     2.1
" Author:      Rick Howe (Takumi Ohtani) <rdcxy754@ybb.ne.jp>
" Copyright:   (c) 2015-2022 by Rick Howe

let s:save_cpo = &cpo
set cpo&vim

let s:pnu = 'PNU' . string(g:loaded_partialnumber)
let s:idb = 100
let s:idx = 100000

function! partialnumber#SetPNU(sl, el, ...) abort
  let hl = (a:0 == 0) ? 'SignColumn' : a:1
  if hlID(hl) == 0
    call s:EchoErr('No highlight exists: ' . hl)
    return
  endif
  let bn = bufnr('%')
  for ln in map(values(s:CheckPNU(bn)), 'v:val.ln')
    if a:sl <= ln[-1] && ln[0] <= a:el
      call s:EchoErr('Already numbered in these lines')
      return
    endif
  endfor
  call s:ToggleEvent(bn, 1)
  call map(range(a:sl, a:el),
                        \'s:DefinePlaceSign(bn, s:idb, v:val, v:key + 1, hl)')
  let s:idb += 1
endfunction

function! partialnumber#SetNoPNU(sl, el) abort
  let hx = []
  let bn = expand('<abuf>') | let bn = empty(bn) ? bufnr('%') : eval(bn)
  for [id, hn] in items(s:CheckPNU(bn))
    if a:sl <= hn.ln[-1] && hn.ln[0] <= a:el
      call map(range(1, len(hn.ln)), 's:UnplaceSign(bn, id, v:val)')
      if index(hx, hn.hl) == -1 | let hx += [hn.hl] | endif
    endif
  endfor
  if empty(hx)
    call s:EchoErr('Not numbered in these lines')
    return
  endif
  let hls = map(values(s:CheckPNU(0)), 'v:val.hl')
  call map(filter(hx, 'index(hls, v:val) == -1'), 's:UndefineSign(v:val)')
  call s:ToggleEvent(bn, 0)
endfunction

function! s:ToggleEvent(bn, on) abort
  if !empty(s:Sign_getplaced(a:bn)) | return | endif
  let pn = 'partialnumber'
  let ev = {'BufDelete': pn . '#SetNoPNU()'}
  if exists('*listener_add')
    let pl = 'PNU_lid'
    let bv = getbufvar(a:bn, '')
    let bp = has_key(bv, pl)
    if a:on && !bp
      call setbufvar(a:bn, pl, listener_add(function('s:UpdatePNU'), a:bn))
    elseif !a:on && bp
      call listener_remove(bv[pl])
      unlet bv[pl]
    endif
  else
    call extend(ev, {'TextChanged': 's:UpdatePNU()',
                                            \'InsertLeave': 's:UpdatePNU()'})
  endif
  let de = empty(s:Sign_getdefined(''))
  if a:on
    if de
      call execute(['augroup ' . pn, 'autocmd!', 'augroup END'])
    endif
    call execute(values(map(ev, '"autocmd " . pn . " " . v:key .
                                  \" <buffer=" . a:bn . "> call " . v:val')))
  elseif exists('#' . pn)
    call execute(values(map(ev, '"autocmd! " . pn . " " . v:key .
                                                \" <buffer=" . a:bn . ">"')))
    if de | call execute(['augroup! ' . pn]) | endif
  endif
endfunction

function! s:UpdatePNU(...) abort
  if 0 < a:0 && a:4 == 0 | return | endif
  let upd = {}
  let bn = expand('<abuf>') | let bn = empty(bn) ? bufnr('%') : eval(bn)
  let pnu = s:CheckPNU(bn)
  for [id, hn] in items(pnu)
    let [nl, mi, mx] = [len(hn.ln), min(hn.ln), max(hn.ln)]
    if 0 < a:0
      if hn.ln != range(mi, mx) || mi < a:2 && a:2 <= mx
        for ix in range(nl)
          if a:2 <= hn.ln[ix]
            let upd[id] = [ix + 1, a:2, a:2 + (nl - ix) + a:4 - 1]
            break
          endif
        endfor
      endif
    else
      if hn.ln != range(mi, mx)
        for ix in range(1, nl - 1)
          if hn.ln[ix] != hn.ln[0] + ix || hn.ln[ix] > hn.ln[-1]
            let upd[id] = [ix + 1, hn.ln[ix - 1] + 1, hn.ln[-1]]
            break
          endif
        endfor
      endif
    endif
  endfor
  if !empty(upd)
    let hl = []
    for [id, ud] in items(upd)
      call map(range(ud[0], len(pnu[id].ln)), 's:UnplaceSign(bn, id, v:val)')
      if ud[1] <= ud[2]
        call map(range(ud[1], ud[2]),
              \'s:DefinePlaceSign(bn, id, v:val, v:key + ud[0], pnu[id].hl)')
      endif
      let hl += [pnu[id].hl]
    endfor
    let hls = map(values(s:CheckPNU(0)), 'v:val.hl')
    call map(filter(hl, 'index(hls, v:val) == -1'), 's:UndefineSign(v:val)')
  endif
endfunction

function! s:CheckPNU(bn) abort
  let pnu = {}
  for sp in s:Sign_getplaced(a:bn)
    let id = sp.id / s:idx
    if !has_key(pnu, id)
      let pnu[id] = {'ln': [], 'hl': s:Sign_getdefined(sp.name)[0].texthl}
    endif
    let pnu[id].ln += [sp.lnum]
  endfor
  return pnu
endfunction

function! s:EchoErr(msg) abort
  echohl Error | echon a:msg | echohl None
endfunction

function! s:DefinePlaceSign(bn, id, ln, nu, hl) abort
  if 1000 <= a:nu | return | endif
  let nm = s:pnu . '_' . hlID(a:hl) . '_'
  let [na, nb] = [a:nu / 10, a:nu % 10]
  let [tx, nm] = (nb != 0) ? [nr2char(0xA0) . nb, nm . '0' . nb] :
                                  \[(&ambiwidth == 'single' || 50 < na) ? na :
                                    \nr2char((na <= 20) ? 0x2460 + (na - 1) :
        \(na <= 35) ? 0x3251 + (na - 21) : 0x32B1 + (na - 36)), nm . na . '0']
  call s:Sign_define(nm, tx, a:hl)
  call s:Sign_place(a:bn, a:id * s:idx + a:nu, a:ln, nm)
endfunction

function! s:UndefineSign(hl) abort
  for sl in filter(s:Sign_getdefined(''), 'v:val.texthl == a:hl')
    call s:Sign_undefine(sl.name)
  endfor
endfunction

function! s:UnplaceSign(bn, id, nu) abort
  call s:Sign_unplace(a:bn, a:id * s:idx + a:nu)
endfunction

if exists('*sign_define')
  function! s:Sign_define(nm, tx, hl) abort
    call sign_define(a:nm, {'text': a:tx, 'texthl': a:hl})
  endfunction
  function! s:Sign_undefine(nm) abort
    call sign_undefine(a:nm)
  endfunction
  function! s:Sign_getdefined(nm) abort
    return filter(empty(a:nm) ? sign_getdefined() : sign_getdefined(a:nm),
                                                      \'v:val.name =~ s:pnu')
  endfunction
  function! s:Sign_place(bn, id, ln, nm) abort
    call sign_place(a:id, s:pnu, a:nm, a:bn, {'lnum': a:ln})
  endfunction
  function! s:Sign_unplace(bn, id) abort
    call sign_unplace(s:pnu, {'buffer': a:bn, 'id': a:id})
  endfunction
  function! s:Sign_getplaced(bn) abort
    let sp = []
    for bn in a:bn ? [a:bn] : map(getbufinfo(), 'v:val.bufnr')
      let sp += sign_getplaced(bn, {'group': s:pnu})[0].signs
    endfor
    return sp
  endfunction
else
  function! s:Sign_define(nm, tx, hl) abort
    call execute('sign define ' . a:nm . ' text=' . a:tx . ' texthl=' . a:hl)
  endfunction
  function! s:Sign_undefine(nm) abort
    call execute('sign undefine ' . a:nm)
  endfunction
  function! s:Sign_getdefined(nm) abort
    let sd = []
    for xx in filter(split(execute('sign list ' . a:nm), '\n'),
                                                            \'v:val =~ s:pnu')
      let yy = map(split(xx, '\s\+'),
                                    \'substitute(v:val, "^[^=]\\+=", "", "")')
      let sd += [{'name': yy[1], 'text': yy[2], 'texthl': yy[3]}]
    endfor
    return sd
  endfunction
  function! s:Sign_place(bn, id, ln, nm) abort
    call execute('sign place ' . a:id . ' line=' . a:ln . ' name=' . a:nm .
                                                          \' buffer=' . a:bn)
  endfunction
  function! s:Sign_unplace(bn, id) abort
    call execute('sign unplace ' . a:id . ' buffer=' . a:bn)
  endfunction
  function! s:Sign_getplaced(bn) abort
    let sp = []
    for xx in filter(split(execute('sign place' .
                  \(a:bn ? ' buffer=' . a:bn : '')), '\n'), 'v:val =~ s:pnu')
      let yy = map(split(xx, '\s\+'),
                                    \'substitute(v:val, "^[^=]\\+=", "", "")')
      let sp += [{'lnum': eval(yy[0]), 'id': eval(yy[1]), 'name': yy[2]}]
    endfor
    return sp
  endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: ts=2 sw=0 sts=-1 et
