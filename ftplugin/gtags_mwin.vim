" Author: Kalimuthu Velappan
" Version: 1.2
" Last Modified: June 04, 2012
" Email: kalmuthu@gmail.com
" Desription: Gtag support for multiwindow

" Copyright and licence
" ---------------------
" Copyright (c) 2012 Innovace Technology Solutions
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" Overview
" --------
" The gtags.vim plug-in script integrates the GNU GLOBAL source code tag system
" with Vim. About the details, see http://www.gnu.org/software/global/.
"
" Installation
" ------------
" Drop the file in your plug-in directory or source it from your vimrc.
" To use this script, you need the GNU GLOBAL-5.7 or later installed
" in your machine.

" Usage
" -----
" 
" 1. To go to symbol(variable/function) definition, place cursor cursor under the symbol
"    and press Ctl + \, you would get the similar to following:
"     
"     ============= TAG : [FILE_NAME_LENGTH] ================
"     main/system/header.h  70  #define FILE_NAME_LENGTH  32    
"     main/control/views.h  17  #define FILE_NAME_LENGTH  24 
"     main/program/forms.h  23  #define FILE_NAME_LENGTH  12    
"	  ... 
"     Cursor is place under the list, Press <ENTER> key to select/navigate the tag
" 
" 2. To go to reference of the symbol(variable/function) definition, place cursor cursor 
"     under the symbol and press Ctl + R, you would get the similar to following:
"     
"     ============= TAG : [FILE_NAME_LENGTH] ================
"     main/system/header.c  70  int len = FILE_NAME_LENGTH;
"     main/control/views.c  17  size = FILE_NAME_LENGTH+1;
"     main/program/forms.c  23  int max = FILE_NAME_LENGTH + 12;
"     ...
"     Cursor is place under the list, Press <ENTER> key to select/navigate the tag
" 
" 
" 3. Similarly, to get the variable symbol definition, place cursor cursor under the symbol
"    and press Ctl + S.
"     
" 4. To browse the Tag Stack, press Ctl + T key, you would get similar to the following.
" 
"    ============================== TAG : [StackTag]========================
"    main/system/process.c         | 5         | FILE_NAME_LENGTH    | FILE
"	 1_1_FILE_NAME_LENGTH_1        | 2         | FILE_NAME_LENGTH    | TAG
"	 main/system/header.c          | 95        | FILE_NAME_LENGTH    | FILE
" 
" 
" If you dont want the multiwindow support, You can use the suggested key mapping with the following code:
"
"	[$HOME/.vimrc]
"	let No_Gtags_Multi_Window_Auto_Map = 1
"

if exists("loaded_gtags_multi_window")
    finish
endif


if !exists("g:Gtags_Result_Format")
    let g:Gtags_Result_Format = "ctags-mod"
endif

" Character to use to quote patterns and file names before passing to global.
" (This code was drived from 'grep.vim'.)
if !exists("g:Gtags_Shell_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let g:Gtags_Shell_Quote_Char = '"'
    else
        let g:Gtags_Shell_Quote_Char = "'"
    endif
endif
if !exists("g:Gtags_Single_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let g:Gtags_Single_Quote_Char = "'"
        let g:Gtags_Double_Quote_Char = '\"'
    else
        let s:sq = "'"
        let s:dq = '"'
        let g:Gtags_Single_Quote_Char = s:sq . s:dq . s:sq . s:dq . s:sq
        let g:Gtags_Double_Quote_Char = '"'
    endif
endif

"
" Display error message.
"
function! s:Error(msg)
    echohl WarningMsg |
           \ echomsg 'Error: ' . a:msg |
           \ echohl None
endfunction
"
" Trim options to avoid errors.
"
function! s:TrimOption(option)
    let l:option = ''
    let l:length = strlen(a:option)
    let l:i = 0

    while l:i < l:length
        let l:c = a:option[l:i]
        if l:c !~ '[cenpquv]'
            let l:option = l:option . l:c
        endif
        let l:i = l:i + 1
    endwhile
    return l:option
endfunction

"
" Execute global and load the result into quickfix window.
"
function! s:ExecLoad(option, long_option, pattern)
    " Execute global(1) command and write the result to a temporary file.
    let l:isfile = 0
    let l:option = ''
    let l:result = ''

    if a:option =~ 'f'
        let l:isfile = 1
        if filereadable(a:pattern) == 0
            call s:Error('File ' . a:pattern . ' not found.')
            return
        endif
    endif
    if a:long_option != ''
        let l:option = a:long_option . ' '
    endif
    let l:option = l:option . '--result=' . g:Gtags_Result_Format
    let l:option = l:option . ' -q'. s:TrimOption(a:option)
    if l:isfile == 1
        let l:cmd = 'global ' . l:option . ' ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char
    else
        let l:cmd = 'global ' . l:option . 'e ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char 
    endif

    "echoerr "CMD = ".l:cmd

    let l:result = system(l:cmd)
    if v:shell_error != 0
        if v:shell_error != 0
            if v:shell_error == 2
                call s:Error('invalid arguments. (gtags.vim requires GLOBAL 5.7 or later)')
            elseif v:shell_error == 3
                call s:Error('GTAGS not found.')
            else
                call s:Error('global command failed. command line: ' . l:cmd)
            endif
        endif
        return
    endif
    if l:result == '' 
        if l:option =~ 'f'
            call s:Error('Tag not found in ' . a:pattern . '.')
        elseif l:option =~ 'P'
            call s:Error('Path which matches to ' . a:pattern . ' not found.')
        elseif l:option =~ 'g'
            call s:Error('Line which matches to ' . a:pattern . ' not found.')
        else
            call s:Error('Tag which matches to ' . g:Gtags_Shell_Quote_Char . a:pattern . g:Gtags_Shell_Quote_Char . ' not found.')
        endif
        return
    endif

    call OpenTag(a:pattern, l:result)

endfunction



" ---------------------------- MULTIWINDOW   GTAG  ----------------------------------------

function! s:GtagsCursor_x()
    let l:pattern = expand("<cword>")
    call s:ExecLoad('x', ' ', l:pattern)
endfunction


function! s:GtagsCursor_r()
    let l:pattern = expand("<cword>")
    call s:ExecLoad('r', ' ', l:pattern)
endfunction

function! s:GtagsCursor_s()
    let l:pattern = expand("<cword>")
    call s:ExecLoad('s', ' ', l:pattern)
endfunction

" shortcut Keys
" The key maps are assigned based on the easier and closer to the finger.
"	[$HOME/.vimrc]
"	let No_Gtags_Multi_Window_Auto_Map = 1
"

if !exists("No_Gtags_Multi_Window_Auto_Map")
    let No_Gtags_Multi_Window_Auto_Map = 0
endif

if g:No_Gtags_Multi_Window_Auto_Map == 0
	:noremap <C-\>   :call <SID>GtagsCursor_x()<CR>
	:noremap <C-R>   :call <SID>GtagsCursor_r()<CR>
	:noremap <C-S>   :call <SID>GtagsCursor_s()<CR>
	:noremap <C-T>   :call SelectWindowStackTag()<CR>
	:noremap <C-d>   :call CloseTag() <CR>
	:noremap <C-B>   :call DisplayWindowStack() <CR>
endif



let s:Tag={"TagName":"NULL", "TagFileName":"NULL","CurPos":0, "TagType":"NULL" }
let s:Stack=[]
let s:TagStack={"TagStack":0, "TagIndex":0, "CurrentTag":0}
let s:Window=[]
silent highlight GtagsGroup ctermbg=DarkGrey guibg=DarkGrey

if !exists("loaded_gtags_multi_window")
    call add(s:Window, copy(s:TagStack))
endif
" Get the window number associated with it
function! GetWindowNumber()
    while len(s:Window) <= winnr("$")
        call AddWindow()
    endwhile
    return winnr()
endfunction

" Debug functions
function! DisplaySetup()
    call add(s:Stack, copy(s:Tag))
    let s:TagStack.TagStack=copy(s:Stack)
    call add(s:Window, copy(s:TagStack) )
    let s:Window[0].TagStack[0].TagName="TEST"
    echo  "Tag name=". s:Window[0].TagStack[0].TagName
endfunction

function! GetTagFileName(tag_name)
    let win_idx = GetWindowNumber()
    let tag_idx = s:Window[win_idx].TagIndex
    return GetWindowNumber() ."_". winbufnr(0) ."_". a:tag_name."_".tag_idx
endfunction

" Open new Buffer
function! OpenBuffer(tag_name, file_name, tag_type)
    if !bufexists(a:file_name)
        execute("badd ". a:file_name)
    endif
endfunction 

" Close the buffer
function! CloseBuffer(tag_name, file_name, tag_type)
    if bufexists(a:file_name)
        execute("bwipeout ". a:file_name)
    endif
endfunction 

" Load the buffer for the given filename
function! LoadBuffer(tag_name, file_name, line_no, tag_type, file_content)
    if !bufexists(a:file_name)
        call OpenBuffer(a:tag_name, a:file_name, a:tag_type)
    endif
    execute("buffer ". a:file_name)
    if a:tag_type == "TAG" 
        setlocal modifiable
        silent put=a:file_content
        call setline(1,"=========================================TAG : [".a:tag_name."]=========================================")
        setlocal nomodifiable
        setlocal buftype=nowrite buflisted
        setlocal noswapfile
        setlocal cursorline 
        silent noremap <buffer> <Enter> :call SelectTag() <CR>
        silent noremap <buffer> <C-\> 
	else
		call system("echo \"history -s \"v ".a:file_name. "\"\" >> /tmp/vfiles.txt")
    endif
    call cursor(a:line_no,1)
    call search(a:tag_name, '', line("."))
    call SetStackTopTag(a:tag_name, a:file_name, a:tag_type)
    call SelectMatch("GtagsGroup", a:tag_name)
endfunction 

function! SelectMatch(group, tag_name)
    call clearmatches()
    if GetStackTopTagIndex() > 0 
        call matchadd(a:group, a:tag_name)
    endif
endfunction

" Select the buffer based on the Tag 
function! SelectBuffer(tag)
    if !bufexists(a:tag.TagFileName)
        call SetStackTopTag(a:tag.TagName, a:tag.TagFileName, a:tag.TagType)
        return CloseTag()
    endif
    execute("buffer ". a:tag.TagFileName)
    call setpos(".", a:tag.CurPos)
    call SelectMatch("GtagsGroup", a:tag.TagName)
    call SetStackTopTag(a:tag.TagName, a:tag.TagFileName, a:tag.TagType)
endfunction 

" Copy the Current tag details to Stack top
function! CopyCurrentToStackTop()

    let tag_type = GetStackTopTagType()
    if tag_type != "FILE" 
        return
    endif
    if GetStackTopTagIndex() <= 0 
        return
    endif
    let tag = GetStackTopTag()
    let current_pos = getpos(".")
    if line(".") == tag.CurPos[1] 
        return
    endif
    call PushCurrentTag(tag)
endfunction

" Open the new tag
function! OpenTag(tag_name, content )
    call CopyCurrentToStackTop()
    call PushTag(a:tag_name, bufname("%"))
    let tag_file_name = GetTagFileName(a:tag_name)
    call LoadBuffer(a:tag_name, tag_file_name, 2, "TAG", a:content )
    call AutoSelectTag()
    
endfunction

" Close the tag 
function! CloseTag()
    let win_idx = GetWindowNumber()
    let tag_idx = s:Window[win_idx].TagIndex-1
    if tag_idx < 0 
        echohl WarningMsg | echo "Bottom of Stack" | echohl None
        return
    endif
    let ctag=GetStackTopTag()
    let tag=PopTag()
    call SelectBuffer(tag)
    if ctag.TagType == "TAG"
        call CloseBuffer( ctag.TagName, ctag.TagFileName, ctag.TagType)
    endif
    call AutoCloseTag()
endfunction 

" Automatically close the tag window when only one entry in the tag window
function! AutoCloseTag()

    let tag=GetStackTopTag()
    if tag.TagType != "TAG"
        return
    endif

    if line(".") <= 1
        return 
    endif
    if line("$") > 2
        return 
    endif
    call CloseTag()
endfunction 

" Select the Tag from Tag window
function! SelectTag()
    if line(".") <= 1
        return 
    endif
    let tag = GetStackTopTag()
    let words = split(getline("."), '\t')
    let file_name = substitute( words[0], " ", "", "g")
    let line_no = words[1]
    let line_cnt = words[2]
    call PushTag(tag.TagName, bufname("%"))
    call LoadBuffer(tag.TagName, file_name, line_no, "FILE", "")
endfunction

" Automatically select the tag from tag window when there is only one entry
function! AutoSelectTag()
    if line(".") <= 1
        return 
    endif
    if line("$") > 2
        return 
    endif
    call SelectTag()
endfunction

" Update the top stack contents
function! PushCurrentTag(ctag)
    let win_idx = GetWindowNumber()
    let tag_idx = s:Window[win_idx].TagIndex
    let tag = copy(s:Tag)
    let tag.TagName = a:ctag.TagName
    let tag.TagFileName = a:ctag.TagFileName
    let tag.CurPos = copy(a:ctag.CurPos)
    let tag.TagType = a:ctag.TagType
    call add(s:Window[win_idx].TagStack, tag )
    let s:Window[win_idx].TagIndex = tag_idx+1
endfunction

" Push the tag to stack
function! PushTag(tag_name, tag_filename)
    let win_idx = GetWindowNumber()
    let tag_idx = s:Window[win_idx].TagIndex
    let tag_type = GetStackTopTagType()
    let tag = copy(s:Tag)
    let tag.TagName = a:tag_name
    let tag.TagFileName = a:tag_filename
    let tag.CurPos = getpos(".")
    let tag.TagType = tag_type
    call add(s:Window[win_idx].TagStack, tag )
    let s:Window[win_idx].TagIndex = tag_idx+1
endfunction

" Pop the tag from stack
function! PopTag()
    let win_idx = GetWindowNumber()
    let tag_idx = s:Window[win_idx].TagIndex-1
    if tag_idx < 0 
        echo "Bottom of Stack"
        return 0
    endif
    let tag = copy(s:Window[win_idx].TagStack[tag_idx])
    call remove(s:Window[win_idx].TagStack, tag_idx)
    let s:Window[win_idx].TagIndex = tag_idx
    return tag
endfunction

" Get the top of the stack index
function! GetStackTopTagIndex()
    let win_idx = GetWindowNumber()
    let tag_idx = s:Window[win_idx].TagIndex
    return tag_idx
endfunction

" Get the top of the stack tag
function! GetStackTopTag()
    let win_idx = GetWindowNumber()
    let tag = copy(s:Window[win_idx].CurrentTag)
    return tag
endfunction

" Set the current top tag contents
function! SetStackTopTag(tag_name, tag_filename, tag_type)
    let win_idx = GetWindowNumber()
    let s:Window[win_idx].CurrentTag.TagName = a:tag_name
    let s:Window[win_idx].CurrentTag.TagFileName = a:tag_filename
    let s:Window[win_idx].CurrentTag.CurPos = getpos(".")
    let s:Window[win_idx].CurrentTag.TagType = a:tag_type
endfunction

" Get the tag type either FILE or TAG
function! GetStackTopTagType()
    let win_idx = GetWindowNumber()
    let tag_type = s:Window[win_idx].CurrentTag.TagType
    if tag_type == "NULL"
        let tag_type = "FILE"
    endif
    return tag_type
endfunction

" Debug functions
function! DisplayStackTopTag(index)
    let tag = copy(s:Window[a:index].CurrentTag)
    call DisplayTag(tag)
endfunction

" Debug functions
function! DisplayTag(tag)
    echo printf(" %-30.30s | %-9s | %-5s | %s ",  a:tag.TagName, a:tag.TagType, a:tag.CurPos[1],  a:tag.TagFileName ) 
endfunction
function! GetTagContent(tag)
    return printf("%-50s\t| %-9s\t| %-5s\t| %s\n", a:tag.TagFileName, a:tag.CurPos[1], a:tag.TagName, a:tag.TagType ) 
endfunction

" Init the stack
function! OpenStack(index)
    let s:Window[a:index].TagStack = copy(s:Stack)
    let s:Window[a:index].CurrentTag = copy(s:Tag)
    let s:Window[a:index].TagIndex = 0
endfunction

" Uninit  stack
function! CloseStack(index)
    if  len(s:Window[a:index].TagStack) > 0 
        call remove(s:Window[a:index].TagStack, 0, len(s:Window[a:index].TagStack)-1)
    endif
    let s:Window[a:index].TagStack = 0
    let s:Window[a:index].TagIndex = 0
endfunction

" Display the tag stack
function! DisplayStack(index)
    for i in range(len(s:Window[a:index].TagStack)-1, 0, -1)
        call DisplayTag( s:Window[a:index].TagStack[i] )
    endfor
endfunction

" Get the top of the stack
function! GetStackContent(index)
    let stack_content=""
    for i in range(len(s:Window[a:index].TagStack)-1, 0, -1)
        let stack_content .= GetTagContent( s:Window[a:index].TagStack[i] )
    endfor
    return stack_content
endfunction

" Get the window index for tag
function! OpenWindow(index)
    if a:index > len(s:Window) 
        echoerr "Open: Out of index = ".a:index. ",len=". len(s:Window)
        return
    endif
    call insert(s:Window, copy(s:TagStack), a:index )
    call OpenStack(a:index)
endfunction

" Uninitialize the window 
function! CloseWindow(index)
    if a:index > len(s:Window) || a:index < 1 
        echoerr "Close: Out of index = ".a:index. ",len=". len(s:Window)
        return
    endif
    call CloseStack(a:index)
    call remove(s:Window, a:index )
endfunction

" Initialize the new window
function! AddWindow()
    call add(s:Window, copy(s:TagStack))
    call OpenStack(len(s:Window)-1)
endfunction

" Window debug function
function! DisplayWindow()
    for i in range(1, len(s:Window)-1)
        echo "Window[".i."] TagIndex = ".s:Window[i].TagIndex
    endfor
endfunction

" Debug function to display the tag stack
function! DisplayWindowStack()
    for i in range(1, len(s:Window)-1)
        echo "Window[".i."] TagIndex = ".s:Window[i].TagIndex
        echo "-------------------------------------Tag Stack------------------------------------"
        call DisplayStackTopTag(i)
        call DisplayStack(i)
    endfor
endfunction

" Select the tag from window tag stack
function! SelectWindowStackTag()
    let win_idx = GetWindowNumber()
    let stack_content = GetStackContent(win_idx)
    if stack_content == ""
        echohl WarningMsg | echo "Stack is Empty" | echohl None
        return
    endif
    call OpenTag("StackTag", stack_content)
endfunction



" Setup the buffer for window
let s:loadmsg=""
let s:Event={"LastEvent":"NULL", "LastWinCount":0, "LastWinNo":1 }
function! EnterBufWindow()
    if  s:Event.LastWinCount > winnr("$")
        call CloseWindow(s:Event.LastWinNo)
    endif

    if s:Event.LastWinCount  == 0
        call OpenWindow(s:Event.LastWinNo)
    endif

    let s:Event.LastWinCount = winnr("$")
    let s:Event.LastWinNo = winnr()
endfunction

" Setup the window for tag
function! EnterWindow()
    if  s:Event.LastWinCount > winnr("$")
        call CloseWindow(s:Event.LastWinNo)
    endif
    let s:Event.LastWinCount = winnr("$")
    let s:Event.LastWinNo = winnr()
endfunction

" clearup while leaving from window
function! LeaveWindow()
    if s:Event.LastWinCount < winnr("$")
        call OpenWindow(s:Event.LastWinNo)
    endif
    if s:Event.LastWinCount > winnr("$")
        call CloseWindow(s:Event.LastWinNo)
    endif
    let s:Event.LastEvent = "Leave"
    let s:Event.LastWinCount = winnr("$")
    let s:Event.LastWinNo = winnr()

endfunction

"window debug message
function! LoadMsg()
    echo "Num of win =". s:loadmsg
    echo "Len = ".len(s:Window)
endfunction

autocmd BufWinEnter    * :call EnterBufWindow()
autocmd WinEnter       * :call EnterWindow()
autocmd WinLeave       * :call LeaveWindow()

let loaded_gtags_multi_window = 1











