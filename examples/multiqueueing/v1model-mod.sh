#!/bin/bash

input_file="v1model.p4"

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