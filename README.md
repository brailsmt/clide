Project to create a command line IDE.  This is mainly due to the time it takes for maven to compile
small changes in code and how poorly it integrates with vim/gvim.  Along with a healthy distaste for 
one-size-fits-all IDEs.

Update 01/05/2016:
-----------------
So, this is what I get for starting a project with little more than a vague idea of what I want.  After hacking around
for awhile, I have to come to conclusion that an IDE requires a significant amount of configuration.  Maven is lifecycle
management tool, not a development tool.  I feel that a very large amount of the benefit of clide will be in
de-constructing the maven configuration into a format that is easily accessible from the command line.  The first
release of neovim has sparked a much renewed interest in this project.  In the past week, I've hacked together enough to
initialize a project, calculate md5s for poms and source files and generate classpaths.

I've come to realize that I need to modify my approach.  I have been relying quite heavily on Ruby, and I will continue
to do so, but I want clide to be wide open for any language a plugin writer may choose to use.  Drawing heavily on the
idea of git and it's genesis as shell scripts, that seems to be a good model.  To that end, at the moment, clide will
become little more than a tool to deconstruct pom.xml files and store them in a directory structure that can easily be
consumed anything, but especially by shell scripts, as I feel that is the lowest common denominator, and is already a
very well defined and well understood interface with stdin, stdout, and stderr.  There may very well be faster ways to
access this data, but that is a discussion for another day, when or if performance becomes a concern.
