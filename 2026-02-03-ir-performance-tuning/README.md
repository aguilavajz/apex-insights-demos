# Performance Tuning in Interactive Reports

This demo showcases how to optimize Oracle APEX Interactive Reports when dealing with large datasets (1 million+ rows).

## 🚀 The Challenge

Interactive Reports add several layers of "Wrapper Queries" to handle dynamic filtering, sorting, and pagination. Without the correct configuration, the database might be forced to perform full table scans or aggregate the entire dataset on every page load.

## 🛠️ Components

1. **`setup_data.sql`**: A script to generate 1,000,000 rows of test data with realistic distributions.
2. **Demo App Features**:
   - **Naive IR**: Default settings (Total Row Count enabled).
   - **Optimized IR**: Using the "Lazy Count" pattern and optimized SQL source.

## 📖 Instructions

1. Run `setup_data.sql` in your SQL Workshop to create the table and the `get_slow_value` bottleneck function.
2. Create an Interactive Report using:

   ```sql
   SELECT id, order_number, status, amount, 
          get_slow_value(id) as bottleneck
     FROM IR_PERF_TEST
    WHERE get_slow_value(id) IS NOT NULL
   ```

3. **Naive Config:** Set Pagination to "Row Ranges X to Y **of Z**" (forces full scan).
4. **Optimized Config:** Set Pagination to "Row Ranges X to Y" (enables Top-N optimization).

## 🔐 Credentials (Public Demo)

If you are following the live demo online, use these credentials:

- **Username:** `DEMO`
- **Password:** `ApexInsights2026!`

---
**Part of the APEX Insights series.**
[Read the full article](https://insightsapex.vinnyum.tech/performance-tuning-interactive-reports-apex)
