

"+==========================+"
"| Configuration for python |"
"+==========================+"


" Compile option
"{{{
	nmap <silent><F9> :w<CR> :!clear && echo "> Running" && python3 % <CR>
	nmap <silent><F5> :w<CR> :!clear && echo "> Running" && python3 % < in<CR>
"}}}

" Tweak
"{{{
	hi pythonBuiltin cterm=NONE ctermfg=121
	hi pythonStatement ctermfg=14
"}}}


