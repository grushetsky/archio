# General Description

__archio__ is a small bash utility that gets the certain version of __KioSPHERE__ and wraps it into a package that consists of a set of archives that can be transmitted for further distribution, maintenance or storage. The archives contain both sources and binaries of the product. The sources are fetched from Git repository, while the binaries of built components are downloaded from Bamboo server.

## Requirements

__archio__ is being developed and tested under Linux. As __archio__ is basically a bash script, the quite common set of dependencies make it possible to run the program on many platforms. Make sure the following components are installed in your environment:

  * GNU bash
  * Zip
  * GNU Wget

## Options

The list of available script parameters is the following (required parameters are italicized):

  * _-pv_, _--product-version=VER_
  Indicate version of KioSPHERE that will be packed into archives. Defaults to version 1.5.9.

  * _-b_,  _--build-number=NUM_
  Specify the Bamboo build number for indicated version. Defaults to 0.

  * _-u_,  _--user-name=NAME_
  User name of your Bamboo account.

  * _-p_,  _--password=PASS_
  Password of your Bamboo account.

  * -ca, --combined-archive
  Produce another archive that includes both sources and binaries.

  * -cu, --clean-up
  Remove 'bin' and 'src' folders that were created during the archives composition.

  * -d,  --destination=PATH
  The path where the dir with the output archives will be created. Defaults to current dir.

  * -cl, --compression-level=NUM
  Define the level of archive compression, a value between 0 and 9. 9 is the highest level. Defaults to 9.

  * -v,  --version
  Show  version.

  * -h,  --help
  Show current help section.

## Examples

Produce the package with KioSPHERE 1.5.9 build 15 and remove fetched source files:

    archio -pv=1.5.9 -b=15 -u=me -p='my-favorite-complex-pass!&^*$$$' -cu

Produce the package with KioSPHERE 1.5.9 build 14 that among other files includes a single archive with both binary and source archives, while all of the archives aren't compressed:

    archio -pv=1.5.9 -b=14 -u=you -p='anotherpass' -ca -cl=0
