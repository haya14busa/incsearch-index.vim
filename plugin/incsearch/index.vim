"=============================================================================
" FILE: plugin/incsearch/index.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_incsearch_index
endif
if exists('g:loaded_incsearch_index')
  finish
endif
let g:loaded_incsearch_index = 1
let s:save_cpo = &cpo
set cpo&vim

function! s:config(...) abort
  return extend(copy({'modules': [incsearch#over#modules#Index#make()]}), get(a:, 1, {}))
endfunction

noremap <silent><expr> <Plug>(incsearch-index-/) incsearch#go(<SID>config())
noremap <silent><expr> <Plug>(incsearch-index-?) incsearch#go(<SID>config({'command': '?'}))
noremap <silent><expr> <Plug>(incsearch-index-stay) incsearch#go(<SID>config({'is_stay': 1}))

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
