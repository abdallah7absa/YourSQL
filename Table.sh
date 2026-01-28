#!/bin/bash

TABLE_DIR="$HOME/YourSQL"

# إنشاء المجلد لو مش موجود
mkdir -p "$TABLE_DIR"

while true
do
choice=$(zenity --list \
--title="YourSQL Menu" \
--text="Choose an option" \
--column="Menu" \
"Create Table" \
"List Tables" \
"Drop Table" \
"Exit")

case "$choice" in

"Create Table")
    table_name=$(zenity --entry \
    --title="Create Table" \
    --text="Enter table name:")

    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty"
    elif [ -f "$TABLE_DIR/$table_name" ]; then
        zenity --error --text="Table already exists"
    else
        touch "$TABLE_DIR/$table_name"
        zenity --info --text="Table '$table_name' created successfully"
    fi
    ;;

"List Tables")
    if [ "$(ls -A "$TABLE_DIR")" ]; then
        ls "$TABLE_DIR" | zenity --text-info --title="Tables List"
    else
        zenity --info --text="No tables found"
    fi
    ;;

"Drop Table")
    table_name=$(zenity --entry \
    --title="Drop Table" \
    --text="Enter table name to delete:")

    if [ -f "$TABLE_DIR/$table_name" ]; then
        rm "$TABLE_DIR/$table_name"
        zenity --info --text="Table '$table_name' deleted"
    else
        zenity --error --text="Table not found"
    fi
    ;;

"Exit"|*)
    exit 0
    ;;
esac
done
