#!/bin/bash

TABLE_DIR="$HOME/YourSQL_Table"
mkdir -p "$TABLE_DIR"

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
        --title="YourSQL Menu" \
        --text="Choose an option" \
        --column="Menu" \
        --width=400 \
        --height=500 \
        "Create Table" \
        "List Tables" \
        "Drop Table" \
        "Exit")
    
    case "$choice" in
        "Create Table")
            # Get table name
            table_name=$(zenity --entry \
                --title="Create Table" \
                --text="Enter table name:" \
                --width=400)
            
            if [ -z "$table_name" ]; then
                zenity --error --text="Table name cannot be empty" --width=300
                continue
            fi
            
            if ! validate_name "$table_name"; then
                zenity --error \
                    --text="Invalid table name!\nMust start with letter and contain only letters, numbers, and underscores." \
                    --width=400
                continue
            fi
            
            if [ -f "$TABLE_DIR/$table_name.data" ]; then
                zenity --error --text="Table '$table_name' already exists" --width=300
                continue
            fi
            
            # Define columns
            declare -a columns
            declare -a col_names
            
            zenity --info \
                --title="Define Columns" \
                --text="Now define the columns for table '$table_name'.\n\nClick OK to continue." \
                --width=400
            
            while true; do
                col_info=$(zenity --forms \
                    --title="Add Column to '$table_name'" \
                    --text="Define column (Cancel when done):" \
                    --add-entry="Column Name" \
                    --add-combo="Data Type" --combo-values="int|string|float|date" \
                    --width=400 \
                    --height=200)
                
                # User clicked Cancel - exit loop
                if [ $? -ne 0 ]; then
                    break
                fi
                
                col_name=$(echo "$col_info" | cut -d'|' -f1)
                col_type=$(echo "$col_info" | cut -d'|' -f2)
                
                # Both empty - treat as done
                if [ -z "$col_name" ] && [ -z "$col_type" ]; then
                    break
                fi
                
                # Only one filled - show error
                if [ -z "$col_name" ] || [ -z "$col_type" ]; then
                    zenity --error \
                        --title="Error" \
                        --text="Both column name and type are required!" \
                        --width=400
                    continue
                fi
                
                if ! validate_name "$col_name"; then
                    zenity --error \
                        --title="Error" \
                        --text="Invalid column name!\nMust start with letter and contain only letters, numbers, and underscores." \
                        --width=400
                    continue
                fi
                
                # Check for duplicate column
                if [[ " ${col_names[*]} " =~ " $col_name " ]]; then
                    zenity --error \
                        --title="Error" \
                        --text="Column '$col_name' already exists!" \
                        --width=400
                    continue
                fi
                
                columns+=("{\"name\":\"$col_name\",\"type\":\"$col_type\"}")
                col_names+=("$col_name")
            done
            
            if [ ${#columns[@]} -eq 0 ]; then
                zenity --error \
                    --title="Error" \
                    --text="At least one column is required!\nTable creation cancelled." \
                    --width=400
                continue
            fi
            
            # Ask for primary key
            pk_list=()
            pk_list+=("FALSE" "None")
            for col in "${col_names[@]}"; do
                pk_list+=("FALSE" "$col")
            done
            
            pk_col=$(zenity --list \
                --title="Select Primary Key" \
                --text="Select a primary key column for '$table_name' (optional):" \
                --radiolist \
                --column="Select" \
                --column="Column Name" \
                --width=400 \
                --height=500 \
                "${pk_list[@]}")
            
            if [ "$pk_col" == "None" ] || [ -z "$pk_col" ]; then
                pk_col="null"
            else
                pk_col="\"$pk_col\""
            fi
            
            # Create metadata file
            cols_json=$(IFS=,; echo "${columns[*]}")
            echo "{\"columns\":[$cols_json],\"primary_key\":$pk_col}" > "$TABLE_DIR/$table_name.meta"
            
            # Create empty data file
            touch "$TABLE_DIR/$table_name.data"
            
            zenity --info \
                --title="Success" \
                --text="Table '$table_name' created successfully!\n\nColumns: ${#columns[@]}\nPrimary Key: $(echo $pk_col | tr -d '\"')" \
                --width=400
            ;;
            
        "List Tables")
            # Find all .data files
            tables=($(find "$TABLE_DIR" -maxdepth 1 -type f -name "*.data" -exec basename {} .data \; 2>/dev/null | sort))
            
            if [ ${#tables[@]} -eq 0 ]; then
                zenity --info \
                    --title="List Tables" \
                    --text="No tables found.\n\nCreate a table first!" \
                    --width=400
            else
                # Build table information for zenity --list
                table_data=()
                for table in "${tables[@]}"; do
                    if [ -f "$TABLE_DIR/$table.data" ] && [ -f "$TABLE_DIR/$table.meta" ]; then
                        row_count=$(wc -l < "$TABLE_DIR/$table.data" 2>/dev/null || echo "0")
                        col_count=$(grep -o '"name"' "$TABLE_DIR/$table.meta" 2>/dev/null | wc -l)
                        pk=$(grep -o '"primary_key":"[^"]*"' "$TABLE_DIR/$table.meta" 2>/dev/null | cut -d'"' -f4)
                        
                        if [ -z "$pk" ] || [ "$pk" == "null" ]; then
                            pk="None"
                        fi
                        
                        table_data+=("$table" "$row_count" "$col_count" "$pk")
                    fi
                done
                
                if [ ${#table_data[@]} -eq 0 ]; then
                    zenity --info \
                        --title="List Tables" \
                        --text="No valid tables found." \
                        --width=400
                else
                    zenity --list \
                        --title="YourSQL - All Tables" \
                        --text="List of all tables:" \
                        --column="Table Name" \
                        --column="Rows" \
                        --column="Columns" \
                        --column="Primary Key" \
                        --width=700 \
                        --height=400 \
                        "${table_data[@]}"
                fi
            fi
            ;;
            
        "Drop Table")
            # Find all .data files
            tables=($(find "$TABLE_DIR" -maxdepth 1 -type f -name "*.data" -exec basename {} .data \; 2>/dev/null | sort))
            
            if [ ${#tables[@]} -eq 0 ]; then
                zenity --error \
                    --title="Error" \
                    --text="No tables available to drop!" \
                    --width=400
            else
                # Build radio list
                table_list=()
                for table in "${tables[@]}"; do
                    if [ -f "$TABLE_DIR/$table.data" ]; then
                        row_count=$(wc -l < "$TABLE_DIR/$table.data" 2>/dev/null || echo "0")
                        table_list+=("FALSE" "$table" "$row_count rows")
                    fi
                done
                
                if [ ${#table_list[@]} -eq 0 ]; then
                    zenity --error \
                        --title="Error" \
                        --text="No tables available!" \
                        --width=400
                else
                    selected=$(zenity --list \
                        --title="Drop Table" \
                        --text="Select a table to drop:" \
                        --radiolist \
                        --column="Select" \
                        --column="Table Name" \
                        --column="Info" \
                        --width=500 \
                        --height=350 \
                        "${table_list[@]}")
                    
                    if [ $? -eq 0 ] && [ -n "$selected" ]; then
                        # Confirmation
                        zenity --question \
                            --title="Confirm Drop" \
                            --text="Are you sure you want to drop table '$selected'?\n\nThis action cannot be undone!" \
                            --width=400
                        
                        if [ $? -eq 0 ]; then
                            rm -f "$TABLE_DIR/$selected.data" "$TABLE_DIR/$selected.meta"
                            zenity --info \
                                --title="Success" \
                                --text="Table '$selected' dropped successfully!" \
                                --width=400
                        fi
                    fi
                fi
            fi
            ;;
            
        "Exit"|*)
            zenity --question \
                --title="Exit YourSQL" \
                --text="Are you sure you want to exit?" \
                --width=300
            if [ $? -eq 0 ]; then
                exit 0
            fi
            ;;
    esac
done
