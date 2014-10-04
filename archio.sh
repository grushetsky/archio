#!/bin/bash

# Package info
package_name="archio"
package_version="0.1"
package_author="Toxic"

# Select one of the input values based on version number
# In case the version is less than 1.6.x the first parameter is echoed, otherwise, the second one.
# $1 - first value
# $2 - second value
function select_based_on_version() {
    if [[ "$version" < "1.6" ]]; then
        echo "$1"
    else
        echo "$2"
    fi
}

# Remove trailing characters from downloaded artifacts
function normalize_artifacts() {
    for file in *.*\?*; do
        mv "$file" "${file%%\?*}";
    done
}

# Clone Git repository if it doesn't exist
function clone_repo() {
    if [ ! -d "$1/.git" ]; then
        if [ -d "$1" ]; then
            rm -r $1
        fi
        git clone git@github.com:IQEX/$1.git
    fi
}

# Check if parameter is empty echoing error text in case it is
function check_if_null() {
    if [ -z $1 ]; then
        echo "$2 can't be null. The execution will terminate."
        exit 0;
    fi
}

# Input parameters processing
version="1.5.9"
build_number="0"
bamboo_user_name=
bamboo_password=
combined_archive_enabled="false"
clean_up_enabled="false"
destination=$PWD
file_compression_level=9

for key in "$@"; do
    case "$key" in
        -h|--help)
            echo "$package_name - prepares KioSPHERE binary and source archives for certain product version"
            echo " "
            echo "Usage: $package_name [options]"
            echo " "
            echo "[options]:"
            echo "  -pv, --product-version=VER     Indicate version of KioSPHERE that will be packed into archives. Defaults to version 1.5.9."
            echo "  -b,  --build-number=NUM        Specify the Bamboo build number for indicated version. Defaults to 0."
            echo "  -u,  --user-name=NAME          User name of your Bamboo account."
            echo "  -p,  --password=PASS           Password of your Bamboo account."
            echo "  -ca, --combined-archive        Produce another archive that includes both sources and binaries."
            echo "  -cu, --clean-up                Remove 'bin' and 'src' folders that were created during the archives composition."
            echo "  -d,  --destination=PATH        The path where the dir with the output archives will be created. Defaults to current dir."
            echo "  -cl, --compression-level=NUM   Define the level of archive compression, a value between 0 and 9. 9 is the highest level. Defaults to 9."
            echo "  -v,  --version                 Show $product_name version."
            echo "  -h,  --help                    Show current help section."
            echo " "
            exit 0
        ;;
        -v|--version)
            echo "{{ $package_name $package_version }} package, brought you by $package_author."
            exit 0
        ;;
        -pv=*|--product-version=*)
            version="${key#*=}"
            regex="^[1-9]{1,2}\.[0-9]{1}\.[0-9]{1}$"
            if [[ ! $version =~ $regex ]]; then
                echo "Product version '$version' format is wrong. Example of well-formatted product version: '1.5.8'."
                exit 0;
            fi
        shift
        ;;
        -b=*|--build-number=*)
            build_number="${key#*=}"
            regex="^[0-9]+$"
            if [[ ! $build_number =~ $regex ]]; then
                echo "Build number '$build_number' format is wrong. Example of well-formatted build number: '56'."
                exit 0;
            fi
        shift
        ;;
        -u=*|--user-name=*)
            bamboo_user_name="${key#*=}"
        shift
        ;;
        -p=*|--password=*)
            bamboo_password="${key#*=}"
        shift
        ;;
        -ca|--combined-archive)
            combined_archive_enabled="true"
        shift
        ;;
        -cu|--clean-up)
            clean_up_enabled="true"
        shift
        ;;
        -d=*|--destination=*)
            destination="${key#*=}"
            check_if_null "$destination" 'Destination path'
        shift
        ;;
        -cl=*|--compression-level=*)
            file_compression_level="${key#*=}"
            regex="[0-9]{1}"
            if [[ ! $file_compression_level =~ $regex ]]; then
                echo "Archive compression level '$file_compression_level' format is wrong. Example of well-formatted compression level: '2'."
                exit 0;
            fi
        shift
        ;;
        *)
            echo "Unknown option '$key' detected. The execution will terminate."
            exit 0;
        ;;
    esac
done

# Check if obligatory input params are empty
check_if_null "$bamboo_user_name" 'Bamboo user name'
check_if_null "$bamboo_password" 'Bamboo password'

# Output settings
product_name="kiosphere"
output_folder_name="$product_name-$version-$build_number"
destination="$destination/$output_folder_name"
archive_format="zip"
exclude_instructions="--exclude=*.git* --exclude=.DS_Store --exclude=.Spotlight-V100 --exclude=.Trashes --exclude=[Tt]humbs.db --exclude=desktop.ini"
archive_name_src="$product_name-$version-$build_number-src"
archive_name_bin="$product_name-$version-$build_number-bin"
combined_archive_name="$product_name-$version-$build_number-combined"

# Git settings
client_branch=$(select_based_on_version "v1.5" "master")
server_branch="master"
card_lib_branch="master"
client_repo="vv-client"
server_repo="vv-root"
card_lib_repo="uec-ax-lib"

# Bamboo settings
bamboo_project_id="IQF"
bamboo_plan_id=$(select_based_on_version "MASTER" "AWEMAS")
bamboo_artifacts_url="http://itsphere.atlassian.net/builds/browse/$bamboo_project_id-$bamboo_plan_id-$build_number/artifact"
bamboo_client_components_paths=( "UNPACK/KioSphereDefaultInstaller/kiosphere_$version.$build_number.exe"
                                 "BSDK/KioSphereSberbankInstaller/kiosphere_sberbank_$version.$build_number.exe"
                                 "shared/Support/ITSphereSupport.rar"
                                 "shared/PhoneService/ITSPhoneService.rar"
                                 "shared/VoIP/ITSVoIP.rar"
                                 "shared/Scanner/ITSScanner.rar"
                                 "$(select_based_on_version "shared/WebFront/WebFront.rar" "shared/kiobrowser/kiobrowser.rar")"
                                 "shared/Monitor/ITSMonitor.rar"
                                 "shared/Proxy/ITSLocalProxy.rar" )
bamboo_server_components_paths=( "WEBSERVICE/WscSupport/$bamboo_project_id-$bamboo_plan_id-WEBSERVICE-WscSupport-build-$build_number.rar"
                                 "WEBSERVICE/Database/$bamboo_project_id-$bamboo_plan_id-WEBSERVICE-Database-build-$build_number.rar"
                                 "WEBSERVICE/Identity-Provider/$bamboo_project_id-$bamboo_plan_id-WEBSERVICE-IdentityProvider-build-$build_number.rar"
                                 "WEBSERVICE/WebAdmin/$bamboo_project_id-$bamboo_plan_id-WEBSERVICE-WebAdmin-build-$build_number.rar"
                                 "WEBSERVICE/WebShowcase/$bamboo_project_id-$bamboo_plan_id-WEBSERVICE-WebShowcase-build-$build_number.rar" )
bamboo_card_lib_components_paths=( "shared/AxUEC/UecLibBin.rar"
                                   "shared/TermUtils/TermUtils.rar" )

# Create folders
mkdir -p $destination/bin/ $destination/src/
mkdir -p $destination/bin/$client_repo
mkdir -p $destination/bin/$server_repo
mkdir -p $destination/bin/$card_lib_repo

# Clone repos
cd $destination/src/
clone_repo "$client_repo"
clone_repo "$server_repo"
clone_repo "$card_lib_repo"

# Switch 'vv-client' to corresponding branch
cd $destination/src/$client_repo/
git checkout -B $client_branch origin/$client_branch
git reset --hard HEAD

# Switch 'vv-root' to corresponding branch
cd $destination/src/$server_repo/
git checkout -B $server_branch origin/$server_branch
git reset --hard HEAD

# Switch 'uec-ax-lib' to corresponding branch
cd $destination/src/$card_lib_repo/
git checkout -B $card_lib_branch origin/$card_lib_branch
git reset --hard HEAD

# Archive sources
cd $destination/
zip -$file_compression_level -r $exclude_instructions $archive_name_src.$archive_format ./src

# Download 'vv-client' binaries
cd $destination/bin/$client_repo/
for component_path in ${bamboo_client_components_paths[@]}; do
    wget --no-verbose --http-user=$bamboo_user_name --http-password=$bamboo_password "$bamboo_artifacts_url/$component_path?os_authType=basic"
done
normalize_artifacts

# Download 'vv-root' binaries
cd $destination/bin/$server_repo/
for component_path in ${bamboo_server_components_paths[@]}; do
    wget --no-verbose --http-user=$bamboo_user_name --http-password=$bamboo_password "$bamboo_artifacts_url/$component_path?os_authType=basic"
done
normalize_artifacts

# Download 'uec-ax-lib' binaries
cd $destination/bin/$card_lib_repo/
for component_path in ${bamboo_card_lib_components_paths[@]}; do
    wget --no-verbose --http-user=$bamboo_user_name --http-password=$bamboo_password "$bamboo_artifacts_url/$component_path?os_authType=basic"
done
normalize_artifacts

# Archive binaries
cd $destination/
zip -$file_compression_level -r $exclude_instructions $archive_name_bin.$archive_format ./bin

# Archive sources and binaries together
if [ $combined_archive_enabled == "true" ]; then
    cd $destination/
    zip -$file_compression_level -r $exclude_instructions $combined_archive_name.$archive_format ./$archive_name_bin.$archive_format ./$archive_name_src.$archive_format
fi

# Remove 'bin' and 'src' folders
if [ $clean_up_enabled == "true" ]; then
    cd $destination/
    rm -rf ./bin ./src
fi
