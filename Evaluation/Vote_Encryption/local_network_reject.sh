#!/bin/bash

# Command to be executed to reject
command_to_run="fhevm encrypt --node http://localhost:8545 8 0"

# Command to be executed to accept
#command_to_run="fhevm encrypt --node http://localhost:8545 8 1"

# CSV file to store the results
csv_file="execution_times.csv"

# Check if CSV file exists, if not, create it with headers
if [ ! -f $csv_file ]; then
    echo "command,execution_time" > $csv_file
fi

# Perform the command 1000 times
for i in $(seq 1 1000); do
    # Get start time in nanoseconds
    start_time=$(date +%s%N)

    # Execute the command
    eval $command_to_run

    # Get end time in nanoseconds
    end_time=$(date +%s%N)

    # Calculate duration in seconds
    duration=$((($end_time - $start_time)))

    # Append the command and its execution time to the CSV file
    echo "$command_to_run,$duration" >> $csv_file
done

echo "Execution times for '$command_to_run' recorded 1000 times in $csv_file."


