#!/usr/bin/env bash

# Copied from github/cjungmann:bash_patterns.git/sources/small_stuff.sh
# Since we can only capture the output of printf from its stdout, we
# cannot avoid using a subprocess for these functions.
val_from_char() { LC_CTYPE=C; printf '%d' "'$1"; }
char_from_val() { printf $(printf "\\%03o" "$1"); }

# An en-dash is used when a word in a description
# must be broken.
declare en_dash_char="‐"
ends_with_en-dash() { [ "${1: -1:1}" == "$en_dash_char" ]; }

declare cap_delim=$'\cp'

reuse_line() { printf $'\e[1G\eK'; }
to_continue()
{
    printf "%s%s%s " $'\e[32;1m' "Press any key to continue" $'\e[m'
    read -n1
    echo
}

# Convert instances of '\E' to \033 in a string to render the
# escape sequence useable.
#
# Arg
#    (name):   Name of variable to transform
restore_escapes()
{
    local -n rs_string="$1"
    local re_esc=$'\033'
    rs_string="${rs_string//\\E/${re_esc}}"
}

# Populate an array with the complete set of terminfo variable names
# from /usr/share/include/term.h
#
# Args
#   (name);    name of array in which to store names found
#              There will be two elements per row, the capability
#              name and the associated data type(B for bool, N for
#              number, or S for string).
#
# Returns
#   0 for NO Error (success), 1 for failure (file not found)
get_names_from_term_h()
{
    local -n gtn_variables="$1"

    local fpath="/usr/include/term.h"
    if [ -f "$fpath" ]; then
        echo "Found '$fpath'"
        local re=^#define[[:space:]]+\([^\ ]+\)[[:space:]]+CUR[[:space:]]\([^\[]+\)

        local gtn_line
        local -i row_count=0
        while read -r "gtn_line"; do
            if [[ "$gtn_line" =~ $re ]]; then
                gtn_variables+=( "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" )
                (( ++row_count ))

                reuse_line
                printf "%d names" "$row_count"
            fi
        done < "$fpath"
    else
        echo "Failed to find '$fpath'"
    fi

    reuse_line
    printf "Finished collecting %d names from term.h\n" "$row_count"
}

### Set of four regular expressions that are used in function
### get_names_from_terminfo_man()
declare re_ti_head_arr=(
    ^
    [[:space:]]+
    'Variable'
    [[:space:]]+
    'Cap-'
    [[:space:]]+
    'TCap'
    [[:space:]]+
    'Description'
    $
)

declare re_ti_subhead_arr=(
    ^
    [[:space:]]+
    \([^[:space:]]+\)   # capture group's command type (Boolean, Numeric, or String)
    [[:space:]]+
    'name'
    [[:space:]]+
    'Code'
    $
)

declare re_ti_capability_arr=(
    ^
    [[:space:]]+
    \([^[:space:]]+\)       # capture the variable name
    [[:space:]]\{2,\}       # match at least 2 spaces (to distinguish from normal string
    \([^[:space:]]+\)       # capture cap name
    [[:space:]]\{2,\}       # match at least 2 spaces
    \([^[:space:]]\{2\}\)   # capture tcap code (exactly 2 spaces)
    [[:space:]]\{2,\}       # match at least 2 spaces
    \(.*\)                  # capture description
    $
)

declare re_ti_extra_desc_arr=(
    ^
    [[:space:]]\{30,\}
    \(.*\)
    $
)

# Function adds an entry to an associated array of terminal capabilities
#
# This is meant to be a reference array of values to populate a
#
# The second parameter will be used as the index of the associated array,
# the third, fourth, and fifth parameters will be concatenated with the
# values separated by the global variable **cap_delim**
#
# Args
#    (name)    name of associated array
#    (string)  capability name (as defined in term.h and terminfo(5)
#    (string)  terminfo capability
#    (string)  termcap capability code
#    (string)  description
save_terminfo_capability()
{
    local -n stc_array="$1"
    local vname="$2"
    local cname="$3"
    local ccode="$4"
    local desc="$5"

    local -a val=( "$cname" "$ccode" "$desc" )

    local OIFS="$IFS"
    local IFS="$cap_delim"

    stc_array["$vname"]="${val[*]}"

    IFS="$OIFS"
}

# Create associative array indexing variable names with
# capability names, codes, and descriptions.
# 
# Parses contents of terminfo(5) for terminfo variables
#
# Args
#   (name)   name of associative array to receive data
get_names_from_terminfo_man()
{
    local -n gnftm_names="$1"

    local OIFS="$IFS"
    local IFS=''

    # concatenate regexes
    local re_ti_head="${re_ti_head_arr[*]}"
    local re_ti_subhead="${re_ti_subhead_arr[*]}"
    local re_ti_capability="${re_ti_capability_arr[*]}"
    local re_ti_extra_desc="${re_ti_extra_desc_arr[*]}"

    IFS="$OIFS"

    # Line types are:
    #   0  not interesting
    #   1  head                    (marks beginning of section of capabilities)
    #   2  subhead                 (below head, identifies capability type
    #   3  capability start        (first line of capability definition)
    local -i line_type=0

    local p_gtype p_vname p_cname p_ccode p_desc

    local line
    local -i cap_count=0
    while IFS= read -r "line"; do
        if [ "$line_type" -eq 0 ]; then
            if [[ "$line" =~ $re_ti_head ]]; then
                line_type=1
            fi
        elif [ "$line_type" -eq 1 ]; then
            if [[ "$line" =~ $re_ti_subhead ]]; then
                p_gtype="${BASH_REMATCH[1]}"
                line_type=2
            else
                # We thought previous line was a head line, but if it is not
                # followed by a subhead line, it must not have been a head line.
                line_type=0
            fi
        elif [ "$line_type" -ge 2 ]; then
            if [[ "$line" =~ $re_ti_capability ]]; then
                line_type=3
                if [ -n "$p_vname" ]; then
                    save_terminfo_capability \
                        "gnftm_names" \
                        "$p_vname" \
                        "$p_cname" \
                        "$p_ccode" \
                        "$p_desc"
                fi
                p_vname="${BASH_REMATCH[1]}"
                p_cname="${BASH_REMATCH[2]}"
                p_ccode="${BASH_REMATCH[3]}"
                p_desc="${BASH_REMATCH[4]}"

                reuse_line
                printf "Capability name %3d: %s" $(( ++cap_count )) "$p_vname"
            elif [[ "$line" =~ $re_ti_extra_desc ]]; then
                if [ "${p_desc: -1:1}" == "$en_dash_char" ]; then
                    p_desc="${p_desc:0: -1}${BASH_REMATCH[1]}"
                else
                    p_desc="$p_desc ${BASH_REMATCH[1]}"
                fi
            elif [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]\*$ ]]; then
                if [ "$line_type" -eq 2 ]; then
                    # ignoring blank line after subhead
                    line_type=3
                fi
            else
                # falling out of a variables section"
                line_type=0
            fi
        fi
    done < <( man -P cat 5 terminfo )

    # Save capability-in-progress:
    if [ -n "$p_vname" ]; then
        save_terminfo_capability \
            "gnftm_names" \
            "$p_vname" \
            "$p_cname" \
            "$p_ccode" \
            "$p_desc"
    fi
    printf "\n"
}

# Combine capability information from different sources into a
# single reference we'll use in this script
#
# Args
#   (name):    Name of array into which the final form is saved
#   (name):    Array name of data (name and data type) gleaned from
#              /usr/include/term.h.
#   (name):    Array name of data (name, terminfo name, termcap code,
#              and description) gleaned from manpage terminfo(5).
#   (name):    Name of associative array connecting the terminfo name
#              to the escape sequence for that name as found in
#              command *infocmp*.
consolidate_terminfo_data()
{
    local -n ctd_return="$1"
    local -n ctd_var_ninfo="$2"   # two-dimensional array
    local -n ctd_cap_names="$3"
    local -n ctd_sequences="$4"

    local OIFS="$IFS"
    local IFS

    local caps_pack
    local -a info_arr
    local -a caps_arr
    local cap_name cap_code cap_desc
    local cap_seq
    local vname
    local vtype
    for vname in "${ctd_var_ninfo[@]}"; do
        info_arr+=( "$vname" )
        vname="${info_arr[0]}"
        vtype="${info_arr[1]:0:1}"
        if [ "${#info_arr[*]}" -eq 2 ]; then
            caps_pack="${ctd_cap_names[$vname]}"
            if [ -n "$caps_pack" ]; then
                IFS="$cap_delim"
                caps_arr=( $caps_pack )
                cap_name="${caps_arr[0]}"
                cap_code="${caps_arr[1]}"
                cap_desc="${caps_arr[2]}"
            else
                cap_name=""
                cap_code=""
                cap_desc=""
            fi

            if [ -n "$cap_name" ]; then
                cap_seq="${ctd_sequences[$cap_name]}"
            else
                cap_seq=""
            fi

            # The number of elements added should match the value
            # stored in the TERMDATA_COLUMNS variable just below.
            ctd_return+=(
                "$vtype"
                "$vname"
                "$cap_name"
                "$cap_code"
                "$cap_desc"
                "$cap_seq"
            )

            info_arr=()
        fi
    done
}

# Declare after termdata row creation to simplify coordination
# with the global column count variable:
declare -i TERMDATA_COLUMNS=6

# Also below termdata row creation to allow easy confirmation
# of index name to field contents.
declare -i TNDX_TYPE=0
declare -i TNDX_NAME=1
declare -i TNDX_CNAME=2
declare -i TNDX_CCODE=3
declare -i TNDX_DESC=4
declare -i TNDX_SEQ=5

# Itemize codes from _infocmp_ into an array
#
# Args
#    (name)     name of array to which entries are to be stored
#    (string)   name of terminal emulator
get_cap_entries()
{
    local -n gcl_entries="$1"
    local OIFS="$IFS"
    local IFS=","
    local sline spaces content
    local -a tentries
    local re=^\([[:space:]]*\)\(.*\)
    while IFS= read -r "sline"; do
        if [[ "$sline" =~ $re ]]; then
            spaces="${BASH_REMATCH[1]}"
            content="${BASH_REMATCH[2]}"
            if [ "${#spaces}" -ne 0 ]; then
                content="${content// /}"
                tentries=( $content )
                gcl_entries+=( "${tentries[@]}" )
            fi
        fi
    done < <( infocmp )

    IFS="$OIFS"
}

# Decipher and catalog entire terminfo database for current terminal
#
# Args
#    (name)    associative array in which database will be transcribed
#    (string)  name of terminal type
get_infocmp_array()
{
    local -n gca_values="$1"
    local termname="$2"

    local -a entries
    get_cap_entries "entries" "$termname"

    local OIFS="$IFS"
    local IFS

    local -a parts
    local entry name value

    gca_values=()

    for entry in "${entries[@]}"; do
        # Try two different IFS characters to extra an array
        IFS="="
        parts=( $entry )
        if [ "${#parts[*]}" -lt 2 ]; then
            IFS="#"
            parts=( $entry )
            IFS="="
        fi

        # Treat line as name/value or a flag
        if [ "${#parts[*]}" -eq 2 ]; then
            name="${parts[0]}"
            value="${parts[1]}"
        else
            name="$entry"
            value="1"
        fi

        gca_values["$name"]="$value"
    done

    IFS="$OIFS"
}

##
# Generic search function: returns row if field of row matches value
#
# Args
#   (name)     Name of array to be populated with row values
#   (name)     Name of TERMDATA array from which the search is made
#   (integer)  Index of field to match value
#   (string)   Value to to match in given field
#
# Returns 0 (true) if found, 1 if not found
seek_row_by_field()
{
    local -n srbf_return_row="$1"
    local -n srbf_termdata="$2"
    local -i srbf_field_index="$3"
    local srbf_value="$4"

    local -a srbf_row
    local el
    for el in "${srbf_termdata[@]}"; do
        srbf_row+=( "$el" )
        if [ "${#srbf_row[*]}" -eq "$TERMDATA_COLUMNS" ]; then
            if [ "${srbf_row[$srbf_field_index]}" == "$srbf_value" ]; then
                srbf_return_row=( "${srbf_row[@]}" )
                return 0
            fi
            srbf_row=()
        fi
    done

    return 1
}

# Use seek_row_by_field to find a sequence for capability with given
# termcap code.
#
# Use this function to find an sequence to submit for specific
# purposes.
#
# Args
#   (name)   Name of variable to which result is copied
#   (name)   Name of TERMDATA array
#   (string) Value to match against the field value.
#
# Returns 0 (Success) if found, 1 (Error) if not found
seek_sequence_by_ccode()
{
    local -n ssbc_sequence="$1"
    local ssbc_termdata_name="$2"
    local ssbc_capname="$3"

    local -a ssbc_row
    if seek_row_by_field "ssbc_row" "$ssbc_termdata_name" "$TNDX_CCODE" "$ssbc_capname"; then
        ssbc_sequence="${ssbc_row[$TNDX_SEQ]}"
        return 0
    fi
    return 1
}

# Use seek_row_by_field to find a termcap code for capability with
# given sequence.
#
# Use this function to find the capability name for a given keyboard
# escape sequence.
#
# Args
#   (name)   Name of variable to which result is copied
#   (name)   Name of TERMDATA array
#   (string) Value to match against the field value.
#
# Returns 0 (Success) if found, 1 (Error) if not found
seek_cap_name_by_sequence()
{
    local -n scnbs_name="$1"
    local scnbs_termdata_name="$2"
    local scnbs_sequence="$3"

    local -a scnbs_row
    if seek_row_by_field "scnbs_row" "$scnbs_termdata_name" "$TNDX_SEQ" "$scnbd_sequence"; then
        scnbd_name="${scnbs_row[$TNDX_NAME]}"
        return 0
    fi
    return 1
}

####################
### User Options ###
####################

# The number at position 3 of the following function names
# are there to define the option order in the user display.
# The number will be parsed out (along with the arr_style or
# agg_filter prefix) to become the label of the option on
# the user display.

agg_style_01_cap_names_only()
{
    local -n dar_row="$1"
    printf $'%-25s   %-8s   %-2s\n' \
           "${dar_row[$TNDX_NAME]}" \
           "${dar_row[$TNDX_CNAME]}" \
           "${dar_row[$TNDX_CCODE]}"
}

agg_style_02_cap_names_with_descriptions()
{
    local -n dar_row="$1"
    printf $'%-25s   %-8s   %-2s   \e[32;1m%s\e[m\n' \
           "${dar_row[$TNDX_NAME]}" \
           "${dar_row[$TNDX_CNAME]}" \
           "${dar_row[$TNDX_CCODE]}" \
           "${dar_row[$TNDX_DESC]}"
}

agg_style_03_cap_names_with_sequences()
{
    local -n dar_row="$1"
    printf $'%-25s   %-8s   %-2s   \e[32;1m%s\e[m\n' \
           "${dar_row[$TNDX_NAME]}" \
           "${dar_row[$TNDX_CNAME]}" \
           "${dar_row[$TNDX_CCODE]}" \
           "${dar_row[$TNDX_SEQ]}"
}

agg_style_04_cap_names_with_descriptions_and_sequences()
{
    local -n dar_row="$1"
    printf $'%-25s   %-8s   %-2s   \e[32;1m%s\e[m   %s\n' \
           "${dar_row[$TNDX_NAME]}" \
           "${dar_row[$TNDX_CNAME]}" \
           "${dar_row[$TNDX_CCODE]}" \
           "${dar_row[$TNDX_DESC]}" \
           "${dar_row[$TNDX_SEQ]}"
}

agg_style_05_cap_checklist()
{
    local -n dar_row="$1"
    printf $'[ ] %-25s   %-8s   %-2s   \e[32;1m%s\e[m\n' \
           "${dar_row[$TNDX_NAME]}" \
           "${dar_row[$TNDX_CNAME]}" \
           "${dar_row[$TNDX_CCODE]}" \
           "${dar_row[$TNDX_SEQ]}"
}

agg_filter_01_show_all()
{
    [ 1 -eq 1 ]
}

agg_filter_02_key_names()
{
    local -n afk_row="$1"
    [[ "${afk_row[$TNDX_NAME]}" =~ ^key_ ]]
}

agg_filter_03_modes()
{
    local -n afk_row="$1"
    [[ "${afk_row[$TNDX_NAME]}" =~ _mode$ ]] || [[ "${afk_row[$TNDX_DESC]}" =~ mode ]]
}

agg_filter_04_non_key_or_mode_names()
{
    local -n afk_row="$1"
    local val="${afk_row[$TNDX_NAME]}"
    ! ( [[ "$val" =~ ^key_ ]] \
        || [[ "$val" =~ _mode$ ]] \
        || [[ "${afk_row[$TNDX_DESC]}" =~ mode ]]
        )
}

agg_filter_05_only_boolean()
{
    local -n afk_row="$1"
    [ "${afk_row[$TNDX_TYPE]}" == "B" ]
}

agg_filter_06_only_numeric()
{
    local -n afk_row="$1"
    [ "${afk_row[$TNDX_TYPE]}" == "N" ]
}

agg_filter_06_only_string()
{
    local -n afk_row="$1"
    [ "${afk_row[$TNDX_TYPE]}" == "S" ]
}


# Collect function names from which a user selects filters and styles.
#
# Scans script functions for names that begin with "agg_filter_" or
# and "agg_style_".  The "agg_filter_" functions are used to test each
# capability to see if it should be included in a list, the "agg_style_"
# functions are called for each capability that passes the filter to
# display the capability.
#
# New filters or display functions can be added according to need.  If
# the function name conforms to the convention, it will be included in
# the dialog by which the user selects filters and styles.
#
# Args
#   (name):    name of array in which filter function names is returned
#   (name):    name of array in which style function names is returned
collect_display_options()
{
    local -n guo_filters="$1"
    local -n guo_styles="$2"

    local line
    local re=agg_\([^_]+\)_\(.+\)
    while read -r "line"; do
        if [[ "$line" =~ $re ]]; then
            case "${BASH_REMATCH[1]}" in
                 "style" )  guo_styles+=( "${BASH_REMATCH[0]}" ) ;;
                 "filter" ) guo_filters+=( "${BASH_REMATCH[0]}" );;
            esac
        fi
    done < <( declare -F )
}



# The simple function that delivers the user's requested output.
#
# Args
#   (name)    name of array of capabilities records
#   (string)  name of function to use for filtering records
#   (string)  name of function to use for displaying records
use_agg_data()
{
    local -n uad_data="$1"
    local uad_row_filter="$2"
    local uad_row_style="$3"

    # Using *count* to pick-off 5 array elements at a
    # time while constructing a single capability row.
    local -i count=0

    local -a uad_row

    local el
    for el in "${uad_data[@]}"; do
        uad_row+=( "$el" )
        (( ++count ))
        if [ "$count" -eq "$TERMDATA_COLUMNS" ]; then
            if [ "$ONLY_SUPPORTED" -eq 0 ] || [ -n "${uad_row[$TNDX_SEQ]}" ]; then
                if [ -z "$uad_row_filter" ] || "$uad_row_filter" "uad_row"; then
                    "$uad_row_style" "uad_row"
                fi
            fi
            uad_row=()
            count=0
        fi
    done
}

create_termdata_array()
{
    local cad_entries_name="$1"

    # Most abundant source of names: term.h
    declare -a tinfo
    get_names_from_term_h "tinfo"

    # Second source: fewer, but more detailed, capability definitions
    local -A cnames=()
    get_names_from_terminfo_man "cnames"

    # Use infocmp command to get terminal commands for the current terminal:
    # Associated array for look-ups by terminfo name
    local -A isequences
    get_infocmp_array "isequences" "$termname"

    consolidate_terminfo_data "$cad_entries_name" "tinfo" "cnames" "isequences"
}

# Returns a terminal escape sequence for a given value, determined by $3.
#
# Args
#    (name)    name of variable to which the result is written
#    (name)    name of prepared termdata array
#    (integer) column index of submitted value
#    (string)  value with which to search termdata
#
# Returns 0 if found, return reference $1 will contain sequence
#         1 if not found, return reference $1 will be empty
get_termdata_sequence()
{
    local -n gts_sequence="$1"
    local -n gts_termdata="$2"
    local -i column_ndx="$3"
    local search_val="$4"

    gts_sequence=

    # --- begin early-termination error-checking

    # Assert that capabilities array has data
    if [ "${#gts_termdata[*]}" -lt "$TERMDATA_COLUMNS" ]; then
        echo "Terminfo data array not populated." >&2
        return 1
    fi

    # Assert valid field index
    if (( column_ndx < 0 || column_ndx > 2 )); then
        echo "get_termdata_sequence index out-of-range" >&2
        return 1
    fi

    # --- end of early-termination testing

    local -a gts_row=()
    local gts_el
    local esc_char=$'\e'
    for gts_el in "${gts_termdata[@]}"; do
        gts_row+=( "${gts_el}" )
        if [ "${#gts_row[@]}" -eq "$TERMDATA_COLUMNS" ]; then
            if [ "${gts_row[$column_ndx]}" == "$search_val" ]; then
                gts_sequence="${gts_row[$TNDX_SEQ]}"
                gts_sequence="${gts_sequence//\\E/${esc_char}}"
                return 0
            fi

            gts_row=()
        fi
    done

    return 1
}

# Writes to screen the visual part of options user interfaces
#
#
# Args
#    (name)    name of integer variable indicating the index of the selected element
#    (name)    name of array of function names that execute the user's choice
#    (string)  Character from which numerated options will be labelled.  A '+'
#              suffix will make keyed selection to be case-insensitive.
display_user_pref()
{
    local -i dup_ndx="$1"
    local -n dup_array="$2"
    local base_label="$3"

    local -i base_label_value=$( val_from_char "$base_label" )

    local func label ndx_check name
    local -i ndx=0
    local re=^[^_]+_[^_]+_\([[:digit:]]+_\)?\(.*\)
    for func in "${dup_array[@]}"; do
        if [[ "$func" =~ $re ]]; then
            name="${BASH_REMATCH[2]}"
            label=$( char_from_val $(( base_label_value + ndx )) )
            if [ "$ndx" -eq "$dup_ndx" ]; then
                ndx_check="[x]"
            else
                ndx_check="[ ]"
            fi

            printf "%c. %s %s\n" "$label" "$ndx_check" "$name"
        fi
        (( ++ndx ))
    done
}

set_selection_from_key()
{
    local -n ssfk_ndx="$1"
    local -n ssfk_sel_array="$2"
    local ssfk_base_char="$3"
    local ssfk_keyp="$4"

    # A plus (+) suffix request case-insensitive match
    if [ "${ssfk_base_char:1:1}" == "+" ]; then
        ssfk_base_char="${ssfk_base_char,?}"
        ssfk_keyp="${ssfk_keyp,?}"
    fi

    local -i count="${#ssfk_sel_array[*]}"
    local -i val_base=$( val_from_char "${ssfk_base_char:0:1}" )
    local -i val_keyp=$( val_from_char "$ssfk_keyp" )
    local -i val_diff=$(( val_keyp - val_base ))

    if (( val_diff >= 0 && val_diff < count )); then
        (( ssfk_ndx = val_diff ))
        return 0
    else
        return 1
    fi
}

get_user_prefs()
{
    local -n gup_filter_ndx="$1"
    local -n gup_filter_funcs="$3"
    local gup_filter_base="A+"

    local -n gup_style_ndx="$2"
    local -n gup_style_funcs="$4"
    local gup_style_base="1"

    echo "Select the desired set of capabilities:"
    display_user_pref "$gup_filter_ndx" "gup_filter_funcs" "$gup_filter_base"
    echo
    echo "Select what to show for each capability:"
    display_user_pref "$gup_style_ndx" "gup_style_funcs" "$gup_style_base"
    echo

    echo -n "'?' "
    if [ "$ONLY_SUPPORTED" -eq 1 ]; then
        echo -n "[X]"
    else
        echo -n "[ ]"
    fi
    echo " Filter out unsupported capabilities."
    echo

    local keyp
    echo -n "Type a letter, number, or '?' to choose options, ENTER to view , or 'q' to exit."
    read -srN1 "keyp"
    if [ "$keyp" == $'\n' ]; then
        return 0
    elif [[ "Qq" =~ $keyp ]]; then
        return 2
    elif [ "$keyp" == '?' ]; then
        [ "$ONLY_SUPPORTED" -eq 1 ]
        ONLY_SUPPORTED="$?"
    elif set_selection_from_key "gup_filter_ndx" "gup_filter_funcs" "$gup_filter_base" "$keyp"; then
        return 1
    elif set_selection_from_key "gup_style_ndx" "gup_style_funcs" "$gup_style_base" "$keyp"; then
        return 1
    fi

    return 1
}

start_user_dialog()
{
    local -a disp_filters disp_styles
    local -i filter_ndx=0 style_ndx=0
    local -i user_pref
    collect_display_options "disp_filters" "disp_styles"

    while [ 1 -eq 1 ]; do
        echo -n "$TI_CLEAR_SCREEN"

        get_user_prefs "filter_ndx" "style_ndx" "disp_filters" "disp_styles"
        user_pref="$?"

        if [ "$user_pref" -eq 0 ]; then
            echo "$TI_CLEAR_SCREEN"
            less -r < <( use_agg_data "TERMDATA" "${disp_filters[$filter_ndx]}" "${disp_styles[$style_ndx]}" )
            echo "$TI_CLEAR_SCREEN"
        elif [ "$user_pref" -eq 1 ]; then
             continue
        else
            # User typed 'q' to quit
            break
        fi
    done
    echo
}

declare TI_CLEAR_SCREEN
declare TI_ENTER_CA_MODE
declare TI_EXIT_CA_MODE
declare TI_ENTER_KEYPAD_MODE
declare TI_EXIT_KEYPAD_MODE
declare TI_CURSOR_MOVE_HOME
declare TI_CURSOR_UP_MANY
declare TI_CURSOR_DOWN_MANY

declare -a TI_CMDS=(
    "TI_CLEAR_SCREEN"            "cl"
    "TI_ENTER_CA_MODE"           "ti"
    "TI_EXIT_CA_MODE"            "te"
    "TI_ENTER_KEYPAD_MODE"       "ks"
    "TI_EXIT_KEYPAD_MODE"        "ke"
    "TI_CURSOR_MOVE_HOME"        "ho"
    "TI_CURSOR_MOVE_UP_MANY"     "UP"
    "TI_CURSOR_MOVE_DOWN_MANY"   "DO"
)

populate_ti_commands()
{
    local ptc_termdata_name="$1"

    local -a row
    local ptc_sequence
    local el
    for el in "${TI_CMDS[@]}"; do
        row+=( "$el" )
        if [ "${#row[*]}" -eq 2 ]; then
            echo "Processing row: ${row[*]}" >&2
            if seek_sequence_by_ccode "ptc_sequence" "$ptc_termdata_name" "${row[1]}"; then
                echo "For ${row[1]}, modifying sequence '$ptc_sequence'"
                restore_escapes "ptc_sequence"
                local -n vname="${row[0]}"
                vname="$ptc_sequence"
            fi
            row=()
        fi
    done
}

# Dummy test should mirror problem code in **use_agg_data**
test()
{
    # local filter="agg_filter_non_key_names"
    local filter="agg_filter_key_names"
    local -a fake_row=( "key_f6" "kf6" "k6" "F6 function key" "\EBogus" )
    if [ -z "$filter" ] || "$filter" "fake_row"; then
        echo "It was true"
    else
        echo "It was FALSE"
    fi
}


# Global flag for primary filter, whether to show# unsupported
# capabilities (those without defined escape sequences)
declare -i ONLY_SUPPORTED=1

# Make global TERMDATA resource for display but also to provide
# info for our own terminal use.
declare -a TERMDATA
create_termdata_array "TERMDATA"

populate_ti_commands "TERMDATA"

echo "$TI_CLEAR_SCREEN"

start_user_dialog






