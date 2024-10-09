#!/bin/bash

#This script updates Xray geodata files. Actually you can specify any files you like, not only geodata.
#Each entry in the URLS array must correspond to an entry in the FILES array.
#Each file is downloaded, checked for differencies and replaced only if it actually differ from already present one.
#To avoid Xray potential crash it is stopped before files replacement and started again afterwards. If there are no files to update Xray service isn't interrupted.

#To invoke this script periodically (using Cron) do the following:
#   1. Put this file into /usr/bin/xray-geodata-update.sh
#   2. Make script executable: chmod +x /usr/bin/xray-geodata-update.sh
#   3. Open the crontab editor: crontab -e
#   4. Add a weekly cron job (every Wednesday at 5:00 AM): 0 5 * * 3 /usr/bin/xray-geodata-update.sh

#To view the log use: logread | grep xray-geodata-update

# Parameters
FILE_SIZE_MIN=10240     #Minimum size (in bytes) for a file to be considered valid
LOG_ENABLE=true         #Set to false to disable logging

# Files to update (URLs and filess path)
URLS=(
    "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
    "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
    "https://github.com/1andrevich/Re-filter-lists/releases/latest/download/geoip.dat"
    "https://github.com/1andrevich/Re-filter-lists/releases/latest/download/geosite.dat"
)
FILES=(
    "/usr/share/xray/geoip.dat"
    "/usr/share/xray/geosite.dat"
    "/usr/share/xray/geoip-ru.dat"
    "/usr/share/xray/geosite-ru.dat"
)

# Function to log messages
log_message() {
    local message="$1"
    if [ $LOG_ENABLE = true ]; then
        logger -t xray-geodata-update "$message"
        #echo "$(date +"%Y-%m-%d @ %H:%M:%S") $message"
    fi
}

# Check if Xray service is running
xray_check() {
    service xray status > /dev/null 2>&1
    return $?
}

# Signal the start of the update process
log_message "Starting update process."

# Create an array to store the files that were successfully downloaded and changed
UPDATES=()

# Loop over the URLs and paths, download files to temporary locations
for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILE="${FILES[$i]}"
    TEMP="${FILE}.tmp"

    # Download each file to a temporary location
    curl -sSL -o "$TEMP" "$URL"

    # If the download was successful, check it and compare with the current file
    if [ $? -eq 0 ]; then
        # File consistency check (by minimum size)
        FILE_SIZE=$(wc -c < "$TEMP")
        if [ "$FILE_SIZE" -lt "$FILE_SIZE_MIN" ]; then
            log_message "$FILE: downloaded file seems to be invalid ($FILE_SIZE < FILE_SIZE_MIN bytes), skipping update."
            rm -f "$TEMP"
            continue
        fi

        # File comparison
        if cmp -s "$TEMP" "$FILE"; then
            log_message "$FILE: no differencies, skipping update."
            rm -f "$TEMP"
        else
            # Add the file to the list of files to update
            UPDATES+=("$FILE")
            log_message "$FILE: differencies found, adding to the update list."
        fi
    else
        log_message "$FILE: failed to download $URL"
        rm -f "$TEMP"
    fi
done

# If any files have changed, stop Xray and update those files
if [ ${#UPDATES[@]} -gt 0 ]; then
    # Save Xray current state
    if xray_check; then
        XRAY_ISRUNNING=true
        log_message "Xray is currently running. Stopping it to safely update files."
        service xray stop
    else
        XRAY_ISRUNNING=false
        log_message "Xray is not running. Proceeding with update."
    fi

    # Move updated files in place
    for FILE in "${UPDATES[@]}"; do
        TEMP="${FILE}.tmp"
        mv "$TEMP" "$FILE"
        log_message "$FILE: updated successfully."
    done

    # Restore Xray to its previous state
    if [ "$XRAY_ISRUNNING" = true ]; then
        log_message "Starting Xray after files being updated."
        service xray start
    fi
else
    log_message "No files to update."
fi
