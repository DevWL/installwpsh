#!/bin/bash
read -p 'Project name (without special char only letters and numbers no spacesec) press enter for default [testsite]: ' PROJECTNAME
PROJECTNAME=${PROJECTNAME:-"testsite"}

SERVERWWW="/c/laragon/www" # you can replace all occurrences of "~/Sites" with ${SERVERWWW}
PROJECTROOT=$SERVERWWW/$PROJECTNAME

# Setup site folder, replace all $PROJECTNAME with $PROJECTNAME
mkdir ${PROJECTROOT}
cd ${PROJECTROOT}
# cd ..

wget -q -O latest.tar.gz http://wordpress.org/latest.tar.gz #TODO - check lastest ver on local machine and copy it if it is not older then X time
# curl -O http://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz || exit $?
cd ./wordpress || exit $?
cd ${PROJECTROOT}/wordpress # another way

mv * ${PROJECTROOT}
mv .* ${PROJECTROOT}
cd ..
rmdir ./wordpress

#############################################  PLUGIN AND THEME CLEANUP #################################################################################

# whipe out all themes
echo "Type 'y' to remove all themes! or Press enter for default [n]: "
read -p 'Input... : ' WIPETHEMES
WIPETHEMES=${WIPETHEMES:-"n"}

if [ "$WIPETHEMES" = "y" ]
then
    rm -rf ${PROJECTROOT}/wp-content/themes/*
    cp ${PROJECTROOT}/wp-content/plugins/index.php ${PROJECTROOT}/wp-content/themes
else
    rm -rf ${PROJECTROOT}/wp-content/themes/{twentynineteen,twentyseventeen,twentysixteen,twentytwenty,twentytwentyone}
fi

# whipe out all plugins
echo 'Type y  to remove all plugins! Ppress enter for default [n]: '
read -p 'Input... : ' WIPEPLUGINS
WIPEPLUGINS=${WIPEPLUGINS:-"n"}
if [ "$WIPEPLUGINS" = "y" ]
then
    rm -rf ${PROJECTROOT}/wp-content/plugins/*
    cp ${PROJECTROOT}/wp-content/themes/index.php ${PROJECTROOT}/wp-content/plugins
else
    rm -rf ${PROJECTROOT}/wp-content/plugins/{hello.php,akismet}
fi



#############################################  DATABASE MYSQL #################################################################################


# # Setup MySQL Database
# mysql.server start # use on linux
mysql -u root -e "create database ${PROJECTNAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
mysql -u root -e "create user '${PROJECTNAME}'@'localhost' identified by password ''";
mysql -u root -e "GRANT ALL PRIVILEGES ON ${PROJECTNAME}.* TO ${PROJECTNAME}@localhost";
mysql -u root -e "FLUSH PRIVILEGES";



# # Create config file # note I have used .dv instead of laragon default .test local domain extension

WPUSER="Admin"
WPPASS="laragon123"
WPEMAIL="w.liszkiewicz@gmail.com"
DOMAINEXT="dv"
WPURL="https://${PROJECTNAME}.${DOMAINEXT}"

cd ${PROJECTROOT}
wp-cli.phar core config --dbname=$PROJECTNAME --dbuser=$PROJECTNAME
wp-cli.phar core install --url=${WPURL} --title=${PROJECTNAME} --admin_user=${WPUSER} --admin_password=${WPPASS} --admin_email=${WPEMAIL}

##############################################################################################################################################################

# ######################################## create themes LIB ########################################
THEMESLIB=${SERVERWWW}/wp-themes
mkdir ${SERVERWWW}/wp-themes
cd ${THEMESLIB}


wget -q -O stable.zip http://github.com/toddmotto/html5blank/archive/stable.zip # use wget or curl -O
# curl -O http://github.com/toddmotto/html5blank/archive/stable.zip
cp -r /c/users/symfony/downloads/Divi.zip $THEMESLIB

# unzip all files
unzip -qq \*.zip

cp -r ${THEMESLIB}/* ${PROJECTROOT}/wp-content/themes
rm ${PROJECTROOT}/wp-content/themes/*.zip
mv ${PROJECTROOT}/wp-content/themes/html5blank-stable/ ${PROJECTROOT}/wp-content/themes/$PROJECTNAME

# # Install and activate theme and plugins
cd ${PROJECTROOT}
wp-cli.phar theme activate Divi || wp-cli.phar theme activate $PROJECTNAME

# ######################################## create plugin LIB ########################################
cd $SERVERWWW
PLUGINLIB=${SERVERWWW}/wp-plugins
mkdir $PLUGINLIB

cd $PLUGINLIB

#AFC plugin
wget -q -O advanced-custom-fields.zip https://downloads.wordpress.org/plugin/advanced-custom-fields.5.10.2.zip
wget -q -O better-wp-security.zip https://downloads.wordpress.org/plugin/better-wp-security.8.0.2.zip

# cd ${PROJECTROOT}
# wp-cli.phar plugin activate advanced-custom-fields #TODO loop over plugin dir and activate each plugin
cd $PLUGINLIB
for dir in *
do
    dir=${dir%*/}
    ( wp-cli.phar plugin activate "$d" )
done

# # unzip all zip files
unzip -qq \*.zip

cp -r ${PLUGINLIB}/* ${PROJECTROOT}/wp-content/plugins
rm ${PROJECTROOT}/wp-content/plugins/*.zip

###################### ACTIAVTE ALL PLUGINS ########################
array=()
for dir in */
do
    dir=${dir%*/}
    ( echo "$dir" )
    array+=("$dir")
done

echo "${array[@]}"

cd ${PROJECTROOT}
for i in "${array[@]}"
do
   echo "$i -> activating"
   wp-cli.phar plugin activate $i
done

# # wp plugin output login info
cd ${PROJECTROOT}
echo > "_dv_login.txt"
echo '' | tee -a "_dv_login.txt"
echo "------------ DB ------------" | tee -a "_dv_login.txt"
echo "Database: ${PROJECTNAME}" | tee -a "_dv_login.txt"
echo "DB User: ${PROJECTNAME}" | tee -a "_dv_login.txt"
echo "DB Pass: ''" | tee -a "_dv_login.txt"

echo '' | tee -a "_dv_login.txt"
echo "------------ WP ------------" | tee -a "_dv_login.txt"
echo "WP Url: ${WPURL}" | tee -a "_dv_login.txt"
echo "WP User: ${WPUSER}" | tee -a "_dv_login.txt"
echo "WP Pass: ${WPPASS}" | tee -a "_dv_login.txt"
echo "WP Email: ${WPEMAIL}" | tee -a "_dv_login.txt"