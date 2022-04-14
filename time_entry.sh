#!/usr/bin/env bash

if [ -z $REDMINE_KEY ]
then
    echo "REDMINE_KEY is missing, add it by running: export REDMINE_KEY=xxx"
    exit 1
fi

ISSUE_ID=
DAYS_COUNT=
URL=
DATE=$(date +"%F")

while getopts d:i:u: opt; do
    case $opt in
        d)
            DAYS_COUNT=$OPTARG
        ;;
        i)
            ISSUE_ID=$OPTARG
        ;;
        u)
            URL=$OPTARG
        ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
        ;;
    esac
done

if [ -z $ISSUE_ID ]
then
    echo "ISSUE_ID is missing, pass the option -i xxxx"
    exit 1
fi

if [ -z $URL ]
then
    echo "URL is missing, pass the option -u https://xxxx"
    exit 1
fi
get_time_entry_1() {
    echo '{"time_entry": {"activity_id": 9,"issue_id": '$ISSUE_ID', "hours": 7.5, "comments": "Development activities","spent_on": "'$1'"}}'
}

get_time_entry_2() {
    echo '{"time_entry": {"activity_id": 10,"issue_id": '$ISSUE_ID', "hours": 0.5, "comments": "Daily Stand Up", "spent_on": "'$1'"}}'
}

get_entries() {
    curl -s -S \
    -H "X-Redmine-API-Key: $REDMINE_KEY" \
    -H "Content-Type: application/json" \
    -X GET "$URL/time_entries.json?spent_on=$1" \
    | python -c "import sys, json; print json.load(sys.stdin)['total_count']"
}

create_entries() {
    DAY_OF_WEEK_NUMBER=$(date -jf "%F" $1 "+%u")
    DAY_OF_WEEK_NAME=$(date -jf "%F" $1 "+%A")
    ENTRIES=$(get_entries $1)
    
    # do not add entries if already exists
    if [ $ENTRIES -lt 1 ]
    then
        # dont add time entries on weekends
        if [[ $DAY_OF_WEEK_NUMBER -gt 5 ]]; then
            echo "You dont work on weekends, do you? Skipping time entry creation for $1 $DAY_OF_WEEK_NAME"
        else
            TIME_ENTRY1=$(get_time_entry_1 $1)
            TIME_ENTRY2=$(get_time_entry_2 $1)
            
            R_1=$(curl -s -S -d "$TIME_ENTRY1" \
                -H "X-Redmine-API-Key: $REDMINE_KEY" \
                -H "Content-Type: application/json" \
                -X POST "$URL/time_entries.json" \
            | python -c "import sys, json; print json.load(sys.stdin)['time_entry']['id']")
            
            if [ ! -z $R_1 ]
            then
                echo "created entry 1 $1 $DAY_OF_WEEK_NAME, id: $R_1"
            else
                echo "failed to create entry 1 $1 $DAY_OF_WEEK_NAME"
            fi
            
            R_2=$(curl -s -S -d "$TIME_ENTRY2" \
                -H "X-Redmine-API-Key: $REDMINE_KEY" \
                -H "Content-Type: application/json" \
                -X POST "$URL/time_entries.json" \
            | python -c "import sys, json; print json.load(sys.stdin)['time_entry']['id']")
            
            if [ ! -z $R_2 ]
            then
                echo "created entry 2 $1 $DAY_OF_WEEK_NAME, id: $R_2"
            else
                echo "failed to create entry 2 $1 $DAY_OF_WEEK_NAME"
            fi
        fi
    else
        echo "$1 already has entries, skipping $DAY_OF_WEEK_NAME"
    fi
}

if [ ! -z $DAYS_COUNT ]
then
    if [ $DAYS_COUNT -gt 0 ]; then
        SIGN="+"
    fi
    
    if [ $DAYS_COUNT -lt 0 ]; then
        SIGN="-"
    fi
    for (( i=0; i<${DAYS_COUNT#-}; i++ ))
    do
        CURRENT_DATE="$(DATE -v${SIGN}${i}d +"%F")"
        create_entries $CURRENT_DATE
    done
else
    create_entries $DATE
fi