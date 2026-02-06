#!/bin/bash

echo hi from Menu_Table.sh this is my database $CurrentDB

typeof() {
    local value="$1"
    if [[ $value =~ ^[+-]?[0-9]+$ ]]; then
        echo "int"
    elif [[ $value =~ ^[+-]?[0-9]+\.$ ]]; then
        echo "string"
    elif [[ $value =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
        echo "float"
    else
        echo "string"
    fi
}

TABLE_DIR=$CurrentDB
# mkdir -p "$TABLE_DIR"

# Validate name (table/column)
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        return 1
    fi
    return 0
}

while true
do
    choice=$(zenity --list \
        --title="YourSQL" \
        --text="Choose an option" \
        --column="Menu" \
        --width=400 \
        --height=500 \
        "Create Table" \
        "List Tables" \
        "Drop Table" \
        "Insert Into Table"\
        "Select From Table"\
        "Delete From Table"\
        "Update Table"\
        "Exit")
    
    case "$choice" in
       "Create Table")
    table_name=$(zenity --entry \
        --title="Create Table" \
        --text="Enter table name:")

    [[ -z "$table_name" ]] && continue
    validate_name "$table_name" || {
        zenity --error --text="Invalid table name"
        continue
    }

    if [ -d "$TABLE_DIR/$table_name" ]; then
        zenity --error --text="Table already exists"
        continue
    fi

    declare -a col_names
    declare -a col_types

    zenity --info --text="Define columns (Cancel when finished)"

    while true; do
        col_info=$(zenity --forms \
            --title="Add Column" \
            --add-entry="Column Name" \
            --add-combo="Data Type" --combo-values="int|string|float|date")

        [[ $? -ne 0 ]] && break

        col_name=$(cut -d'|' -f1 <<< "$col_info")
        col_type=$(cut -d'|' -f2 <<< "$col_info")

        [[ -z "$col_name" || -z "$col_type" ]] && continue
        validate_name "$col_name" || continue

        [[ " ${col_names[*]} " =~ " $col_name " ]] && {
            zenity --error --text="Column already exists"
            continue
        }

        col_names+=("$col_name")
        col_types+=("$col_type")
    done

    if [ ${#col_names[@]} -eq 0 ]; then
        zenity --error --text="At least one column required"
        continue
    fi

    # ===== Select Primary Key =====
    pk_list=()
    for col in "${col_names[@]}"; do
        pk_list+=("FALSE" "$col")
    done

    pk_col=$(zenity --list \
        --title="Primary Key" \
        --text="Select Primary Key (will be first and start with _)" \
        --radiolist \
        --column="Select" \
        --column="Column" \
        "${pk_list[@]}")

    [[ -z "$pk_col" ]] && {
        zenity --error --text="Primary Key is required"
        continue
    }

    # ===== Create table folder =====
    mkdir -p "$TABLE_DIR/$table_name"
    meta_file="$TABLE_DIR/$table_name/.meta"
    data_file="$TABLE_DIR/$table_name/$table_name.db"

    # ===== Write META =====
    # Primary key first with _
    for i in "${!col_names[@]}"; do
        if [ "${col_names[$i]}" == "$pk_col" ]; then
            echo "_${col_names[$i]}:${col_types[$i]}" > "$meta_file"
        fi
    done

    # Other columns
    for i in "${!col_names[@]}"; do
        if [ "${col_names[$i]}" != "$pk_col" ]; then
            echo "${col_names[$i]}:${col_types[$i]}" >> "$meta_file"
        fi
    done

    touch "$data_file"

    zenity --info --text="Table '$table_name' created successfully"
;;

            
        "List Tables")
            # Find table folders
            tables=$(find "$TABLE_DIR" -maxdepth 1 -type d ! -path "$TABLE_DIR" -exec basename {} \; 2>/dev/null | sort)
            
            if [ -z "$tables" ]; then
                zenity --info --text="No tables found.\n\nCreate a table first!"
            else
                table_data=()
                for table in $tables; do
                    if [ -f "$TABLE_DIR/$table/$table.db" ]; then
                        rows=$(wc -l < "$TABLE_DIR/$table/$table.db" 2>/dev/null || echo "0")
                        cols=$(grep -c ":" "$TABLE_DIR/$table/.meta" 2>/dev/null || echo "0")
                        table_data+=("$table" "$rows" "$cols")
                    fi
                done
                
                if [ ${#table_data[@]} -eq 0 ]; then
                    zenity --info --text="No tables found"
                else
                    zenity --list \
                        --title="All Tables in $(basename $CurrentDB)" \
                        --text="List of tables:" \
                        --column="Table Name" \
                        --column="Rows" \
                        --column="Columns" \
                        --width=500 \
                        --height=400 \
                        "${table_data[@]}"
                fi
            fi
            ;;
            
        "Drop Table")
            # Find table folders
            tables=$(find "$TABLE_DIR" -maxdepth 1 -type d ! -path "$TABLE_DIR" -exec basename {} \; 2>/dev/null | sort)
            
            if [ -z "$tables" ]; then
                zenity --error --text="No tables to drop"
            else
                table_list=()
                for table in $tables; do
                    rows=$(wc -l < "$TABLE_DIR/$table/$table.db" 2>/dev/null || echo "0")
                    table_list+=("FALSE" "$table" "$rows rows")
                done
                
                selected=$(zenity --list \
                    --title="Drop Table" \
                    --text="Select table to drop:" \
                    --radiolist \
                    --column="" \
                    --column="Table Name" \
                    --column="Info" \
                    --width=500 \
                    --height=350 \
                    "${table_list[@]}")
                
                if [ -n "$selected" ]; then
                    zenity --question \
                        --title="Confirm Drop" \
                        --text="Drop table '$selected'?\n\nAll data will be deleted!\n\nThis cannot be undone!" \
                        --width=400
                    
                    if [ $? -eq 0 ]; then
                        rm -rf "$TABLE_DIR/$selected"
                        zenity --info --text="Table '$selected' dropped successfully"
                    fi
                fi
            fi
            ;;
             
        "Insert Into Table")
            record=""
            pk=""
            USER_INPUT=$(zenity --entry --title="Insert" --text="Enter Table Name:");
            cd $CurrentDB/$USER_INPUT && insertFile=$CurrentDB/$USER_INPUT || zenity --error --text="No such table";
            while IFS=':' read -r f1 f2
            do
                # printf 'name: %s type: %s\n' "$f1" "$f2"
                if [[ ${f1:0:1} == "_" ]] then
                    value=$(zenity --entry --title="insert into $USER_INPUT" --text="Enter ${f1:1} field:")
                else
                    value=$(zenity --entry --title="insert into $USER_INPUT" --text="Enter $f1 field:")
                fi
                valueType=$(typeof $value)
                echo the type is $valueType;
                echo pk data type $f2
                while [[ $valueType != "$f2" ]]; do
                    zenity --error --text="Invalide Data Type for $f1, Requied $f2.";
                    value=$(zenity --entry --title="insert into $USER_INPUT" --text="Enter $f1 field:")
                    valueType=$(typeof $value)
                done
                record="${record}${value}|"

                if [[ ${f1:0:1} == "_" ]] then
                    pk=$value;
                fi
            done <"$insertFile/.meta"

            echo ${record::-1} and pk is $pk

            duplicate=0

            while IFS='|' read -r f1 f2
            do
                if [[ $pk == $f1 ]] then
                    duplicate=1
                fi
            done <"$insertFile/$USER_INPUT.db"
            
            if [[ $duplicate == 1 ]] then
                zenity --error --text="ERROR: Duplicate Primary Key."
            else
                echo ${record::-1} >> $insertFile/$USER_INPUT.db && zenity --info --text"User Added Successfully"
            fi
            ;;
        "Select From Table")
            USER_INPUT=$(zenity --entry --title="Select" --text="Enter Table Name:");
            cd $CurrentDB/$USER_INPUT && selectFile=$CurrentDB/$USER_INPUT || zenity --error --text="No such table";

            selectSelection=$(zenity --list --title="Select From Table" --column="Selection" "All" "by primary key")

            case $selectSelection in
                "All")
                    clear
                    columns="|"
                    while IFS=':' read -r f1 f2
                    do
                        if [[ ${f1:0:1} == "_" ]] then
                            columns="${columns}${f1:1}|"
                        else
                            columns="${columns}${f1}|"
                        fi
                    done <"$selectFile/.meta" 
                    echo "------------------------------------------------"
                    echo ${columns}
                    echo "------------------------------------------------" 
                    while IFS= read -r line
                    do
                        echo "|$line|"
                    echo "------------------------------------------------"
                    done <"$selectFile/$USER_INPUT.db"

                    ;;
                "by primary key")
                    clear
                    pk=$(zenity --entry --title="Select" --text="Enter Primary Key:");
                    columns="|"
                    while IFS=':' read -r f1 f2
                    do
                        if [[ ${f1:0:1} == "_" ]] then
                            columns="${columns}${f1:1}|"
                        else
                            columns="${columns}${f1}|"
                        fi
                    done <"$selectFile/.meta" 
                    echo "------------------------------------------------"
                    echo ${columns}
                    echo "------------------------------------------------" 
                    awk -v var="$pk" -F "|" '{if($1 == var) {print $0;}}' $selectFile/$USER_INPUT.db
                    echo "------------------------------------------------"
                ;;
                *)
                ;;
            esac
            ;;
        "Delete From Table")
            USER_INPUT=$(zenity --entry --title="Delete" --text="Enter Table Name:");
            cd $CurrentDB/$USER_INPUT && selectFile=$CurrentDB/$USER_INPUT || zenity --error --text="No such table";
            pk=$(zenity --entry --title="Delete" --text="Enter Primary Key:");
            t=$(mktemp)
            awk -v var="$pk" -F "|" '$1 != var' $selectFile/$USER_INPUT.db >"$t" && mv "$t" $selectFile/$USER_INPUT.db
            zenity --info --text="Deleted reocrd with primary key $pk"
            ;;
        "Update Table")
            newRecord=""
            updatePk=""
            USER_INPUT=$(zenity --entry --title="Update" --text="Enter Table Name:");
            cd $CurrentDB/$USER_INPUT && updateFile=$CurrentDB/$USER_INPUT || zenity --error --text="No such table";

            updatePk=$(zenity --entry --title="Update" --text="Enter Primary Key:");

            while IFS=':' read -r f1 f2
            do
                if [[ ${f1:0:1} == "_" ]] then
                    echo "ال id مش بيتعمله update"
                    # value=$(zenity --entry --title="Update $USER_INPUT" --text="Enter new ${f1:1} field:")
                else
                    value=$(zenity --entry --title="Update $USER_INPUT" --text="Enter new $f1 field:")
                    valueType=$(typeof $value)
                    echo the type is $valueType;
                    echo pk data type $f2
                    while [[ $valueType != "$f2" ]]; do
                        zenity --error --text="Invalide Data Type for $f1, Requied $f2.";
                        value=$(zenity --entry --title="Update $USER_INPUT" --text="Enter $f1 field:")
                        valueType=$(typeof $value)
                    done
                fi
                if [[ ${f1:0:1} == "_" ]] then
                    newRecord="${newRecord}${updatePk}|"
                else
                    newRecord="${newRecord}${value}|"
                fi
            done <"$updateFile/.meta"
            t=$(mktemp)
            awk -v var="$updatePk" -v newrecord="${newRecord::-1}" -F "|" '{if($1==var){gsub($0, newrecord);} print $0;}' $updateFile/$USER_INPUT.db >"$t" && mv "$t" $updateFile/$USER_INPUT.db
            #  >"$t" && mv "$t" $updateFile/$USER_INPUT.db
            # zenity --info --text="Updated reocrd with primary key $updatePk"
            theRecord=$(grep ${newRecord::-1} $updateFile/$USER_INPUT.db)
            sed -i "s/$theRecord/${newRecord::-1}/g" $updateFile/$USER_INPUT.db
            # awk -v therecord="$theRecord" -v newrecord="${newRecord::-1}" -F "|" '{gsub(therecord, newRecord); print $0}' $updateFile/$USER_INPUT.db >"$t" && mv "$t" $updateFile/$USER_INPUT.db

            # echo the record is $theRecord
            # echo new record is ${newRecord::-1}
            ;;
        "Exit"|*)
            zenity --question \
                --title="Exit YourSQL" \
                --text="Are you sure you want to exit?" \
                --width=300
            if [ $? -eq 0 ]; then
                . ./main.sh
            fi
            ;;
    esac
done
