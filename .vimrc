

"+========================+"
"| My vimrc configuration |"
"+========================+"


" TODO
"{{{
"	1. add the surrond method (ex: ys<, cs", ds', viwS[, etc)
"	2. bulk rename in vim(ranger.vim)
"	3. compile in a new tab (or anywhere else, eg: tmux vsplit)
"	4. terminal bell in zsh (without going to tmux)
"	5. Osc52Yank
"	6. add augroup to deal with different platform
"	7. change leader key to space
"	8. map <leader><leader> to `:e #` (which is equivalent to <C-^>)
"}}}


" General
"{{{
	" Auto Reload .vimrc After Saving
	"{{{
		autocmd! bufwritepost .vimrc source %
	"}}}

	" Basic
	"{{{
		set number			" show line numbers
		set relativenumber	" show relativenumber
		" set showbreak=###	" wrap-broken line prefix
		set nowrap			" wrap line which is too long
		set nocompatible	" set not compatible with vi
		set textwidth=80	" line wrap (number of cols)
		set autoindent		" auto-indent new lines
		set smartindent		" enable smart-indent
		set history=500
		set undolevels=500	" number of undo levels (default = 1000)
		set backspace=2		" backspace behaviour
		set confirm			" ask confirm instead of block
		set showcmd			" show the last used command
		set mouse=n			" mouse control (a == all)
		set scrolloff=5		" preserve 5 line after scrolling
		set modeline
		set autochdir	"change the working directory to the directory of the file you opened"
		filetype plugin on
		filetype indent on
		filetype indent plugin on
	"}}}

	" Tab
	"{{{
		set tabstop=4		" Number of spaces per Tab
		set softtabstop=4	" Number of spaces per Tab(virtual tab width)
		set smarttab		" Enable smart-tabs
		set shiftwidth=4	" Number of auto-indent spaces
	"}}}

	" Search and replace
	"{{{
		set showmatch		" Highlight matching brace
		set hlsearch		" Highlight all search results
		set incsearch		" Highlight result while searching
		set smartcase		" Enable smart-case search
		set gdefault		" Always substitute all matches in a line
		set ignorecase		" Always case-insensitive
	"}}}

	" Priorty Of Encoding When Opening File
	"{{{
		set fileencodings=utf-8,big5,utf-16,gb2312,gbk,gb18030,euc-jp,euc-kr,latin1
		set encoding=utf-8
	"}}}
"}}}


" Color
"{{{
	" Theme & stuff
	"{{{
		set t_Co=256			" vim color
		set background=dark		" background
		syntax enable

		" modified theme
		function! MyHighlights() abort
			set cursorline
			hi CursorLine cterm=NONE ctermbg=237
			hi CursorLineNr cterm=none

			hi Folded ctermbg=black ctermfg=241
			hi VertSplit cterm=none ctermfg=0 ctermbg=237

			hi statusline ctermfg=8 ctermbg=15
		endfunction

		" color scheme
		augroup MyColors
			autocmd!
			autocmd ColorScheme * call MyHighlights()
		augroup END
		colo peachpuff
	"}}}

	" Cursor
	"{{{
		" Cursorline
		au InsertEnter * set nocursorline
		au InsertLeave * set cursorline

		" Change cursor in different mode
		let &t_EI = "\e[2 q"	"normal mode
		let &t_SR = "\e[4 q"	"replace mode
		let &t_SI = "\e[6 q"	"insert mode
		" Other options (replace the number after \e[):
		"Ps = 0 -> blinking block.
		"Ps = 1 -> blinking block (default).
		"Ps = 2 -> steady block.
		"Ps = 3 -> blinking underline.
		"Ps = 4 -> steady underline.
		"Ps = 5 -> blinking bar (xterm).
		"Ps = 6 -> steady bar (xterm).
	"}}}

	" Make the 81th column stand out
	"{{{
		hi ColorColumn80 ctermbg=magenta ctermfg=black
		call matchadd('ColorColumn80', '\%81v', -1)
		" -1 means that any search highlighting will override the match highlighting
	"}}}

	" Highlight trailing spaces | spaces before tabs
	"{{{
		hi ExtraWhitespace cterm=underline ctermbg=NONE ctermfg=yellow
		au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
		au InsertLeave * match ExtraWhitespace /\s\+$\| \+\ze\t/
	"}}}

	" Tab bar color
	"{{{
		hi TabLineSel cterm=NONE ctermbg=8 ctermfg=white
		hi TabLine cterm=NONE ctermbg=black ctermfg=darkgray
		hi TabLineFill ctermfg=black
	"}}}

	" Show syntax highlighting groups && color of word under cursor
	"{{{
		nmap <C-S-P> :call <SID>SynStack()<CR>
		function! <SID>SynStack()
			if !exists("*synstack")
				return
			endif
			echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")') synIDattr(synIDtrans(synID(line("."), col("."), 1)), "fg")
		endfunc
	"}}}
"}}}


" Mapping
"{{{
	" Auto complete
	"{{{
		inoremap {<CR> {<CR>}<Esc>ko
	"}}}

	" Other stuff
	"{{{
		" Leader key
		let mapleader = ","
		nmap <leader>l :noh<CR>
		nmap <leader><space> :up<CR>
		nmap <leader><leader> :Vexplore<CR>
		vmap <leader>s :sort<CR>
		nmap <leader>r :source ~/.vimrc<CR>

		" Esc
		imap jj <esc>
		imap kk <esc>

		" Moving the cursor
		imap <C-h> <left>
		imap <C-j> <down>
		imap <C-k> <up>
		imap <C-l> <right>
		nmap <C-j> 4jzz
		vmap <C-j> 4jzz
		nmap <C-k> 4kzz
		vmap <C-k> 4kzz

		" Navigate between splits/tabs
		nmap <C-h> <C-w><C-h>
		nmap <C-l> <C-w><C-l>
		nmap gc :tabnew<CR>

		" Useful short cut
		nmap ; :
		imap <C-a> <esc>^i
		imap <C-e> <end>
		cmap <C-a> <home>
		cmap <C-e> <end>
		nmap <C-f> /
		nmap <silent><F2> :up<CR>:!clear && make<CR>
		nmap <S-k> k<S-j>
		nmap Y y$
		" vmap > >gv
		" vmap < <gv
	"}}}
"}}}


" Something Fancy
"{{{
	" Statusline
	"{{{
		" Info showed on statusline
		"{{{
			set laststatus=2								" show two statusline
			set statusline=[%{expand('%:F')}]\ 				" path and file name
			set statusline+=[%{strlen(&fenc)?&fenc:'none'}  " file encoding
			set statusline+=,\ %{&ff}						" file format
			set statusline+=,\ %{strlen(&ft)?&ft:'plain'}]	" filetype
			set statusline+=\ %m							" modified flag
			set statusline+=\ %h							" help file flag
			set statusline+=\ %r							" read only flag
			set statusline+=\ %=							" align left
			set statusline+=Line:%l/%L[%p%%]				" line X of Y [percent of file]
			set statusline+=\ Col:[%c]						" current column
			set statusline+=\ ASCII:[%b]\ 					" ASCII code under cursor
			" set statusline+=\ Buf:%						" Buffer number
			" set statusline+=\ [0x%B]\						" byte code under cursor
		"}}}

		" Change the color of statusline
		"{{{
			" Different color in different mode
			function! InsertStatuslineColor(mode)
				if a:mode == 'i'
					hi statusline ctermfg=2 ctermbg=0
				elseif a:mode == 'r'
					hi statusline ctermfg=1 ctermbg=0
				endif
			endfunction
			au InsertEnter * call InsertStatuslineColor(v:insertmode)
			au InsertLeave * hi statusline ctermfg=8 ctermbg=15
		"}}}
	"}}}

	" Blink search matches
	"{{{
		hi Search ctermfg=0 ctermbg=124
		function! HINext(blinktime)
			" zz
			let target_pat = '\c\%#'.@/
			let blinks = 2
			for n in range(1, blinks)
				let ring = matchadd('ErrorMsg', target_pat, 101)
				redraw
				exec 'sleep' . float2nr(a:blinktime / (2*blinks) * 600) . 'm'
				call matchdelete(ring)
				redraw
				exec 'sleep' . float2nr(a:blinktime / (2*blinks) * 600) . 'm'
			endfor
		endfunction
		nmap <silent> n n:call HINext(0.15)<cr>
		nmap <silent> N N:call HINext(0.15)<cr>
	"}}}

	" File searching
	"{{{
		set path+=**		" search down into subfolder,also enable tab to complete
		set wildmenu		" Display all matching files; use * to make it fussy
		set wildignore+=node_modules/*
	"}}}

	" File browsing(netrw)
	"{{{
		let g:netrw_banner=0		" disable annoying banner
		let g:netrw_liststyle=3		" tree view
		let g:netrw_browse_split=4	" open in prior window
		let g:netrw_altv=1			" open splits to the right
		let g:netrw_winsize = 16	" the percentage of the size
		let g:netrw_preview = 1		" use 'p' to preview the file in netRW
" 		let g:netrw_list_hide=netrw_gitignore#Hide()
" 		let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'

		" open netrw automatically
" 		augroup ProjectDrawer
" 			autocmd!
" 			autocmd VimEnter * :Vexplore
" 		augroup END

		" NOW WE CAN:
		" - :edit a folder to open a file browser
		" - <CR>/v/t to open in an h-split/v-split/tab
		" - check |netrw-browse-maps| for more mappings
	"}}}

	" Warning message
	"{{{
		function! EchoMsg(msg)
			echohl WarningMsg
			echo a:msg
			echohl None
		endfunction
	"}}}

	" Copy to clipboard
	"{{{
		set pastetoggle=<F12>
		nmap <F12> :w !clip.exe<CR><CR>:call EchoMsg('File "'.@%.'" copied to clipboard!')<CR>
		vmap <F12> :'<,'>w !clip.exe<CR><CR>:call EchoMsg('Copied to clipboard!')<CR>
		nmap <leader>y :call system('clip.exe', @0)<CR>:call EchoMsg('Copied to clipboard!')<CR>
		if exists('$TMUX')
			vmap <leader>c :'<,'>w !tmux load-buffer -<CR><CR>:call EchoMsg('Copied to tmux!')<CR>
		endif

		" the `xclip` way
		"nmap <F12> :up<CR>:!xclip -i -selection clipboard % <CR><CR>
		"vmap <F12> :'<,'>w !xclip<CR><CR>
		"nmap <silent><leader>c :call system('xclip', @0)<CR>

		function! Osc52Yank()
			let buffer=system('base64 -w0', @0)
			let buffer='\ePtmux;\e\e]52;c;'.buffer.'\x07\e\\'
			" let pane_tty=system("tmux list-panes -F '#{pane_active} #{pane_tty}' | awk '$1==1 { print $2 }'")
			let pane_tty='/dev/pts/4'
			exe "!echo -ne ".shellescape(buffer)." > ".shellescape(pane_tty)
		endfunction
		"nnoremap <leader>y :call Osc52Yank()<CR>
	"}}}
"}}}


" Based On Filetype
"{{{
	" Folding
	"{{{
		" Custom folding expression
		"{{{
			function! CustomFoldExpr(cmt)
				let thisline = getline (v:lnum)
				let tmp = a:cmt
				if a:cmt == '//'
					let tmp = tmp.' '
				endif
				if thisline =~ '\v^\s*$'	"empty line
					return '-1'
				elseif thisline =~ '^'.tmp.'###'
					return '>3'
				elseif thisline =~ '^'.tmp.'##'
					return '>2'
				elseif thisline =~ '^'.tmp.'#'
					return '>1'
				else
					return '='
				endif
			endfunction
		"}}}

		" Custom folding text
		"{{{
			function! CustomFoldText(cmt)
				let thisline = getline (v:foldstart)
				let foldsize = (v:foldend-v:foldstart)
				let tmp = a:cmt
				if a:cmt == '//'
					let tmp = tmp.' '
				endif
				if thisline =~ '^'.tmp.'###'
					return '    '. '    '. getline(v:foldstart). ' ('.foldsize.' lines)'
				elseif thisline =~ '^'.tmp.'##'
					return '    '. getline(v:foldstart). ' ('.foldsize.' lines)'
				elseif thisline =~ '^'.tmp.'#'
					return getline(v:foldstart). ' ('.foldsize.' lines)'
				else
					return getline(v:foldstart). ' ('.foldsize.' lines)'
				endif
			endfunction
		"}}}

		" Folding based on filetype
		"{{{
		" <zf> to create, <zx> <za> to fold and expand
			function! CustomFolding()
				set foldlevel=0
				set foldnestmax=3
				if &ft == 'c' || &ft == 'cpp' || &ft == 'rust' || &ft == 'go'
					set foldmethod=expr
					set foldexpr=CustomFoldExpr('//')
					set foldtext=CustomFoldText('//')
				elseif &ft == 'python'
					set foldmethod=expr
					set foldexpr=CustomFoldExpr('#')
					set foldtext=CustomFoldText('#')
				else
					set foldmethod=marker
				endif
			endfunction
		"}}}
	"}}}

	" Commenting
	"{{{
		" Toggle comment method
		"{{{
			function! ToggleCommentMethod(cmt)
				let line = getline('.')
				if line =~ '[^\s]'
					if matchstr(line, '^\s*'.a:cmt.'.*$') == ''
						exec "normal! mqI".a:cmt."\<esc>`q"
					else
						exec 's:'.a:cmt.'::'
					endif
				endif
			endfunction
		"}}}

		" Comment based on filetype
		"{{{
			function! ToggleComment()
				if &ft == 'c' || &ft == 'cpp' || &ft == 'rust' || &ft == 'go'
					nmap <silent> <C-c> :call ToggleCommentMethod('// ')<cr>
				elseif &ft == 'python'
					nmap <silent> <C-c> :call ToggleCommentMethod('# ')<cr>
				elseif &ft == 'vim'
					nmap <silent> <C-c> :call ToggleCommentMethod('" ')<cr>
				endif
			endfunction
		"}}}
	"}}}

	" Handle config for various filetypes
	"{{{
		function! HandleFiletypes()
			if &ft == 'c' || &ft == 'cpp'
				set cindent		"enable smart indent in c language
				nmap <silent><F5> :up<CR>:!clear && g++ % -static -lm --std=c++11 -Wall -Wextra -Wshadow && echo "> Running " && ./a.out < in<CR>
				nmap <silent><F9> :up<CR>:!clear && g++ % -static -lm --std=c++11 -Wall -Wextra -Wshadow && echo "> Running " && ./a.out<CR>
			elseif &ft == 'rust'
				" TODO: format file after save
				nmap <silent><F9> :up<CR>:!clear && rustc % && echo "> Running" && ./%<<CR>
				nmap <silent><F5> :up<CR>:!clear && rustc % && echo "> Running" && ./%< < in<CR>
			elseif &ft == 'go'
				nmap <silent><F5> :up<CR>:!clear && echo "> Running " && go run % < in<CR>
				nmap <silent><F9> :up<CR>:!clear && echo "> Running " && go run %<CR>
				syn match parens /[{}]/ | hi parens ctermfg=red
			elseif &ft == 'java'
				nmap <silent><F5> :up<CR>:!clear && javac % && echo "> Running " && java -cp "%:p:h" "%:t:r" < in<CR>
				nmap <silent><F9> :up<CR>:!clear && javac % && echo "> Running " && java -cp "%:p:h" "%:t:r"<CR>
			endif
		endfunction
		au filetype * call CustomFolding()
		au filetype * call ToggleComment()
		au filetype * call HandleFiletypes()
	"}}}
"}}}




