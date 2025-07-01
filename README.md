# ActiveStorage Performance Test

## 📌 Purpose

This repository was created to benchmark and evaluate the **performance of Active Storage in Rails** when attaching a large number of files (images or documents) to a single record.

The goal is to explore and improve the **efficiency of attaching many files** using various strategies such as:
- Batch attaching files instead of one by one.
- Using transactions for performance gains.
- Logging and measuring how attach time scales as the number of files increases.

## 🧪 Problem Statement

Active Storage is a powerful tool in Rails for file handling. However:
- When attaching a large number of files (hundreds or thousands), the performance can degrade significantly.
- Issues like **N+1 queries**, **slow I/O**, and **database load** become more noticeable as dataset size increases.

This project is designed to **reproduce real-world scenarios** and explore optimization techniques to make file attachment faster and more efficient.
