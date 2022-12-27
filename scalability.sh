#!/bin/bash

SEED=1234

for TOTAL_KEYS in 1000000 2000000 5000000
do
    BASE_PATH=scalability/$TOTAL_KEYS"_keys"
    mkdir -p $BASE_PATH

    for NUM_THREADS in 1 4 8 16 32
    do

        printf '%s\t%s\n' "KEYS: " $TOTAL_KEYS \
                "THREADS: " $NUM_THREADS |
        expand -t 20

        if [[ $TOTAL_KEYS -eq 1000000 ]] && [[ $NUM_THREADS -eq 1 ]]; then
            echo "Running benchmark to test for variance in experiments ..."

            VAR_PATH=$BASE_PATH"/variance"
            mkdir -p $VAR_PATH

            for i in {1..10}
            do
                rm DBs/*

                perf stat -o $VAR_PATH"/perf_stat_write_random_"$NUM_THREADS"_threads_run_"$i".txt" \
                    ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -num=$TOTAL_KEYS -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                        >$VAR_PATH"/perf_stat_write_random_"$NUM_THREADS"_threads_run_"$i".log" 2>&1;

                perf record -g -o $BASE_PATH"/perf_record_write_random_"$NUM_THREADS"_threads_run_"$i".data" \
                    ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -num=$TOTAL_KEYS -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                        >$BASE_PATH"/perf_record_write_random_"$NUM_THREADS"_threads_run_"$i".log" 2>&1;
            done
        fi

        echo "Running benchmark with perf stat ..."
        rm DBs/*
        perf stat -o $BASE_PATH"/perf_stat_write_random_"$NUM_THREADS"_threads.txt" \
            ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -num=$TOTAL_KEYS -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                >$BASE_PATH"/perf_stat_write_random_"$NUM_THREADS"_threads.log" 2>&1;
        perf stat -o $BASE_PATH"/perf_stat_write_seq_"$NUM_THREADS"_threads.txt" \
            ./rocksdb/db_bench -benchmarks=fillseq -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -num=$TOTAL_KEYS -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                >$BASE_PATH"/perf_stat_write_seq_"$NUM_THREADS"_threads.log" 2>&1;

        echo "Running benchmark with perf record ..."
        rm DBs/*
        perf record -g -o $BASE_PATH"/perf_record_write_random_"$NUM_THREADS"_threads.data" \
            ./rocksdb/db_bench -benchmarks=fillrandom -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -num=$TOTAL_KEYS -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                >$BASE_PATH"/perf_record_write_random_"$NUM_THREADS"_threads.log" 2>&1;
        perf record -g -o $BASE_PATH"/perf_record_write_seq_"$NUM_THREADS"_threads.data" \
            ./rocksdb/db_bench -benchmarks=fillseq -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -num=$TOTAL_KEYS -compression_type=none -threads=$NUM_THREADS -seed=$SEED \
                >$BASE_PATH"/perf_record_write_seq_"$NUM_THREADS"_threads.log" 2>&1;

        echo -e "Creating flame graphs ...\n"
        perf script -i $BASE_PATH"/perf_record_write_random_"$NUM_THREADS"_threads.data" | ~/repos/FlameGraph/stackcollapse-perf.pl | \
            ~/repos/FlameGraph/flamegraph.pl > $BASE_PATH"/perf_record_write_random_"$NUM_THREADS"_threads.svg"
        perf script -i $BASE_PATH"/perf_record_write_seq_"$NUM_THREADS"_threads.data" | ~/repos/FlameGraph/stackcollapse-perf.pl | \
            ~/repos/FlameGraph/flamegraph.pl > $BASE_PATH"/perf_record_write_seq_"$NUM_THREADS"_threads.svg"

    done
done