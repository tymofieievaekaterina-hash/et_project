--формируем объединеную исходную таблицу
WITH join_table AS ( 
  SELECT 
        checks_number,
        store_id,
        employees_id,
        quantity,
        selling_price,
        REPLACE(checkout_id1,'"', '') as checkout_id,
        CAST(REPLACE(start_operation_dt,'"', '') as datetime) as start_operation_dt,
        CAST(REPLACE(end_operation_dt,'"', '') as datetime) as   end_operation_dt,
       
             --считаем время операции в секундах
       DATEDIFF(second,CAST(REPLACE(start_operation_dt,'"', '') as datetime),
                            CAST(REPLACE(end_operation_dt,'"', '') as datetime)) as time_operation_second,

             --ранжируем операции по возрастанию даты в разрезе employees_id, checkout_id1, store_id
       ROW_NUMBER() OVER(PARTITION BY  employees_id, checkout_id1, store_id ORDER BY CAST(REPLACE(start_operation_dt,'"', '') as datetime)) AS num_rank
 
  FROM store_checkout_queues scq
  LEFT JOIN store_stores ss ON scq.store_uuid = ss.store_uuid
  WHERE store_id IN (98451680, 12864064)
),
prev_operation as
(SELECT checks_number,
        --выводим дату и время предидущей операции
        LAG(end_operation_dt) OVER(PARTITION BY store_id, employees_id, checkout_id ORDER BY num_rank) AS prev_end_time,
        --выводим количество позиций в чеке предидущей операции
        LAG(quantity) OVER(PARTITION BY store_id, employees_id, checkout_id ORDER BY num_rank) as prev_quantity,
           --определяем минимальное временя на операцию (в секундах) в зависимости от количества товаров в чеке в предидущей операции для каждого кассира
        MIN(time_operation_second) OVER (PARTITION BY employees_id, quantity) as min_time_operation,
         --часы
        FORMAT(start_operation_dt, 'HH:00') + ' - ' + FORMAT(DATEADD(hour, 1, start_operation_dt), 'HH:00') AS hour_operation
FROM join_table
)

SELECT hour_operation, 
       COUNT(checks_number) as count_operation
    
FROM (

SELECT po.checks_number,
       gt.store_id,
       gt.employees_id,
       gt.quantity,
       gt.selling_price,
       po.hour_operation,
       gt.num_rank,
       gt.time_operation_second,
       po.prev_end_time,
       po.prev_quantity,
       po.min_time_operation,
      
         --считаем разницу во времени с предидущей операцией
        DATEDIFF(second, prev_end_time, start_operation_dt) as time_between_operations,
        --формируем признак наличия очереди
        itog_filter = iif(DATEDIFF(second, prev_end_time, start_operation_dt) IS NULL, 0,
                      iif(DATEDIFF(second, prev_end_time, start_operation_dt) >= 
        LAG(min_time_operation) OVER(PARTITION BY store_id, employees_id, checkout_id ORDER BY num_rank), 0, 1))
        
FROM join_table gt
JOIN prev_operation po ON gt.checks_number=po.checks_number) as total_table
WHERE itog_filter = 1
GROUP BY hour_operation
ORDER BY count_operation DESC