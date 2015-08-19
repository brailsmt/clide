" Mappings for ease of working with junit tests

" Open the JUnit test for the file passed in.  Intended to be called from the file loaded in the current buffer.
function! OpenEitherJUnitOrSource(fname)
    let l:fname = ""
    if a:fname !~ "Test\.java"
        let l:fname = fnamemodify(a:fname, ":s#src/main/java#src/test/java#")
        let l:fname = fnamemodify(l:fname, ":s#\.java$#Test.java#")
    else
        let l:fname = fnamemodify(a:fname, ":s#src/test/java#src/main/java#")
        let l:fname = fnamemodify(l:fname, ":s#Test\.java$#.java#")
    endif

    if bufexists(l:fname) && !bufloaded(l:fname)
        let l:bufnr = bufnr(bufname(l:fname))
        exec "split #".l:bufnr
    else
        exec "split ".l:fname
    endif
endfunction
