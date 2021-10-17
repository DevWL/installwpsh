#!/bin/bash
# @Author: Wiktor Liszkiewicz
# @Email: w.liszkiewicz@gmail.com

echo "This installer was created to work with Laragon Dev Env over Xampp or Wampp because it is simple better"
echo "To be able to run this script on Winodows you first need to install:"
echo "some linux subsystem like git-bash or cmdr"
echo "wget and curl"
echo "tar"

echo ""
echo "If you want to add more plugins go to 'create plugin LIB' section and add wget lines to the zip file of your plugin. You can cp it from webbrowser (right click on btn > coppy url)"
echo "All plugins will be automatically activated"
echo "At the end you will generate output in cli and a configuration file will be generated in the project root with all the infromations needed"

echo ""
echo "Project name (without special char only letters and numbers no spacesec) press enter for default value "
read -p 'default [testsite]: ' PROJECTNAME
PROJECTNAME=${PROJECTNAME:-"testsite"}

SERVERWWW="/c/laragon/www" # << edit to fit your needs
PROJECTROOT=$SERVERWWW/$PROJECTNAME

# Setup site folder, replace all $PROJECTNAME with $PROJECTNAME
mkdir ${PROJECTROOT}
cd ${PROJECTROOT}
# cd ..

echo "Get fresh files? Requiered when runing first time!"
read -p 'y/n: ' UPDATEFILE
if [ "$UPDATEFILE" = "y" ]
then
    cd ${SERVERWWW}
    wget -q -O latest.tar.gz https://wordpress.org/latest.tar.gz #TODO - check lastest ver on local machine and copy it if it is not older then X time
    # curl -O http://wordpress.org/latest.tar.gz
fi

cp ${SERVERWWW}/latest.tar.gz ${PROJECTROOT}
cd ${PROJECTROOT}
tar -xzf latest.tar.gz || exit $?
cd ./wordpress || exit $?
cd ${PROJECTROOT}/wordpress # another way

mv * ${PROJECTROOT}
mv .* ${PROJECTROOT} 2> /dev/null #suppress errors and warnings
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
echo 'Type y to remove all plugins! Ppress enter for default [n]: '
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


# ######################################## create themes LIB ########################################
THEMESLIB=${SERVERWWW}/wp-themes
mkdir ${SERVERWWW}/wp-themes 2> /dev/null #suppress errors and warnings
cd ${THEMESLIB}

if [ "$UPDATEFILE" = "y" ]
then
    wget -q -O stable.zip http://github.com/toddmotto/html5blank/archive/stable.zip # use wget or curl -O
    # curl -O http://github.com/toddmotto/html5blank/archive/stable.zip
    cp -r /c/users/symfony/downloads/Divi.zip $THEMESLIB
fi


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
mkdir $PLUGINLIB 2> /dev/null #suppress errors and warnings
cd $PLUGINLIB

#Plugins: #AFC | #itsecurity | ...

if [ "$UPDATEFILE" = "y" ]
then
    wget -q -O advanced-custom-fields.zip https://downloads.wordpress.org/plugin/advanced-custom-fields.5.10.2.zip
    wget -q -O better-wp-security.zip https://downloads.wordpress.org/plugin/better-wp-security.8.0.2.zip
fi

#Unzip all zip files
unzip -qq \*.zip

cp -r ${PLUGINLIB}/* ${PROJECTROOT}/wp-content/plugins
rm ${PROJECTROOT}/wp-content/plugins/*.zip


###################### ACTIAVTE ALL PLUGINS ########################
cd $PLUGINLIB
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
   echo "--- $i -> activating"
   wp-cli.phar plugin activate $i

done


###################### ADD REMOVE PAGES POSTS ######################
# Remove posts/pages
wp-cli.phar post delete 1 --force #Hello World!
wp-cli.phar post delete 2 --force #Sample Page

# Add Pages
wp-cli.phar post create --post_type=page --post_title="Strona domowa"
wp-cli.phar post create --post_type=page --post_title=Kontakt
wp-cli.phar post create --post_type=page --post_title=Blog
wp-cli.phar post create --post_type=page --post_title=Produkty
wp-cli.phar post create --post_type=page --post_title=Usługi
wp-cli.phar post create --post_type=page --post_title=Galeria
wp-cli.phar post create --post_type=page --post_title=Reaizacje


###################### Output DV login info ######################
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