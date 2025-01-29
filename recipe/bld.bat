setlocal EnableExtensions EnableDelayedExpansion
@echo on

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
::   MAN_PAGES because they can't be enabled for Windows
set ^"CMAKE_OPTIONS=^
 -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
 -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
 -DCMAKE_BUILD_TYPE=Release ^
 -DBOOST_ALL_DYN_LINK=ON ^
 -DBoost_NO_BOOST_CMAKE=ON ^
 -DPYTHON_EXECUTABLE="%PYTHON%" ^
 -DRUNTIME_PYTHON_EXECUTABLE="%PYTHON%" ^
 -DUHD_PYTHON_DIR="%SP_DIR%" ^
 -DUHD_RELEASE_MODE=release ^
 -DENABLE_B100=ON ^
 -DENABLE_B200=ON ^
 -DENABLE_C_API=ON ^
 -DENABLE_DOXYGEN=OFF ^
 -DENABLE_DPDK=OFF ^
 -DENABLE_E300=ON ^
 -DENABLE_E320=ON ^
 -DENABLE_EXAMPLES=ON ^
 -DENABLE_LIBUHD=ON ^
 -DENABLE_MAN_PAGES=OFF ^
 -DENABLE_MANUAL=OFF ^
 -DENABLE_MPMD=ON ^
 -DENABLE_OCTOCLOCK=ON ^
 -DENABLE_N300=ON ^
 -DENABLE_N320=ON ^
 -DENABLE_PYTHON_API=ON ^
 -DENABLE_TESTS=OFF ^
 -DENABLE_UTILS=ON ^
 -DENABLE_USB=ON ^
 -DENABLE_USRP1=ON ^
 -DENABLE_USRP2=ON ^
 -DENABLE_WHEEL_BUILD_DEFAULT=OFF ^
 -DENABLE_X300=ON ^
 -DENABLE_X400=ON ^
 ^"

if [%python_impl%] == [pypy] (
  set ^"CMAKE_OPTIONS=!CMAKE_OPTIONS! ^
    -DENABLE_SIM=OFF ^
    ^"
) else (
  set ^"CMAKE_OPTIONS=!CMAKE_OPTIONS! ^
    -DENABLE_SIM=OFF ^
    ^"
)

cmake -G "Ninja" !CMAKE_OPTIONS! ..
if errorlevel 1 exit 1

:: build
cmake --build . --config Release -- -j%CPU_COUNT%
if errorlevel 1 exit 1

:: install
cmake --build . --config Release --target install
if errorlevel 1 exit 1

:: delete dd.exe which gets downloaded and included in release mode
cmake -E rm -f "%LIBRARY_LIB%\uhd\utils\dd.exe"
if errorlevel 1 exit 1

:: copy scripts into uhd package so we can make an entry_point
cmake -E copy "utils\rfnoc_image_builder" "%SP_DIR%\uhd\rfnoc_image_builder.py"
if errorlevel 1 exit 1
cmake -E copy -t "utils\uhd_images_downloader.py" "%SP_DIR%\uhd"
if errorlevel 1 exit 1
cmake -E copy "utils\usrpctl" "%SP_DIR%\uhd\usrpctl_script.py"
if errorlevel 1 exit 1
