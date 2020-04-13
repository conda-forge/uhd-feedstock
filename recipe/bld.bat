setlocal EnableDelayedExpansion

:: Python assumes an old Visual Studio without snprintf, but this breaks
:: compiling the Python bindings. Need to define HAVE_SNPRINTF to fix.
:: https://github.com/boostorg/system/issues/32#issuecomment-462912013
set "CXXFLAGS=%CXXFLAGS% -DHAVE_SNPRINTF"

:: Make a build folder and change to it
cd host
mkdir build
cd build

:: configure
:: enable uhd components explicitly so we get build error when unsatisfied
:: the following are disabled:
::   DOXYGEN/MANUAL because we don't need docs in the conda package
::   DPDK needs dpdk
::   LIBERIO needs liberio
::   MAN_PAGES because they can't be enabled for Windows
cmake -G "NMake Makefiles JOM" ^
    -DCMAKE_INSTALL_PREFIX:PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_BUILD_TYPE:STRING=Release ^
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP:BOOL=ON ^
    -DBOOST_ALL_DYN_LINK:BOOL=ON ^
    -DBoost_NO_BOOST_CMAKE=ON ^
    -DLIBUSB_INCLUDE_DIRS:PATH="%LIBRARY_INC%\libusb-1.0" ^
    -DPYTHON_EXECUTABLE:PATH="%PYTHON%" ^
    -DUHD_PYTHON_DIR:PATH="%PREFIX%\Lib\site-packages" ^
    -DUHD_RELEASE_MODE:STRING=release ^
    -DENABLE_B100=ON ^
    -DENABLE_B200=ON ^
    -DENABLE_C_API=ON ^
    -DENABLE_DOXYGEN=OFF ^
    -DENABLE_DPDK=OFF ^
    -DENABLE_E300=ON ^
    -DENABLE_E320=ON ^
    -DENABLE_EXAMPLES=ON ^
    -DENABLE_LIBERIO=OFF ^
    -DENABLE_LIBUHD=ON ^
    -DENABLE_MAN_PAGES=OFF ^
    -DENABLE_MANUAL=OFF ^
    -DENABLE_MPMD=ON ^
    -DENABLE_OCTOCLOCK=ON ^
    -DENABLE_N230=ON ^
    -DENABLE_N300=ON ^
    -DENABLE_N320=ON ^
    -DENABLE_PYTHON_API=ON ^
    -DENABLE_RFNOC=ON ^
    -DENABLE_TESTS=ON ^
    -DENABLE_UTILS=ON ^
    -DENABLE_USB=ON ^
    -DENABLE_USRP1=ON ^
    -DENABLE_USRP2=ON ^
    -DENABLE_X300=ON ^
    ..
if errorlevel 1 exit 1

:: build
cmake --build . --config Release -- -j%CPU_COUNT%
if errorlevel 1 exit 1

:: test
set PATH=%SRC_DIR%\host\build\lib;%PATH%
ctest --output-on-failure
if errorlevel 1 exit 1

:: install
cmake --build . --config Release --target install
if errorlevel 1 exit 1
