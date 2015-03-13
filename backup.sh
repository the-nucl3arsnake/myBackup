#!/bin/sh
ifBackup='ifBackup';
confDir='/etc/ifBackup';
confFile='ifBackup.conf';

if [[ ! -f $confDir/$confFile ]]; then
    exit
else
    source $confDir/$confFile;
fi

confSites="$confDir/$if_optconf";
currentDay=$(date +%Y-%m-%d);
backupDest=$if_backup_dir/$currentDay;
tmpDir=$if_tmp_dir/$ifBackup;

# options INIT
if [[ -n $if_options ]]; then
    options="-$if_options";
fi

# stats INIT
if [[ $IF_stats == 1 ]]; then
    stats="--stats";
fi

# INCREMENTAL DIRS INIT
lastDir=$(ls -r $if_backup_dir/$lastDir |head -1);
if [[ -d $if_backup_dir/$lastDir ]]; then
    linkDest="--link-dest=$if_backup_dir/$lastDir";
fi

mkdir $if_backup_dir/$currentDay;
mkdir $tmpDir;

function generateScripts {
    for i in `ls $confSites/*.conf`; do
        if [[ -f $i ]]; then
            source $i;
            scriptName=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10;echo);
            scriptLocation=$tmpDir/$scriptName;
            for currentPath in ${backup_dirs[@]}; do
                if [[ -n $toBackup ]]; then
                    prevLine="$toBackup;";
                fi
                toBackup="$prevLine rsync $options $stats $linkDest $mount_point/$currentPath $backupDest/$backup_name";
            done
            cat <<EOS >> $scriptLocation
mount $mount_point && $toBackup  || echo fail;
umount $mount_point;
EOS
            chmod +x $scriptLocation;
            screens=("${screens[@]}" "screen -dmS $backup_name-$currentDay $scriptLocation;");
            #CLEAN VARS
            unset scriptName;
            unset backup_name;
            unset mount_point;
            unset backup_dirs;
            unset prevLine;
            unset toBackup;
        fi
    done
}

generateScripts;

for toExec in "${screens[@]}"; do
    $toExec;
    #sleep 1;
done;
