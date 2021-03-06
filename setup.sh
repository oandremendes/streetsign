#!/bin/bash
# setup.sh - useful script for getting a virtualenv etc all set up.
#
####################################################
# Config:

# You shouldn't have to change this, but if you need to force a specific
# version (2.7, say) this can be helpful.
PYTHON_VERSION=python

VDIR=.virtualenv
SDIR=.setup
PYTHON=$VDIR/bin/$PYTHON_VERSION
PIP=$VDIR/bin/pip

# You shouldn't need to change these...
VIRTUALENV_VERSION=1.9.1

VIRTUALENV="$VDIR/virtualenv-$VIRTUALENV_VERSION/virtualenv.py"

####################################################
# Actually start doing stuff:

# with clean command, remove old virtualenv
if [[ "$1" == "clean" ]]; then
    echo "Removing Old VirtualEnv"
    rm -rf "$VDIR"
    # if "./setup.sh clean only", quit after cleaning.
    [[ "$2" == "only" ]] && exit 0
fi

# if the .virtualenv folder doesn't exist, make it
if [[ ! -d "$VDIR" ]]; then
    echo "Making new folder ($VDIR) for virtualenv to live in."
    mkdir "$VDIR"
fi

# extract virtualenv.py if we need it
if [[ ! -f "$VIRTUALENV" ]]; then
    PACKAGE="virtualenv-1.9.1.tar.gz"
    echo "Downloading VirtualEnv ($VIRTUALENV_VERSION)"
    curl "https://pypi.python.org/packages/source/v/virtualenv/$PACKAGE" -o "$VDIR/$PACKAGE"
    if [[ $? -ne 0 ]]; then
        echo 'Download Failed!'
        exit 1
    fi
    echo "Extracting VirtualEnv..."
    tar -zxC "$VDIR" -f "$VDIR/$PACKAGE"
fi

# if there's no python in virtualenv, make one:
[[ -f "$PYTHON" ]] || $PYTHON_VERSION "$VIRTUALENV" "$VDIR"

# get required python modules:
echo "Checking requirements (python modules)"
$PIP install -U pip
$PIP install -r "requirements.txt"
if [[ $? -ne 0 ]]; then
    echo 'Something went wrong trying to install the required python modules...'
    exit 2
fi

# If no config.py, auto generate one:
if [[ ! -f 'config.py' ]]; then
    $PYTHON_VERSION .setup/make_initial_config_file.py > 'config.py'
fi

# setup standard hooks.
if [[ ! -e ".git/hooks/pre-commit" ]]; then
    cp .setup/hooks/pre-commit .git/hooks/pre-commit
fi

if [[ ! -f "database.db" ]]; then
    echo "no database, so I'll make a default one"
    $PYTHON -c "import db;db.make()"

    echo "the main user is 'admin' and the password is 'password'."
    echo "please change it!"
fi

mkdir -p streetsign_server/static/user_files/fonts

echo
echo "--------------------------------------------------------"
echo "Everything is done! You should be able to use ./run.py to run the development server."
