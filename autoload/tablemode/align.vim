" Borrowed from Tabular
" Private Functions {{{1
" function! s:StripTrailingSpaces(string) - Remove all trailing spaces {{{2
" from a string.
function! s:StripTrailingSpaces(string)
  return matchstr(a:string, '^.\{-}\ze\s*$')
endfunction

function! s:Padding(string, length, where) "{{{3
  let gap_length = a:length - tablemode#utils#strlen(a:string)
  if a:where =~# 'l'
    return a:string . repeat(" ", gap_length)
  elseif a:where =~# 'r'
    return repeat(" ", gap_length) . a:string
  elseif a:where =~# 'c'
    let right = spaces / 2
    let left = right + (right * 2 != gap_length)
    return repeat(" ", left) . a:string . repeat(" ", right)
  endif
endfunction

" function! s:Split() - Split a string into fields and delimiters {{{2
" Like split(), but include the delimiters as elements
" All odd numbered elements are delimiters
" All even numbered elements are non-delimiters (including zero)
function! s:Split(string, delim)
  let rv = []
  let beg = 0

  let len = len(a:string)
  let searchoff = 0

  while 1
    let mid = match(a:string, a:delim, beg + searchoff, 1)
    if mid == -1 || mid == len
      break
    endif

    let matchstr = matchstr(a:string, a:delim, beg + searchoff, 1)
    let length = strlen(matchstr)

    if length == 0 && beg == mid
      " Zero-length match for a zero-length delimiter - advance past it
      let searchoff += 1
      continue
    endif

    if beg == mid
      let rv += [ "" ]
    else
      let rv += [ a:string[beg : mid-1] ]
    endif

    let rv += [ matchstr ]

    let beg = mid + length
    let searchoff = 0
  endwhile

  let rv += [ strpart(a:string, beg) ]

  return rv
endfunction

" Public Functions {{{1
function! tablemode#align#sid() "{{{2
  return maparg('<sid>', 'n')
endfunction
nnoremap <sid> <sid>

function! tablemode#align#scope() "{{{2
  return s:
endfunction

function! tablemode#align#Align(lines) "{{{2
  let lines = map(a:lines, 's:Split(v:val, g:table_mode_separator)')

  for line in lines
    if len(line) <= 1 | continue | endif

    if line[0] !~ tablemode#table#StartExpr()
      let line[0] = s:StripTrailingSpaces(line[0])
    endif
    if len(line) >= 2
      for i in range(1, len(line)-1)
        let line[i] = tablemode#utils#strip(line[i])
      endfor
    endif
  endfor

  let maxes = []
  for line in lines
    if len(line) <= 1 | continue | endif
    for i in range(len(line))
      if i == len(maxes)
        let maxes += [ tablemode#utils#strlen(line[i]) ]
      else
        let maxes[i] = max([ maxes[i], tablemode#utils#strlen(line[i]) ])
      endif
    endfor
  endfor

  for idx in range(len(lines))
    let line = lines[idx]

    if len(line) <= 1 | continue | endif
    for i in range(len(line))
      if line[i] !~# '[^0-9\.]'
        let field = s:Padding(line[i], maxes[i], 'r')
      else
        let field = s:Padding(line[i], maxes[i], 'l')
      endif

      let line[i] = field . (i == 0 || i == len(line) ? '' : ' ')
    endfor

    let lines[idx] = s:StripTrailingSpaces(join(line, ''))
  endfor

  return lines
endfunction
