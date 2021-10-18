#!/bin/env bash

AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
DB_HOST=$(aws ssm get-parameters --region ${AWS_REGION} --names DB_HOST     --query Parameters[0].Value | sed -e 's/^"//' -e 's/"$//')
DB_NAME=$(aws ssm get-parameters --region ${AWS_REGION} --names DB_NAME --query Parameters[0].Value | sed -e 's/^"//' -e 's/"$//')
DB_USER=$(aws ssm get-parameters --region ${AWS_REGION} --names DB_USER --query Parameters[0].Value | sed -e 's/^"//' -e 's/"$//')
DB_PASS=$(aws ssm get-parameters --region ${AWS_REGION} --names DB_PASS --query Parameters[0].Value --with-decryption | sed -e 's/^"//' -e 's/"$//')

_YEAR=`date "+%Y"`
_MONTH=`date "+%m"`
_DAY=`date "+%d"`
_DATE=`date "+%Y%m%dT%H%M%S"` # YYY-MM-DDT
_PATH_BASE="sqlfiles"
_PATH_FULL="${_PATH_BASE}/${_YEAR}/${_MONTH}/${_DAY}/${_DATE}"
_SET_BYTABLE=true

# Create the folder for current
if [ ! -d ${_PATH_FULL} ]; then
   mkdir -p ${_PATH_FULL} || exit 1
fi

# Create a temporary my.cnf
# Don't forget to delete it, especially if script fails somewhere

_TMPF=`mktemp`
echo "[client]"            >> $_TMPF
echo "host=${DB_HOST}"     >> $_TMPF
echo "user=${DB_USER}"     >> $_TMPF
echo "password=${DB_PASS}" >> $_TMPF
#echo "database=${DB_NAME}"     >> $_TMPF

# find ${_PATH_BASE} -type d -mtime +60 -exec rm -rf {} \;

for database in `mysql --defaults-extra-file=${_TMPF} -sN -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'performance_schema', 'sys')"`; do
    backupfile="${_PATH_FULL}/${_DATE}_${database}.sql.gz"
    echo "Backing up database ${database}"
    if [ ! ${_SET_BYTABLE} = true ]; then
        mysqldump --defaults-extra-file=${_TMPF} --single-transaction --quick --lock-tables=false --no-tablespaces ${database} | gzip -9 -c > $backupfile
    else
        for table in `mysql --defaults-extra-file=${_TMPF} -sN -e "SHOW TABLES;" ${database}` ; do
            backupfile="${_PATH_FULL}/${_DATE}_${database}_${table}.sql.gz"
            echo "Backing up table ${database}/${table}"
            mysqldump --defaults-extra-file=${_TMPF} --single-transaction --quick --lock-tables=false --no-tablespaces ${database} ${table} | gzip -9 -c > $backupfile
        done;
    fi
done

#   do /usr/local/bin/mysqldump $i > $PATH/$DATE-$i 

rm -f ${_TMPF} && echo "Temporary ${_TMPF} file deleted."
echo "Backup successfully completed and saved in ${_PATH_FULL}"
