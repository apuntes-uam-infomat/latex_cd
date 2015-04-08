# Continuous compilation and deployment of LaTeX files

This is a small set of scripts to enable continuous compilation and deployment of LaTeX files in a GitHub repository. This is what this thing does:

* Start a Ruby/Sinatra server listening on port 5467.
* When someone requests _yourip:5467/payload_, the build system will start. **Beware:** there isn't any kind of control, you're responsible of securing and rate-limiting your server, if you need it.
* The build system checks out the latest changes from your repository.
* If your repository has packages that have to be installed or any kind of similar prebuild step, the function `packages_install` will launch if there are changes in that directory.
* The build system compiles every `.tex` file in second level folders with `latexmk` (that is, _repo/doc/man.tex_ will be built, but not _repo/first.tex_ nor _repo/doc/aux/aux.tex_). Options for compilation are available in the script `pullandbuild.sh`.
* Whenever a PDF file is updated, it will be uploaded to the folders you specify in the `dbupload.rb` script (but first you have to get an access token from Dropbox and save it in the _dbtoken_ file, see [dropbox-sdk](https://github.com/dropbox/dropbox-sdk-ruby) gem for details on how to do it).
* If [GHI](https://github.com/stephencelis/ghi) is present and configured, the script will report build failures and conflict markers sending an issue to the Github repository.

## Requirements & installation

`latex_cd` requires a working Ruby installation for the Sinatra server and for the Dropbox uploader. Ruby installations are tricky if you want to do it the right way, so here're some guidelines to install Ruby and latex_cd as a service in your system (Debian based).

1. Install RVM system-wide. [Follow instructions in the RVM site, see multi-user install](https://rvm.io/rvm/install#installation), but basically you should execute `curl -sSL https://get.rvm.io | sudo bash -s stable`.
2. Add yourself to the _rvm_ group for testing: `sudo usermod -a -G rvm $USER`. Log out and log in again to load the environment variables.
3. Get the Ruby executable with `rvmsudo rvm install 2.2.1`.
4. Create the _latexcd_ user: `sudo useradd -m latexcd`.
5. Add the _latexcd_ user to the _rvm_ group: `sudo usermod -a -G rvm latexcd`.
6. Execute the install script with `sudo ./install`. It will install the application to your chosen prefix (see _latexcd.conf_ file) and install all necessary dependencies.
7. Run the service with `sudo service latexcd start`.
8. Execute _latexcd_ at boot with `sudo update-rc.d latexcd defaults`.
9. (Optional for issue reporting) Configure [GHI](https://github.com/stephencelis/ghi) in the repo (_/opt/latexcd/latex\_cd/repo_). Remember to prefix the executions with `rvm 2.2.1 do ghi ..." to avoid possible problems.

