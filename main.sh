#!/bin/bash

while true

do

selection=$(zenity --list --title="YourSQL" --column="Database Queries" "Create Database" "Show Database" "Use Database" "Drop Database" "Exit")

case $selection in
    "Create Database")
        clear;
    	echo "create database..."
        USER_INPUT=$(zenity --entry --title="Database Creation" --text="Enter Database Name:")
        mkdir ~/Documents/YourSQL/$USER_INPUT && zenity --info --text="$USER_INPUT Database Created Successfully" || zenity --error --text="Database already exists..."
        # PS1="using ($USER_INPUT) > "
        ;;
    "Show Database")
        clear;
        ls -1 ~/Documents/YourSQL
        ;;
    "Use Database")
        clear;
        USER_INPUT=$(zenity --entry --title="Database Using" --text="Enter Database Name:")
        CurrentDB=~/Documents/YourSQL/$USER_INPUT && zenity --info --text="Using $USER_INPUT Database" || zenity --error --text="No such database"
        PS1="$USER_INPUT> "
        . ./Menu_Table.sh
        ;;
    "Drop Database")
        clear;
        USER_INPUT=$(zenity --entry --title="Database Deletion" --text="Enter Database Name:")
        rm -r ~/Documents/YourSQL/$USER_INPUT && zenity --info --text="Deleted $USER_INPUT Database." || zenity --error --text="No such database"    
        ;;    
    "Exit")
        clear;
        exit 1;
        ;;
    *)
        echo not ok
        ;;
esac

done
