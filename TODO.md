The following are things that need to be done.  I have seen a lot of the features that IntelliJ and Eclipse have.  Many
of them are nice, and important for productivity.  Unfortunately, any IDE forces you into doing things the way they
intend.  I have my own workflows, so I want to take the best parts of these tools and make them available from a command
line application that can be scripted to create all sorts of things.

- parse maven output
  - error locations and messages
  - warning locations and messages
  - junit failures locations and messages
  - integrate with vim's quickfix format and create an interface in vim to view each of the above, or any combination
    thereof
- fast builds
  - maven is horrendously slow
  - compile only what is needed, and only when needed
  - perfection is not required, 100% accuracy for builds in development is less important that fast turn around time
- modular
  - look to git's plumbing/porcelain
  - the interface between modules is stdout/stdin, format stability is important
    - would be nice to do named pipes/sockets
- auto-import based on dependencies
- error indications upon saving
- simple navigation history
