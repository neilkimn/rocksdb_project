from statistics import mean, stdev
import re

def calculate_mean_stddev(numbers):
  return mean(numbers), stdev(numbers)

def extract_time(time_string):
  time_parts = re.search(r"(\d+)m(\d+\.\d+)s", time_string).groups()
  minutes = int(time_parts[0])
  seconds = float(time_parts[1])

  time_in_seconds = minutes * 60 + seconds
  return time_in_seconds

with open("overhead/overhead.txt", "r") as f:
    lines = f.readlines()
    lines = [l.strip() for l in lines if "real" in l]

baseline = list()
perf_record = list()
perf_stat = list()

for idx in range(0,len(lines),3):
    baseline.append(extract_time(lines[idx]))
    perf_record.append(extract_time(lines[idx+1]))
    perf_stat.append(extract_time(lines[idx+2]))

m, s = calculate_mean_stddev(baseline)
print("Baseline")
print(f"\tMean: {m}")
print(f"\tStandard deviation: {s}")

m, s = calculate_mean_stddev(perf_record)
print("perf record")
print(f"\tMean: {m}")
print(f"\tStandard deviation: {s}")

m, s = calculate_mean_stddev(perf_stat)
print("perf stat")
print(f"\tMean: {m}")
print(f"\tStandard deviation: {s}")