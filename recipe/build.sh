#!/bin/bash

set -ex

cd host  # needed for builds from github tarball
mkdir build
cd build

# enable uhd components explicitly so we get build error when unsatisfied
# the following are disabled:
#   DOXYGEN/MANUAL because we don't need docs in the conda package
#   DPDK needs dpdk
#   E300 build fails on CI
cmake_config_args=(
    -DBOOST_ROOT=$PREFIX
    -DBoost_NO_BOOST_CMAKE=ON
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_FIND_LIBRARY_CUSTOM_LIB_SUFFIX=$ARCH
    -DCMAKE_INSTALL_PREFIX=$PREFIX
    -DCURSES_NEED_NCURSES=ON
    -DLIB_SUFFIX=""
    -DPYTHON_EXECUTABLE=$PYTHON
    -DRUNTIME_PYTHON_EXECUTABLE=$PYTHON
    -DUHD_RELEASE_MODE=release
    -DENABLE_B100=ON
    -DENABLE_B200=ON
    -DENABLE_C_API=ON
    -DENABLE_DOXYGEN=OFF
    -DENABLE_DPDK=OFF
    -DENABLE_E300=OFF
    -DENABLE_E320=ON
    -DENABLE_EXAMPLES=ON
    -DENABLE_LIBUHD=ON
    -DENABLE_MAN_PAGES=ON
    -DENABLE_MANUAL=OFF
    -DENABLE_MPMD=ON
    -DENABLE_OCTOCLOCK=ON
    -DENABLE_N300=ON
    -DENABLE_N320=ON
    -DENABLE_PYTHON_API=ON
    -DENABLE_SIM=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_UTILS=ON
    -DENABLE_USB=ON
    -DENABLE_USRP1=ON
    -DENABLE_USRP2=ON
    -DENABLE_X300=ON
    -DENABLE_X400=ON
)

if [[ $target_platform == osx* ]] ; then
    # the RPATH variables are forced to values that we don't want for a conda
    # package unless we specify them, so force them to the CMake defaults
    cmake_config_args+=(
        -DCMAKE_INSTALL_NAME_DIR="@rpath"
        -DCMAKE_INSTALL_RPATH=""
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF
        -DCMAKE_BUILD_WITH_INSTALL_NAME_DIR=ON
    )
fi

if [[ $python_impl == "pypy" ]] ; then
    # we need to help cmake find pypy
    # (need both PYTHON_ and Python_ style because UHD uses old finder
    #  and pybind11 uses new FindPython module)
    cmake_config_args+=(
        -DPYTHON_LIBRARY=$PREFIX/lib/`$PYTHON -c "import sysconfig; print(sysconfig.get_config_var('LDLIBRARY'))"`
        -DPYTHON_INCLUDE_DIR=`$PYTHON -c "import sysconfig; print(sysconfig.get_paths()['include'])"`
        -DPython_LIBRARY=$PREFIX/lib/`$PYTHON -c "import sysconfig; print(sysconfig.get_config_var('LDLIBRARY'))"`
        -DPython_INCLUDE_DIR=`$PYTHON -c "import sysconfig; print(sysconfig.get_paths()['include'])"`
        -DUHD_PYTHON_DIR=$SP_DIR
    )
fi

cmake ${CMAKE_ARGS} -G "Ninja" .. "${cmake_config_args[@]}"
cmake --build . --config Release -- -j${CPU_COUNT}
cmake --build . --config Release --target install

if [[ $target_platform != linux* ]] ; then
    # copy uhd_images_downloader.py into uhd package so we can make an entry_point
    cp utils/uhd_images_downloader.py $SP_DIR/uhd/uhd_images_downloader_cmd.py
fi
