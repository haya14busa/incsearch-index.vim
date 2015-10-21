"=============================================================================
" FILE: autoload/incsearch/over/modules/Index.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let g:incsearch_searchindex_onchar = get(g:, 'incsearch_searchindex_onchar', 1)
let g:incsearch_searchindex_pos = get(g:, 'incsearch_searchindex_pos', 'right')
let g:incsearch_searchindex_minimum_length = get(g:, 'incsearch_searchindex_minimum_length', 0)
let g:incsearch_searchindex_line_limit = get(g:, 'incsearch_searchindex_line_limit', 1000000)
let g:incsearch_searchindex_count_limit = get(g:, 'incsearch_searchindex_count_limit', 1000)


" Return max column number of given line expression
" expr: similar to line(), col()
function! s:get_max_col(expr) abort
  return strlen(getline(a:expr)) + 1
endfunction

" x < y -> -1
" x = y -> 0
" x > y -> 1
function! s:compare_pos(x, y) abort
  return max([-1, min([1,(a:x[0] == a:y[0]) ? a:x[1] - a:y[1] : a:x[0] - a:y[0]])])
endfunction


function! s:matchedposes(pattern, ...) abort
  let cache = getbufvar(bufnr('%'), 'searchindex_cache')
  if type(cache) is# type('')
    unlet cache
    let cache = {}
  endif
  if has_key(cache, a:pattern)
    return cache[a:pattern]
  endif

  if line('$') > g:incsearch_searchindex_line_limit
    return []
  else

  let w = winsaveview()
  let [from, to] = [
  \   get(a:, 1, [1, 1]),
  \   get(a:, 2, [line('$'), s:get_max_col('$')])
  \ ]
  let ignore_at_cursor_pos = get(a:, 3, 0)
  " direction flag
  let d_flag = s:compare_pos(from, to) > 0 ? 'b' : ''
  call cursor(from)
  let cnt = 0
  let poses = []
  let base_flag = d_flag . 'W'
  try
    " first: accept a match at the cursor position
    let pos = searchpos(a:pattern, (ignore_at_cursor_pos ? '' : 'c' ) . base_flag)
    while (pos != [0, 0] && s:compare_pos(pos, to) isnot# (d_flag is# 'b' ? -1 : 1))
      let poses += [pos]
      let cnt += 1
      if cnt > g:incsearch_searchindex_count_limit
        let cache[a:pattern] = []
        call setbufvar(bufnr('%'), 'searchindex_cache', cache)
        return []
      endif
      let pos = searchpos(a:pattern, base_flag)
    endwhile
  finally
    call winrestview(w)
  endtry

  let cache[a:pattern] = poses
  call setbufvar(bufnr('%'), 'searchindex_cache', cache)
  return poses
endfunction

function! s:index(pattern) abort
  if a:pattern is# ''
    return [-1, -1]
  endif
  let poses = s:matchedposes(a:pattern)
  let index = index(poses, searchpos(a:pattern, 'ncbW'))
  if index !=# -1
    return [index + 1, len(poses)]
  endif
  return [-1, -1]
endfunction

function! s:clear_cache(...) abort
  call setbufvar(bufnr('%'), 'searchindex_cache', {})
endfunction

augroup incsearch-searchindex
  autocmd!
  if exists("##TextChanged")
    autocmd TextChanged * call s:clear_cache()
    autocmd TextChangedI * call s:clear_cache()
  else
    if exists("##InsertCharPre")
      autocmd InsertCharPre * call s:clear_cache()
    endif
    autocmd BufWritePost * call s:clear_cache()
  endif
augroup END

let s:module = {'name': 'SearchIndex'}

function! s:module.priority(event) abort
  return a:event is# 'on_char' ? 100 : 0
endfunction

function! s:searchindex(cmdline) abort
  if len(a:cmdline.getline()) < g:incsearch_searchindex_minimum_length
    return
  endif
  let index = s:get_index(a:cmdline)
  call s:show_index(a:cmdline, index)
endfunction

function! s:get_index(cmdline) abort
  let [raw_pattern, _] = a:cmdline._parse_pattern()
  let pattern = a:cmdline._convert(raw_pattern)
  return s:index(pattern)
endfunction

function! s:show_index(cmdline, index) abort
  if a:index[0] is# -1
    return
  endif
  let mes = '(' . join(a:index, '/') . ')'
  if g:incsearch_searchindex_pos is# 'right'
    call a:cmdline.set_suffix(mes)
  else
    call a:cmdline.set_prompt(mes . ' /')
  endif
endfunction

function! s:module.on_char(cmdline) abort
  if g:incsearch_searchindex_onchar
    call s:searchindex(a:cmdline)
  endif
endfunction

function! incsearch#over#modules#Index#make() abort
  return deepcopy(s:module)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
