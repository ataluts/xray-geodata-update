## Overview

This script updates Xray geodata files. Actually you can specify any files you like, not only geodata.  
Each file is downloaded, checked for validity *(by minimum size)* and differencies and replaced only if it is considered valid and actually differ from already present one. To avoid Xray potential crash it is stopped before files replacement and started again afterwards. If there are no files to update Xray service isn't interrupted.

It is intended to be used on OpenWRT so Xray service control commands are specified accordingly (`service xray start|stop|status` instead of `systemctl start|stop|status xray`)

## Parameters

- `URLS`: Array containing the URLs of the geodata files you want to download. Each URL must correspond to a file in the `FILES` array, meaning the first URL in `URLS` will download to the first file path in `FILES`, and so on.
- `FILE_SIZE_MIN`: Minimum file size *(in bytes)* for a file to be considered valid.
- `LOG_ENABLE`: Set to `true` to enable logging; set to `false` to disable.

## Regular updates

Use Cron to execute the script regularly.

- Open crontab editor:      `crontab -e`.  
- Add a weekly cron job *(for example every Wednesday at 5:00 AM)*: `0 5 * * 3 /usr/bin/xray-geodata-update.sh`.
