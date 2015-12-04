# baseball_data

## setup

* create the database
```
psql -h localhost < sql/create_database.sql
```

* create the tables needed
```
psql -h localhost -d baseball_data < sql/create_tables.sql
```

* load the data
```
psql -h localhost < sql/load_data.sql
```

## questions

* which starter has the highest winning percentage?
* which group of starters (2-9) has the highest winning percentage?



# notice
The information used here was obtained free of
charge from and is copyrighted by Retrosheet.  Interested
parties may contact Retrosheet at "www.retrosheet.org".
