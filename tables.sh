#!/bin/bash

TABLE_DIR="$HOME/YouSql"
mkdir -p "$TABLE_DIR"

choice=$(zenity --list \
--title="YouSql Menu" \
--text="Choose an option" \
--column="Menu" \
"Create Table" \
"List Tables" \
"Drop Table")

case "$choice" in

"Create Table")
    table_name=$(zenity --entry --title="Create Table" --text="Enter table name:")
    if [ -n "$table_name" ]; then
        touch "$TABLE_DIR/$table_name"
        zenity --info --text="Table '$table_name' created successfully"
    fi
    ;;

"List Tables")
    tables=$(ls "$TABLE_DIR" 2>/dev/null)
    if [ -z "$tables" ]; then
        zenity --info --text="No tables found"
    else
        zenity --info --text="Tables:\n$tables"
    fi
    ;;

"Drop Table")
    table_name=$(zenity --entry --title="Drop Table" --text="Enter table name to delete:")
    if [ -f "$TABLE_DIR/$table_name" ]; then
        rm "$TABLE_DIR/$table_name"
        zenity --info --text="Table '$table_name' deleted"
    else
        zenity --error --text="Table not found"
    fi
    ;;

*)
    zenity --info --text="Exit"
    ;;
esac
