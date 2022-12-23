#!/bin/bash

SEED=1234
TOTAL_KEYS=2000000

# Note: Not varying number of keys in RocksDB benchmark

#for TOTAL_KEYS in 1000000 2000000 5000000 10000000
BASE_PATH=scalability
mkdir -p $BASE_PATH

for NUM_THREADS in 1 4 8 16 32
do
    let KEYS_PER_THREAD=$(($TOTAL_KEYS / $NUM_THREADS))

    for KEY_SIZE in 8 16 32
    do

        printf '%s\t%s\n' "KEYS: " $TOTAL_KEYS \
                "THREADS: " $NUM_THREADS \
                "KEYS PER THREAD: " $KEYS_PER_THREAD \
                "KEY SIZE: " $KEY_SIZE |
        expand -t 20

        if [[ $TOTAL_KEYS -eq 2000000 ]] && [[ $NUM_THREADS -eq 32 ]] && [[ $KEY_SIZE -eq 8 ]]; then
            echo "Running benchmark to test for variance in experiments ..."

            VAR_PATH=$BASE_PATH"/variance"
            mkdir -p $VAR_PATH

            for i in {1..10}
            do
                rm DBs/*

                perf stat -o $VAR_PATH"/perf_stat_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads_run_"$i".txt" \
                    ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=$KEY_SIZE -value_size=100 -num=$KEYS_PER_THREAD -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                        >$VAR_PATH"/perf_stat_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads_run_"$i".log" 2>&1;

                perf record -g -o $BASE_PATH"/perf_record_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads_run_"$i".data" \
                    ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=$KEY_SIZE -value_size=100 -num=$KEYS_PER_THREAD -compression_type=none -threads=$NUM_THREADS \
                        >$BASE_PATH"/perf_record_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads_run_"$i".log" 2>&1;
            done
        fi

        echo "Running benchmark with perf stat ..."
        rm DBs/*
        perf stat -o $BASE_PATH"/perf_stat_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.txt" \
            ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=$KEY_SIZE -value_size=100 -num=$KEYS_PER_THREAD -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                >$BASE_PATH"/perf_stat_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.log" 2>&1;
        perf stat -o $BASE_PATH"/perf_stat_read_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.txt" \
            ./rocksdb/db_bench -benchmarks=readrandom -use_existing_db=1 -db=DBs -wal_dir=DBs -key_size=$KEY_SIZE -value_size=100 -num=$KEYS_PER_THREAD -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                >$BASE_PATH"/perf_stat_read_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.log" 2>&1;

        echo "Running benchmark with perf record ..."
        rm DBs/*
        perf record -g -o $BASE_PATH"/perf_record_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.data" \
            ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=$KEY_SIZE -value_size=100 -num=$KEYS_PER_THREAD -compression_type=none -threads=$NUM_THREADS \
                >$BASE_PATH"/perf_record_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.log" 2>&1;
        perf record -g -o $BASE_PATH"/perf_record_read_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.data" \
            ./rocksdb/db_bench -benchmarks=readrandom -use_existing_db=1 -db=DBs -wal_dir=DBs -key_size=$KEY_SIZE -value_size=100 -reads=$KEYS_PER_THREAD -compression_type=none -threads=$NUM_THREADS \
                >$BASE_PATH"/perf_record_read_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.log" 2>&1;

        echo -e "Creating flame graphs ...\n"
        perf script -i $BASE_PATH"/perf_record_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.data" | ~/repos/FlameGraph/stackcollapse-perf.pl | \
            ~/repos/FlameGraph/flamegraph.pl > $BASE_PATH"/perf_record_write_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.svg"
        perf script -i $BASE_PATH"/perf_record_read_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.data" | ~/repos/FlameGraph/stackcollapse-perf.pl | \
            ~/repos/FlameGraph/flamegraph.pl > $BASE_PATH"/perf_record_read_"$KEY_SIZE"_keys_"$NUM_THREADS"_threads.svg"

    done
done