#!/bin/bash

for i in {1..10}; do
  echo "Iteration number $i"

    time ./rocksdb/db_bench -benchmarks=fillseq -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -compression_type=none -num=5000000 -seed=1234 \
    > "overhead/baseline_"$i".txt" 2> "overhead/timing_baseline_"$i".log"

    time perf record ./rocksdb/db_bench -benchmarks=fillseq -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -compression_type=none -num=5000000 -seed=1234 \
        > "overhead/perf_record_"$i".txt" 2> "overhead/timing_perf_record_"$i".log"

    time perf stat ./rocksdb/db_bench -benchmarks=fillseq -use_existing_db=0 -db=DBs -wal_dir=DBs -key_size=16 -value_size=100 -compression_type=none -num=5000000 -seed=1234 \
        > "overhead/perf_stat_"$i".txt" 2> "overhead/timing_perf_stat_"$i".log"
done