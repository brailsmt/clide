function! LoadOnlyMavenErrors()
    cgetfile .clide/maven.out

    let l:mavenOutput = getqflist()
    call setqflist([],'r') 

    for d in l:mavenOutput
        if d.type == 'E' 
            call setqflist([d],'a') 
        endif 
    endfor
endfunction

function! LoadOnlyMavenWarnings()
    cgetfile .clide/maven.out

    let l:mavenOutput = getqflist()
    call setqflist([],'r') 

    for d in l:mavenOutput
        if d.type == 'W' 
            call setqflist([d],'a') 
        endif 
    endfor
endfunction

function! EclimLocationListToQuickfix()
    call setqflist([],'r') 
    for error in getloclist(0)
        if error.type == 'E' || error.type == 'e'
            call setqflist([error],'a') 
        endif
    endfor
endfunction
