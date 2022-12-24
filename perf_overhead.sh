#!/bin/sh

time ./rocksdb/db_bench -benchmarks=fillseq -compression_type=none -num=4000000

time perf record ./rocksdb/db_bench -benchmarks=fillseq -compression_type=none -num=4000000

time perf stat ./rocksdb/db_bench -benchmarks=fillseq -compression_type=none -num=4000000