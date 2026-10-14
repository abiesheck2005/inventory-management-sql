This is my first end-to-end SQL project: a small shop's stock room, built in MySQL.

It answers everyday questions like What's running low? What sells best? Who are my top customers?

What's inside
6 tables: categories, suppliers, products, customers, stock_in, sales
4 triggers for automatic stock updates and overselling protection
3 views: low-stock alerts, sales report, inventory value
1 stored procedure to record a sale in one line
17 queries using joins, subqueries, GROUP BY and HAVING

Run it
Install MySQL 8 and MySQL Workbench
Open inventory_management.sql and run the whole script
Try the safety check

Built with: MySQL · SQL · MySQL Workbench
