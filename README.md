# Continuous compilation and deployment of LaTeX files

This is a small set of scripts to enable continuous compilation and deployment of LaTeX files in a GitHub repository. This is what this thing does:

* Start a Ruby/Sinatra server listening on port 5467.
* When someone requests _yourip:5467/payload_, the build system will start. **Beware:** there isn't any kind of control, you're responsible of securing and rate-limiting your server, if you need it.
* The build system checks out the latest changes from your repository.
* If your repository has packages that have to be installed or any kind of similar prebuild step, the function `packages_install` will launch if there are changes in that directory. 
* The build system compiles every `.tex` file in second level folders with `latexmk` (that is, _repo/doc/man.tex_ will be built, but not _repo/first.tex_ nor _repo/doc/aux/aux.tex_). Options for compilation are available in the script `pullandbuild.sh`.
* Whenever a PDF file is updated, it will be uploaded to the folders you specify in the `dbupload.rb` script.
