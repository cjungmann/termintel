#!/usr/bin/env bash

declare INPUT_FILE
declare OUTPUT_FILE
declare SET_NAME="SET"
declare SCRIPT_NAME="$0"
declare HEADER_FILE_NAME="bogus.h"

declare -i OUTPUT_TYPE_CODE=1
declare -i OUTPUT_TYPE_HEADER=2
declare -i OUTPUT_TYPE_COMBINED=3
declare -i OUTPUT_TYPE="$OUTPUT_TYPE_COMBINED"

declare -i INCLUDE_NAMES=0
declare -i INCLUDE_DESCRIPTIONS=0

show_usage()
{
    cat <<EOF
Usage:
   ${SCRIPT_NAME} [-h] [-i input_file] [-o output_file] [-s set_name]

Options:
-h    This display for help using this script.

-t    output_type (1 for code, 2 for header, 3 for combined)

-n    include array of capability name strings
-d    include array of capability description strings

-i    name of file to read for processing.  STDIN will
      be used in absence of the input option.
-o    name of file to which output will be written.  STDOUT
      will be used in absence of the output option.
-s    Root name for collections of elements in the output.

EOF
}

# Error-checking function for setting the OUTPUT_TYPE variable
# from a command line option.
set_output_type()
{
    declare -i OVAL="$1"
    if [ "$OVAL" -gt 0 ] && [ "$OVAL" -lt 4 ]; then
        OUTPUT_TYPE="$OVAL"
    else
        echo
        echo $'   \e[31;1mValid output type values are 1, 2, or 3.\e[m'
        echo
        show_usage
        exit 1
    fi
}

# Process command line arguments, setting global variables
# according to the user's wishes.
#
# Call from global scope with all arguments, like:
#    process_command_line_args "$@"
process_command_line_args()
{
    local val
    # state vals: 0, nothing on, 1 option on
    local -i state=0
    local cur_option

    for val in "$@"; do
        if [ "$state" -eq 0 ]; then
            if [ "${val:0:1}" == '-' ]; then
                cur_option="${val:1:1}"

                # process options without arguments here
                case "$cur_option" in
                    d) INCLUDE_DESCRIPTIONS=1; continue ;;
                    n) INCLUDE_NAMES=1; continue ;;
                    h) show_usage; return 1; ;;
                    esac

                state=1
            fi
        elif [ "$state" -eq 1 ]; then
            case "$cur_option" in
                i) INPUT_FILE="$val"  ;;
                o) OUTPUT_FILE="$val" ;;
                s) SET_NAME="$val"    ;;
                t) set_output_type "$val" ;;
                *) "Unrecognized option -$cur_option"
                   return 1
                   ;;
            esac
            cur_option=
            state=0
        fi
    done

    return 0
}

# If OUTPUT_FILE is a file, empty it.  Ignore otherwise, it's going to stdout
empty_output_file()
{
    if [ -n "$OUTPUT_FILE" ]; then
        echo -n > "$OUTPUT_FILE"
    fi
}

# Code for "write_supporting_code()"
add_empty_line()
{
    if [ -n "$OUTPUT_FILE" ]; then
        echo >> "$OUTPUT_FILE"
    else
        echo
    fi
}

# Write text of argument to OUTPUT_FILE if defined, otherwise to stdout
write_text()
{
    local wt_text="$1"
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$wt_text" >> "$OUTPUT_FILE"
    else
        echo "$wt_text"
    fi
}

# Break array into 4-element rows and call user-provided function to generate code.
#
# NOTE: Facility in code to omit trailing comma from last element of a
#       collection, but it's currently not used in favor of terminating
#       each collection with a NULL element or other recognizable non-member
#       of the collection.
#
# Args:
#    (name):   name of destination array of text lines of processes capability information
#    (name):   name of array containing capability data
#    (name):   function name that will process each capability row
walk_cap_rows()
{
    local wcr_output_array_name="$1"
    local -n wcr_caps="$2"
    local wcr_row_user="$3"

    local -i line_count=$(( "${#wcr_caps[*]}" / 4 ))
    local -i line_number=0

    local -i field_count=0
    local -a wcr_row

    local val
    for val in "${wcr_caps[@]}"; do
        wcr_row+=( "$val" )
        if (( ++field_count == 4 )); then
           "$wcr_row_user" "$wcr_output_array_name" "wcr_row" $(( ++line_number == line_count ))

           field_count=0
           wcr_row=()
        fi
    done
}


# Callback function for walk_cap_rows() that generates enum elements
#
# Args
#    (name):    name of array to which output is added
#    (name):    name of array containing row data
#    (boolean): 1 if at last line, 0 otherwise.  Flag indicating whether
#               the line might be terminated with a comma
code_enum()
{
    local ce_caps_name="$1"
    local ce_enum_name="${2:-generic}"
    local ce_enum_prefix="${3}"

    add_enum_line()
    {
        local -n ael_output="$1"
        local -n ael_row="$2"

        local ael_line="   ${ce_enum_prefix}_${ael_row[0]^^},"

        ael_output+=( "$ael_line" )
    }

    local -a ce_output_lines=()

    ce_output_lines=( "" )
    ce_output_lines=( "enum $ce_enum_name {" )
    walk_cap_rows "ce_output_lines" "$ce_caps_name" "add_enum_line"
    ce_output_lines+=( "   ${ce_enum_prefix}_END" )
    ce_output_lines+=( "};" )

    local OIFS="$IFS"
    local IFS=$'\n'

    if [ -n "$OUTPUT_FILE" ]; then
        echo "${ce_output_lines[*]}" >> "$OUTPUT_FILE"
    else
        echo "${ce_output_lines[*]}"
    fi

    IFS="$OIFS"
}

# Callback function for walk_cap_rows() that generates array-initialization code.
# The resulting array includes empty elements to which escape-sequences for each
# capability is stored
#
# Args
#    (name):    name of array to which output is added
#    (name):    name of array containing row data
#    (boolean): 1 if at last line, 0 otherwise.  Flag indicating whether
#               the line might be terminated with a comma.
#               (See note in walk_cap_rows().)
code_caps_array()
{
    local csa_caps_array_name="$1"
    local csa_array_name="${2:-vals}"

    cesa_add_enum_line()
    {
        local -n cael_output="$1"
        local -n cael_row="$2"
        local -i cael_last_line="$3"

        cael_output+=( "   { \"${cael_row[2]}\" }," )
    }

    local -a csa_output_lines=()

    csa_output_lines+=( "" )
    csa_output_lines+=( "TIV ${csa_array_name}[] = {" )

    walk_cap_rows "csa_output_lines" "$csa_caps_array_name" "cesa_add_enum_line"

    # end of array detected by empty code:
    csa_output_lines+=( "   { \"\" }" )
    csa_output_lines+=( "};" )

    local OIFS="$IFS"
    local IFS=$'\n'

    if [ -n "$OUTPUT_FILE" ]; then
        echo "${csa_output_lines[*]}" >> "$OUTPUT_FILE"
    else
        echo "${csa_output_lines[*]}"
    fi

    IFS="$OIFS"
}

# Callback function for walk_cap_rows() that generates an array of description
# strings.  These strings will correspond to the array and enums to allow
# safe indexed access to descriptions.
#
# Args
#    (name):    name of array to which output is added
#    (name):    name of array containing row data
#    (boolean): 1 if at last line, 0 otherwise.  Flag indicating whether
#               the line might be terminated with a comma.
#               (See note in walk_cap_rows().)
code_strings_array()
{
    local csa_caps_array_name="$1"
    local csa_array_name="${2:-vals}"
    local -i csa_field_index="${3:-0}"

    cesa_add_name_line()
    {
        local -n cael_output="$1"
        local -n cael_row="$2"
        local -i cael_last_line="$3"

        local cael_value="${cael_row[${csa_field_index}]}"

        cael_output+=( "   \"${cael_value}\"," )
    }

    local -a csa_output_lines=()

    csa_output_lines+=( "" )
    csa_output_lines+=( "const char * ${csa_array_name}[] = {" )

    walk_cap_rows "csa_output_lines" "$csa_caps_array_name" "cesa_add_name_line"

    # end of array detected by empty code:
    csa_output_lines+=( "   NULL" )
    csa_output_lines+=( "};" )

    local OIFS="$IFS"
    local IFS=$'\n'

    if [ -n "$OUTPUT_FILE" ]; then
        echo "${csa_output_lines[*]}" >> "$OUTPUT_FILE"
    else
        echo "${csa_output_lines[*]}"
    fi

    IFS="$OIFS"
}

# Twice-used code to create a base name from the output file
# for conditional compliling of main function.
#
# Arg
#    (name):   string variable that will contain the generated base name
#
# Returns 0 (success) if base name was set, 1 (failure) if OUTPUT_FILE not set.
get_output_base_name()
{
    local -n gobn_name="$1"

    if [ -n "$OUTPUT_FILE" ]; then
        gobn_name="${OUTPUT_FILE%.*}"
        return 0
    fi

    gobn_name=""
    return 1
}

code_simple_main()
{
    local array_name="${1:-caps_MISSING}"

    local main_start_code
    local main_end_code

    read -r -d '' "main_start_code" <<EOF1
int main(int argc, const char **argv)
{
   if (TIV_setup())
   {
      TIV_set_array(${array_name});
EOF1

read -r -d '' "main_end_code" <<EOF2
      TIV_destroy_array(${array_name});
   }

   return 0;
}
EOF2

    local base_name
    if get_output_base_name "base_name"; then
        echo "#ifdef ${base_name^^}_MAIN" >> "$OUTPUT_FILE"
        echo                              >> "$OUTPUT_FILE"
        echo "#include \"sl_caps.c\""     >> "$OUTPUT_FILE"
        echo                              >> "$OUTPUT_FILE"

        write_text "$main_start_code"

        write_text "      printf(\"Showing capset ${SET_NAME}:\\n\");"
        write_text ""

        if [ "$INCLUDE_NAMES" -eq 1 ]; then
            write_text "      printf(\"\\nTIV elements with names:\\n\");"
            write_text "      TIV_dump_array(${array_name}, names_${SET_NAME});"
            write_text ""
        fi
        if [ "$INCLUDE_DESCRIPTIONS" -eq 1 ]; then
            write_text "      printf(\"\\nTIV elements with descriptions:\\n\");"
            write_text "      TIV_dump_array(${array_name}, desc_${SET_NAME});"
            write_text ""
        fi
        write_text "$main_end_code"
        echo                              >> "$OUTPUT_FILE"
        echo "#endif"                     >> "$OUTPUT_FILE"
    else
        write_text "$main_start_code"
        if [ "$INCLUDE_NAMES" -eq 1 ]; then
            echo "      TIV_dump_array(${array_name}, names_${SET_NAME});"
        fi
        if [ "$INCLUDE_DESCRIPTIONS" -eq 1 ]; then
            echo "      TIV_dump_array(${array_name}, desc_${SET_NAME});"
        fi
        echo
        write_text "$main_end_code"
    fi
}



declare -a CL_LINE_REGEX_PARTS=(
    ^
    \([^[:space:]]+\)     # capture column 1 text (variable) without spaces
    [[:space:]]+          # discard inter-column spaces
    \([^[:space:]]+\)     # capture column 2 text (name) without spaces
    [[:space:]]+          # discard inter-column spaces
    \([^[:space:]]+\)     # capture column 3 text (termcap code)  without spaces
    \(                    # begin final optional group
    [[:space:]]+          # possible match discard inter-column spaces
    \([^[:space:]].+\)    # capture column 4 text (description) remaining text in line (including spaces)
    \)?                   # complete final optional group
)

declare OIFS="$IFS"
declare IFS=''
declare CL_LINE_REGEX="${CL_LINE_REGEX_PARTS[*]}"
IFS="$IFS"

# Used by collect_lines() below to create a temporary file with
# STDIN contents to use in place of INPUT_FILE.
#
# Args
#    (name):    name of file to store STDIN content
#
# Return 0 (success) if any lines read, otherwise 1 if no content read.
collect_stdin_content()
{
    local -n csc_file="$1"
    local csc_temp
    read -r -t 0 "$csc_temp"
    if [ "${#csc_temp}" -gt 0 ]; then
        csc_file="$csc_temp"
        return 0
    fi

    return 1
}

# Read non-commented lines from the file named in INPUT_FILE (as
# requested with the -i option) or STDIN if no input file.
#
# Using a regular expression, $CL_LINE_REGEX, will parse lines into
# four parts which will be added to the array passed to the function.
#
# Args
#    (name):   Name of array to which line contents will be written.
#
# Return: 1 (failure) if no lines can be found, otherwise 0 for success
collect_lines()
{
    local -n pf_lines="$1"
    pf_lines=()

    local -n rec="BASH_REMATCH"

    int_collect_lines()
    {
        local line
        while read -r "line"; do
            if [ "${line:0:1}" != "#" ]; then
                if [[ "$line" =~ $CL_LINE_REGEX ]]; then
                    # ${rec[5]} is not a mistake: ${rec[4]} matched the ${rec[5]}
                    # string following some spaces which are discarded by using
                    # ${rec[5]} instead of ${rec[4]}"
                    pf_lines+=( "${rec[1]}" "${rec[2]}" "${rec[3]}" "${rec[5]}" )
                fi
            fi
        done
    }

    if [ -n "$INPUT_FILE" ]; then
        int_collect_lines < "$INPUT_FILE"
    else
        local file_contents
        if collect_stdin_content "file_contents"; then
            int_collect_lines <<< "$file_contents"
        else
            echo
            echo $'   \e[31;1mNothing to read, neither -i input file nor STDIN.\e[m'
            echo
            return 1
        fi
    fi

    return 0
}

# Create an Emacs "Local Variables" section with a compile-command
# that will compile the source file for executable file for testing.
emacs_local_variables()
{
    local base_name
    if get_output_base_name "base_name"; then
        local format="/* %-25s  */\n"
        local format_continuing="/* %-25s \\*/\n"
        local defstr="${base_name^^}_MAIN"

        write_text "// If using an Emacs editor, the following local"
        write_text "// variables prepares the editor to correctly use"
        write_text "// C-x compile"
        write_text ""

        printf "$format" "Local Variables:"                   >> "$OUTPUT_FILE"
        printf "$format_continuing" "mode: c"                 >> "$OUTPUT_FILE"
        printf "$format_continuing" "compile-command: \"gcc"  >> "$OUTPUT_FILE"
        printf "$format_continuing" "-ggdb -std=c99 -x c"     >> "$OUTPUT_FILE"
        printf "$format_continuing" "-Wall -Werror -pedantic" >> "$OUTPUT_FILE"
        printf "$format_continuing" "-ltinfo"                 >> "$OUTPUT_FILE"
        printf "$format_continuing" "-D${defstr}"             >> "$OUTPUT_FILE"
        printf "$format_continuing" "-fsanitize=address"      >> "$OUTPUT_FILE"
        printf "$format_continuing" "-o ${base_name}"         >> "$OUTPUT_FILE"
        printf "$format" "${OUTPUT_FILE}\""                   >> "$OUTPUT_FILE"
        printf "$format" "End:"                               >> "$OUTPUT_FILE"
    fi
}



if process_command_line_args "$@"; then
    if [ -n "$OUTPUT_FILE" ]; then
        HEADER_FILE_NAME="${OUTPUT_FILE%.*}.h"
    fi
    declare HEADER_GUARD="${HEADER_FILE_NAME^^}"
    HEADER_GUARD="${HEADER_GUARD/./_}"

    declare -a GLINES
    if collect_lines "GLINES"; then
        empty_output_file

        if [ "$OUTPUT_TYPE" -eq "$OUTPUT_TYPE_HEADER" ]; then
            write_text "#ifndef $HEADER_GUARD"
            write_text "#define $HEADER_GUARD"
            write_text ""
        fi

        if [ "$OUTPUT_TYPE" -eq "$OUTPUT_TYPE_CODE" ]; then
            write_text "#include \"${HEADER_FILE_NAME}\""
        else
            write_text "#include <termintel.h>"
            write_text ""
            write_text "extern TIV caps_${SET_NAME}[];"
            if [ "$INCLUDE_NAMES" -ne 0 ]; then
                write_text "extern const char * names_${SET_NAME}[];"
            fi
            if [ "$INCLUDE_DESCRIPTIONS" -ne 0 ]; then
                write_text "extern const char * desc_${SET_NAME}[];"
            fi
        fi

        write_text ""

        if [ "$OUTPUT_TYPE" -gt "$OUTPUT_TYPE_CODE" ]; then
            code_enum "GLINES" "enum_${SET_NAME}" "${SET_NAME}"
        fi

        if [ "$OUTPUT_TYPE" -ne "$OUTPUT_TYPE_HEADER" ]; then
            code_caps_array "GLINES" "caps_${SET_NAME}"
            if [ "$INCLUDE_NAMES" -eq "$OUTPUT_TYPE_CODE" ]; then
                code_strings_array "GLINES" "names_${SET_NAME}" 0
            fi
            if [ "$INCLUDE_DESCRIPTIONS" -eq 1 ]; then
                code_strings_array "GLINES" "desc_${SET_NAME}" 3
            fi
        fi

        write_text ""

        if [ "$OUTPUT_TYPE" -eq "$OUTPUT_TYPE_HEADER" ]; then
            write_text "#endif"
        else
            declare -a string_arrays=()
            code_simple_main "caps_${SET_NAME}"
            write_text ""
            emacs_local_variables
        fi
    else
        show_usage
    fi
fi


