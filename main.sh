#!/bin/bash -x



case $1 in
    "CREATE" | "create")
    	case $2 in
    	"DATABASE" | "database")
    		echo "create database..."
    		mkdir ~/Documents/YourSQL/$3
    		;;
		"TABLE" | "table")
    		zenity --error --text="connect to database first."
    		;;
    	*)
    		zenity --error --text="invalid syntax."
    		;;
    	esac
        ;;
    *)
        echo not ok
        ;;
esac
