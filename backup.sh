#!/bin/sh
IFBACKUP='ifBackup';
CONFDIR='/etc/ifBackup';
CONFFILE='ifBackup.conf';

if [[ ! -f $CONFDIR/$CONFFILE ]]; then
    exit
else
    source $CONFDIR/$CONFFILE;
fi

CONFSITES="$CONFDIR/$IF_OPTCONF";
CURRENTDAY=$(date +%Y-%m-%d);
BACKUPDEST=$IF_BACKUP_DIR/$CURRENTDAY;
TMPDIR=$IF_TMP_DIR/$IFBACKUP;

# OPTIONS INIT
if [[ -n $IF_OPTIONS ]]; then
    OPTIONS="-$IF_OPTIONS";
fi

# STATS INIT
if [[ $IF_STATS == 1 ]]; then
    STATS="--stats";
fi

# INCREMENTAL DIRS INIT
LASTDIR=$(ls -r $IF_BACKUP_DIR/$LASTDIR |head -1);
if [[ -d $IF_BACKUP_DIR/$LASTDIR ]]; then
    LINKDEST="--link-dest=$IF_BACKUP_DIR/$LASTDIR";
fi

mkdir $IF_BACKUP_DIR/$CURRENTDAY;
mkdir $TMPDIR;

function generateScripts {
    for i in `ls $CONFSITES/*.conf`; do
        if [[ -f $i ]]; then
            source $i;
            SCRIPTNAME=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10;echo);
            SCRIPTLOCATION=$TMPDIR/$SCRIPTNAME;
            for CURRENTPATH in ${BACKUP_DIRS[@]}; do
                if [[ -n $TOBACKUP ]]; then
                    PREVLINE="$TOBACKUP;";
                fi
                TOBACKUP="$PREVLINE rsync $OPTIONS $STATS $LINKDEST $MOUNT_POINT/$CURRENTPATH $BACKUPDEST/$BACKUP_NAME";
            done
            cat <<EOS >> $SCRIPTLOCATION
mount $MOUNT_POINT && $TOBACKUP  || echo fail;
umount $MOUNT_POINT;
EOS
            chmod +x $SCRIPTLOCATION;
            SCREENS=("${SCREENS[@]}" "screen -dmS $BACKUP_NAME-$CURRENTDAY $SCRIPTLOCATION;");
            #CLEAN VARS
            unset SCRIPTNAME;
            unset BACKUP_NAME;
            unset MOUNT_POINT;
            unset BACKUP_DIRS;
            unset PREVLINE;
            unset TOBACKUP;
        fi
    done
}

generateScripts;

for TOEXEC in "${SCREENS[@]}"; do
    $TOEXEC;
    #sleep 1;
done;
