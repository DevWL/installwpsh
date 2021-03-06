#!/bin/bash

# Version: v1.4.1
# This script is currently under development (alpha version).
# Next version will proceed as fallow: version v2.0.0 (beta), version v3.0.0 (RC) and finely v4.0.0 (first stable).
# Feel free to contribute to fix anny spoted issues.
#
# WARNING! No Warranty! This script comes with no warantty of any kind. 
# You can use this script at your own risk.
# NOTICE! Note the use of "rm -rf" in the script which if missued can cause data lost. Always validate and verify the script before you run it!.
# 
# @Author: Wiktor Liszkiewicz
# @Email: w.liszkiewicz@gmail.com
    echo "# Turn on laragon and run server and mysql"
    echo "# This installer was created to work with Laragon (If you want to configure it for XAMPP you need to change hardcoded SERVERWWW path)"
    echo "# To be able to run this script on Winodows you first need to install:"
    echo "# some linux subsystem like git-bash or cmdr"
    echo "# wget or curl"
    echo "# tar, zip and unizp" #https://superuser.com/questions/201371/create-zip-folder-from-the-command-line-windows #http://gnuwin32.sourceforge.net/packages/zip.htm

    echo ""
    echo "---### WARNING! No Warranty! This script comes with no warantty of any kind (this shell script uses \"rm -rf\" so be cautious!) ###---"
    echo "# If you ahve any question you can try to reach me at w.liszkiewicz@gmail.com"

    echo ""
    echo "# If you want to add more plugins go to 'create plugin LIB' section and add wget lines to the zip file of your plugin. You can cp it from webbrowser (right click on btn > coppy url)"
    echo "# All plugins will be automatically activated"
    echo ""
    echo "# At the end of script execution it will generate output in cli aditional a _dv_login.txt file will be generated in the project root"

    echo ""
    echo "# Project name (without special char only letters and numbers no spacesec) press enter for default value "

############################################# run LARAGON ###################################################################################
    # manualy

#############################################  INITIAL SETUP #################################################################################
    DOMAINEXT="dv" # laradgon default is "test" <<<< edit if needed

    ACCEPT="n"
    TEMPNAME=demo1
    PROJECTNAME=${TEMPNAME}
    # TODO - validate proper user inputs
    while [ "${ACCEPT}" != "y" ] && [ ${#PROJECTNAME} -ge 1 ] && [[ "$PROJECTNAME" =~ [a-zA-Z0-9] ]] && [[ "${PROJECTNAME:0:1}" =~ [a-zA-Z] ]]; do
        if [[ "$PROJECTNAME" =~ [^a-zA-Z0-9] ]] || [[ "${PROJECTNAME:0:1}" =~ [^a-zA-Z] ]]; then
            echo "Only letters and numbers allowed. First char has to be a letter"
        fi
        
        read -p "default [${TEMPNAME}]: " PROJECTNAME
        PROJECTNAME=${PROJECTNAME:-"${TEMPNAME}"}
        PROJECTNAME=${PROJECTNAME##*/}
        PROJECTNAME=${PROJECTNAME%.*}
        
        echo "Confirm site url = ${PROJECTNAME}.${DOMAINEXT}"
        #do other stuff
        read -p 'default n [y/n]: ' ACCEPT
        ACCEPT=${ACCEPT:-"n"}

        TEMPNAME=${PROJECTNAME}
    done

    echo ""
    echo "# Project e-email "
    read -p 'default [w.liszkiewicz@gmail.com]: ' WPEMAIL
    WPEMAIL=${WPEMAIL:-"w.liszkiewicz@gmail.com"} # <<<<< edit default email 

    LARAGONPATH="/c/laragon.dv" # chnge this line if your instalation is placed in different file
    SERVERWWW=${LARAGONPATH}/www # <<<<< edit to fit your needs
    PROJECTROOT=$SERVERWWW/$PROJECTNAME

    # Setup site folder, replace all $PROJECTNAME with $PROJECTNAME
    mkdir ${PROJECTROOT}
    cd ${PROJECTROOT}

    echo "# Get fresh files? Requiered when runing first time!"
    read -p 'y/n default [n]' UPDATEFILE

#############################################  DOWNLOAD WP || LOAD LOCAL FILE  #################################################################################
#https://superuser.com/questions/493640/how-to-retry-connections-with-wget
    WPSRC='https://pl.wordpress.org/latest-pl_PL.tar.gz' # EN - https://wordpress.org/latest.tar.gz # PL - https://pl.wordpress.org/latest-pl_PL.tar.gz
    WPCMSBASENAME=$(basename -- $WPSRC)
    cd ${SERVERWWW}

    if [ "$UPDATEFILE" = "y" ]
    then
        echo "Removing old WP src ${SERVERWWW}/$WPCMSBASENAME"
        rm ${SERVERWWW}/$WPCMSBASENAME
        # wget --tries=70 -O latest.tar.gz ${WPSRC} || curl -O latest.tar.gz ${WPSRC} #TODO - check lastest ver on local machine and copy it if it is not older then X time
        while [ 1 ]; do
            wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue -O ${WPCMSBASENAME} ${WPSRC} || curl -O ${WPSRC}
            if [ $? = 0 ]; then break; fi; # check return value, break if successful (0)
            sleep 2s;
        done;
        # curl -O http://wordpress.org/latest.tar.gz 
    fi

    cp ${SERVERWWW}/${WPCMSBASENAME} ${PROJECTROOT}
    cd ${PROJECTROOT}
    file ${WPCMSBASENAME}
    tar -xf ${WPCMSBASENAME} || exit $?
    cd ./wordpress || exit $?
    cd ${PROJECTROOT}/wordpress # another way

    mv * ${PROJECTROOT}
    mv .* ${PROJECTROOT} 2> /dev/null #suppress errors and warnings
    cd ..
    rmdir ./wordpress


#############################################  PLUGIN AND THEME CLEANUP #################################################################################

    # Whipe out all themes
        echo '# Removeing default themes: '
        # rm -rf ${PROJECTROOT}/wp-content/themes/*
        rm -rf ${PROJECTROOT}/wp-content/themes/{twentynineteen,twentyseventeen,twentysixteen,twentytwenty,twentytwentyone}

    # Whipe out all plugins
        echo '# Removeing default plugins: '
        rm -rf ${PROJECTROOT}/wp-content/plugins/{hello.php,akismet}


#############################################  DATABASE MYSQL #################################################################################
# # Setup MySQL Database
# mysql.server start # use on linux
    # # DATABASENAME=${PROJECTNAME}${DOMAINEXT} #if you need to create a name with extension test or dv, if you have multiple instance of laragon installed it is prabobly best to not use this to be more portable between env
    DATABASENAME=${PROJECTNAME}
    # # first, strip underscores
    # DATABASENAME=${DATABASENAME//_/}
    # next, replace spaces with underscores
    DATABASENAME=${DATABASENAME// /_}
    # now, clean out anything that's not alphanumeric or an underscore
    DATABASENAME=${DATABASENAME//[^a-zA-Z0-9_]/}
    # finally, lowercase with TR
    DATABASENAME=$(echo -n ${DATABASENAME} | tr A-Z a-z)
    # SANITIZE DATABSE NAME (REMOVE UNEXPECTED CHAR)
    
    mysql -u root -e "create database ${DATABASENAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
    mysql -u root -e "create user '${DATABASENAME}'@'localhost' identified by password ''";
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${DATABASENAME}.* TO ${DATABASENAME}@localhost";
    mysql -u root -e "FLUSH PRIVILEGES";



    # # Create config file # note I have used .dv instead of laragon default .test local domain extension

    WPUSER="Laragon"
    WPPASS="silentisgold"
    WPURL="https://${PROJECTNAME}.${DOMAINEXT}"

    cd ${PROJECTROOT}
    wp-cli.phar core config --dbname=${DATABASENAME} --dbuser=${DATABASENAME}
    wp-cli.phar core install --url=${WPURL} --title=${PROJECTNAME} --admin_user=${WPUSER} --admin_password=${WPPASS} --admin_email=${WPEMAIL}
    # wp https://make.wordpress.org/cli/handbook/guides/installing/


# ######################################## create themes LIB ########################################
    THEMESLIB=${SERVERWWW}/wp-themes
    if [ ! -d ${THEMESLIB} ]
    then
        mkdir ${SERVERWWW}/wp-themes 2> /dev/null #suppress errors and warnings
    fi

    # # THEMESRC='http://github.com/toddmotto/html5blank/archive/stable.zip' # <<<<< edit if needed [HTML5BLANK]
    # THEMESRC='https://github.com/Automattic/_s/archive/refs/heads/master.zip' # <<<<< edit if needed [_S]
    # THEMEBASENAME=$(basename -- $THEMESRC)

    # cd ${THEMESLIB}
    # if [ "$UPDATEFILE" = "y" ]
    # then
    #     echo "Removing old theme ${THEMESLIB}/$THEMEBASENAME"
    #     rm ${THEMESLIB}/$THEMEBASENAME
    #     while [ 1 ]; do
    #         wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue -O $THEMEBASENAME ${THEMESRC} || curl -O ${THEMESRC}
    #         if [ $? = 0 ]; then break; fi; # check return value, break if successful (0)
    #         sleep 2s;
    #     done;
    #     ## OR GET THEMES FROM LOCAL DIR LIKE THIS
    # fi

    LOCALTHEMESRC='/c/users/symfony/downloads/Divi.zip' # <<<<< edit if needed
    LOCALTHEMEBASENAME=$(basename -- $LOCALTHEMESRC)
    echo LOCALTHEMEBASENAME ${LOCALTHEMEBASENAME} # <<<<<<<<<<<<<<<<<< TEST

    # copy theme from local folder to lib directory
    cp -r ${LOCALTHEMESRC} ${THEMESLIB} # <<<<< edit if needed

    # reasign themebasename if using localtheme instead of undercore or boilerplate    
    THEMEBASENAME=${LOCALTHEMEBASENAME}
    echo THEMEBASENAME ${THEMEBASENAME} # <<<<<<<<<<<<<<<<<< TEST

    ##################### <<<<<<<<<<<<<<<<<<<<<<<<<< replace
    # ## unzip all files
    # # unzip -qqo \*.zip

    # cp -r ${THEMESLIB}/* ${PROJECTROOT}/wp-content/themes
    # rm ${PROJECTROOT}/wp-content/themes/*.zip
    # mv ${PROJECTROOT}/wp-content/themes/html5blank-stable/ ${PROJECTROOT}/wp-content/themes/$PROJECTNAME

    # # # Install and activate theme and plugins
    # cd ${PROJECTROOT}
    # wp-cli.phar theme activate $PROJECTNAME
    # # wp-cli.phar theme activate Divi
    ##################### <<<<<<<<<<<<<<<<<<<<<<<<<< replace

    cd ${PROJECTROOT}
    # wp-cli.phar theme install ${THEMESLIB}/$THEMEBASENAME --activate
    wp-cli.phar theme install ${THEMESLIB}/${THEMEBASENAME} 
    echo Install theme wp-cli THEMESLIB/THEMEBASENAME : ${THEMESLIB}/${THEMEBASENAME}

    removeSpecialChars () 
    {
        local a=${1//[^[:alnum:]]/}
        local temp="${a,,}"
        echo ${temp}
        return ${temp}
    }

    
    # find the unzpi folder name
    UZIPFOLDERNAME=$(unzip -qql ${THEMESLIB}/${THEMEBASENAME} | head -n1 | tr -s ' ' | cut -d' ' -f5-)
    echo UZIPFOLDERNAME ${UZIPFOLDERNAME} # <<<<<<<<<125<<<<<<<<< TEST
    UZIPFOLDERNAMEMOD=$(echo $UZIPFOLDERNAME | cut -d/ -f1) # shoud generate extracted folder name ex: "Divi"


    # UZIPFOLDERNAMEMOD=${UZIPFOLDERNAME::-1} # remove forwar slash at the end of the dir name
    # UZIPFOLDERNAMEMOD=${UZIPFOLDERNAMEMOD//-stable/} # remove given fraze from folder name https://unix.stackexchange.com/questions/311758/remove-specific-word-in-variable
    
    echo UZIPFOLDERNAMEMOD ${UZIPFOLDERNAMEMOD} # <<<<<<<<<125<<<<<<<<< TEST

    # remove extension from filename > https://stackoverflow.com/questions/2664740/extract-file-basename-without-path-and-extension-in-bash > https://linuxgazette.net/18/bash.html
    PARENTTHEME=${UZIPFOLDERNAMEMOD%%.*}
    echo PARENTTHEME ${PARENTTHEME} # <<<<<<<<<125<<<<<<<<< TEST
    CHILDTHEME=${PARENTTHEME}-child
    echo CHILDTHEME ${CHILDTHEME} # <<<<<<<<<125<<<<<<<<< TEST
    echo "Creating child-theme ${CHILDTHEME} for ${PARENTTHEME} parrent theme"

    wp-cli.phar scaffold child-theme ${CHILDTHEME} --parent_theme=${PARENTTHEME} --activate

    # exit 0 # <<<<<<<<<125<<<<<<<<< TEST

    # wp-cli.phar theme activate ${CHILDTHEME}
    ## [i] For manual theme selection you can do: wp-cli.phar theme install ${THEMESLIB}/Divi.zip --activate

# ######################################## create plugin LIB ########################################
    cd $SERVERWWW
    PLUGINLIB=${SERVERWWW}/wp-plugins
    mkdir $PLUGINLIB 2> /dev/null #suppress errors and warnings
    cd $PLUGINLIB

# # DOWNLOAD PLUGIN ARRAY WITH WGET OR CURL
# # OR SKIP THIS STEP IF YOU WANT TO DOWNLOAD PLUGINS WITH WP-CLI
# # https://www.linuxjournal.com/content/bash-arrays

#     # if [ "$UPDATEFILE" = "y" ]
#     # cd $PLUGINLIB
#     # then
#     #     PLUGINARR=()
#     #     PLUGINARR+=('https://downloads.wordpress.org/plugin/advanced-custom-fields.5.10.2.zip')
#     #     PLUGINARR+=('https://downloads.wordpress.org/plugin/better-wp-security.8.0.2.zip')
#     #     PLUGINARR+=('https://downloads.wordpress.org/plugin/all-in-one-wp-migration.7.48.zip')
#     #     PLUGINARR+=('https://downloads.wordpress.org/plugin/duplicate-post.4.1.2.zip')
#     #     #PLUGINARR+=('add another url here')
        
#     #     for PLUGIN in ${PLUGINARR[*]}
#     #     do
#     #         # printf "   %s\n" $PLUGIN
#     #         PLUGINBASENAME=$(basename -- $PLUGIN)
#     #         ## wget -O $PLUGINBASENAME $PLUGIN || curl -O $PLUGIN
#     #         while [ 1 ]; do
#     #             wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 --continue -O ${PLUGINBASENAME} ${PLUGIN} || curl -O ${PLUGIN}
#     #             if [ $? = 0 ]; then break; fi; # check return value, break if successful (0)
#     #             sleep 2s;
#     #         done;
#     #     done

#     #     for PLUGIN in ${PLUGINARR[*]}
#     #     do
#     #         cd ${PROJECTROOT}
#     #         wp-cli.phar plugin install ${PLUGINLIB}/${PLUGIN} --activate
#     #     done
#     # fi

#     # # UNZIP all zip files
#     # cd $PLUGINLIB
#     # unzip -qqo \*.zip

#     # cp -r ${PLUGINLIB}/* ${PROJECTROOT}/wp-content/plugins
#     # rm ${PROJECTROOT}/wp-content/plugins/*.zip


###################### WP-CLI ACTIAVTE ALL PLUGINS BASED ON plugin dir content ########################
    # cd $PLUGINLIB
    # array=()
    # for dir in */
    # do
    #     dir=${dir%*/}
    #     ( echo "$dir" )
    #     array+=("$dir")
    # done

    # echo "${array[@]}"

    # cd ${PROJECTROOT}
    # for i in "${array[@]}"
    # do
    # echo "--- $i -> activating"
    # wp-cli.phar plugin activate $i

    # done

###################### INSTALL SAMPLE PLUGIN #########################
    cd ${PROJECTROOT}
    wp-cli.phar scaffold plugin ${CHILDTHEME}-plugin

###################### WP-CLI INSTALL PLUGINS ########################
# https://developer.wordpress.org/cli/commands/

    PLUGINSLIST=()
    PLUGINSLIST+=('better-wp-security')
    PLUGINSLIST+=('advanced-custom-fields')
    PLUGINSLIST+=('all-in-one-wp-migration')
    PLUGINSLIST+=('duplicate-post')
    PLUGINSLIST+=('enable-media-replace')
    PLUGINSLIST+=('wp-fastest-cache')
    PLUGINSLIST+=('wordpress-seo')

    if [ "$UPDATEFILE" = "y" ]
    then
        cd ${PROJECTROOT}

        for PLUGIN in ${PLUGINSLIST[*]}
        do
            cd ${PROJECTROOT}
            wp-cli.phar plugin install ${PLUGIN} --activate
        done

        cp -r ${PROJECTROOT}/wp-content/plugins/* ${PLUGINLIB}
        cd ${PLUGINLIB}
        #TODO remove zip and copy only
        # for i in */; do zip -0 -r "${i%/}.zip" "$i" & done; wait # with zip
        # for i in */; do tar -a -c -f "${i%/}.zip" "$i" & done; wait # with tar https://techcommunity.microsoft.com/t5/containers/tar-and-curl-come-to-windows/ba-p/382409

    else
        #TODO 
        for PLUGIN in ${PLUGINSLIST[*]}
        do
            cp -r ${PLUGINLIB}/* ${PROJECTROOT}/wp-content/plugins
            cd ${PROJECTROOT}
            wp-cli.phar plugin activate ${PLUGIN}
        done
    fi
    ## TODO COPY PLUGINS TO $PLUGINLIB if n install from $PLUGINLIB looping over filedir


###################### USE WP-CLI - ADD REMOVE PAGES/POSTS ######################
# Remove posts/pages
    cd ${PROJECTROOT}
    wp-cli.phar post delete 1 --force #Hello World!
    wp-cli.phar post delete 2 --force #Sample Page

# Add Pages - Set your own page name
    cd ${PROJECTROOT}
    wp-cli.phar post create --post_type=page --post_status=draft --post_title="Home" # replace post_title value
    wp-cli.phar post create --post_type=page --post_status=draft --post_title=Contact # replace post_title value
    wp-cli.phar post create --post_type=page --post_status=draft --post_title=Blog # replace post_title value
    wp-cli.phar post create --post_type=page --post_status=draft --post_title=Services # replace post_title value
    wp-cli.phar post create --post_type=page --post_status=draft --post_title=Gallery # replace post_title value
    wp-cli.phar post create --post_type=page --post_status=draft --post_title=Portfolio # replace post_title value
    # wp-cli.phar option update page_on_front 4 # replace 4 with page id you want to set as homepage # all options to set available are listed at domainname/wp-admin/options.php <<< This cose some issue with loading styles for homepage with DIVI theme

    wp-cli.phar menu create "Main" #https://developer.wordpress.org/cli/commands/menu/

################### USE LARAGON CLI - LARAGON RELOAD AND OPEN ######################
# https://laragon.org/docs/cli.html
    ${LARAGONPATH}/laragon reload
    start https://${PROJECTNAME}.dv
    start https://${PROJECTNAME}.dv/wp-admin

###################### Output DV login info ######################
    cd ${PROJECTROOT}
    echo > "_dv_login.txt"
    echo '' | tee -a "_dv_login.txt"
    echo "------------ DB ------------" | tee -a "_dv_login.txt"
    echo "Database: ${DATABASENAME}" | tee -a "_dv_login.txt"
    echo "DB User: ${DATABASENAME}" | tee -a "_dv_login.txt"
    echo "DB Pass: ''" | tee -a "_dv_login.txt"

    echo '' | tee -a "_dv_login.txt"
    echo "------------ WP ------------" | tee -a "_dv_login.txt"
    echo "WP Url: ${WPURL}" | tee -a "_dv_login.txt"
    echo "WP User: ${WPUSER}" | tee -a "_dv_login.txt"
    echo "WP Pass: ${WPPASS}" | tee -a "_dv_login.txt"
    echo "WP Email: ${WPEMAIL}" | tee -a "_dv_login.txt"

