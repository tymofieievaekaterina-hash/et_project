# Определение переодов очередей на кассах
Расчет выполнен в MS Excel и MS SQL Server.
Как источник данных использована объединенная таблица из файлов "store_checkout_queues" и "store_stores". Объединение данных по чекам и магазинам, фильтрация данных по магазинам с id=98451680 и id=12864064 произведидино в Excel с помощью функционала надстройки Excel - Power Query. В результате получена таблицу вида:
checks_number
store_id
employees_id
quantity
selling_price
checkout_id
start_operation_dt
end_operation_dt

Такая же логика объединения и выборки магазинов воспроизведена в виде SQL запроса.

