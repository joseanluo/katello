#!/bin/bash

function usage() {
  cat <<EOF
Script for generating fake repositories from definition files

Arguments:
  -i  - pulp_id of the repo, if not specified, random value will be used and
        the repo will be deleted at the end
  -d  - path to the directory with repo definition
  -o  - path to the output directory
  -p  - path to the directory with packages (if don't want to have them generated by the script)
EOF
}

while getopts "i:d:p:o:" opt; do
    case "$opt" in
        i)  repo_id=$OPTARG ;;
        d)  dir=$OPTARG ;;
        o)  out_dir=$OPTARG ;;
        p)  packages_dir=$OPTARG ;;
        ?)  usage
            exit 1;;
    esac
done

if [ -z "$dir" ] || [ -z "$out_dir" ]; then
   usage
   exit 1
fi

if [ -z "$repo_id" ]; then
    random_repo=1
    repo_id=create_repo_$RANDOM
fi

pulp_repo_dir=/var/lib/pulp/repos/$repo_id

if ! [ -e $out_dir ]; then
    mkdir $out_dir
fi

if ! [ -d $out_dir ]; then
    echo "$out_dir is not a directory"
    exit 2
fi

if [ -e $pulp_repo_dir ]; then
    echo "We are sorry, $pulp_repo_dir already exists, try again"
    exit 2
fi

#create the repository
pulp-admin auth login --username admin --password $(grep '^default_password' /etc/pulp/pulp.conf | awk '{print $2}')
pulp-admin repo create --id $repo_id

if [ -z "$packages_dir" ]; then
  packages_dir=$dir/packages
  mkdir $packages_dir

  #batch build packages
  ./batch_create_dummy_packages.sh $dir/packagelist.txt $packages_dir
  ./sign_dummy_package.sh $packages_dir/*/*.rpm
fi

pulp-admin content upload -r $repo_id --nosig -v $packages_dir/RPMS/*.rpm

#create groups and categories
./create_repogroups.sh $repo_id $dir/grouplist.txt

#create errata
./batch_create_errata.sh $repo_id $dir/errata.txt $packages_dir/RPMS/

#TODO: upload additional files


pulp-admin repo generate_metadata --id $repo_id

cp -r $pulp_repo_dir $out_dir/RPMS
cp -r $packages_dir/SRPMS $out_dir/SRPMS

if [ -e "$dir/packages" ]; then
  rm -r $dir/packages
fi

if [ "$random_repo" = "1" ]; then
    pulp-admin repo delete --id $repo_id
fi
