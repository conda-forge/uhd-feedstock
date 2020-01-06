setlocal EnableDelayedExpansion

:: download and install binary images
python "%PREFIX%\Library\lib\uhd\utils\uhd_images_downloader.py" -y -q
