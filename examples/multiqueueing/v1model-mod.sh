#!/bin/bash

input_file="v1model.p4"

# downloads script
wget https://raw.githubusercontent.com/p4lang/p4c/main/p4include/v1model.p4 -O $input_file

# adds the queueing standard_metadata fields

# check if priority needs to be added
if ! grep -q "@alias(\"intrinsic_metadata.priority\")" "$input_file"; then
    # If it doesn't exist, insert it before the closing brace
    sed -i '/struct standard_metadata_t {/,/}/{ 
        /}/i\
    // set packet priority\
    @alias("intrinsic_metadata.priority")\
    bit<3> priority;
    }' "$input_file"
fi

# check if qid needs to be added 
if ! grep -q "@alias(\"queueing_metadata.qid\")" "$input_file"; then
    # If it doesn't exist, insert it before the closing brace
    sed -i '/struct standard_metadata_t {/,/}/{ 
        /}/i\
    // queue used info at egress\
    @alias("queueing_metadata.qid")\
    bit<5> qid;
    }' "$input_file"
fi


# copies it to: /usr/local/share/p4c/p4include/
dst_folder="/usr/local/share/p4c/p4include/"

read -p "Do you want to copy v1model.p4 to $dst_folder? (y/N) " response

if [[ "$response" == "y" || "$response" == "Y" ]]; then
    sudo cp "$input_file" "$dst_folder"
    echo "File copied to $dst_folder"
else
    echo "File v1model.p4 not copied to $dst_folder."
fi
