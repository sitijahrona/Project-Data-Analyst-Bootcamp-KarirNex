# SOAL NO.1 total ongkir dan avg ongkir pertahun 2025

select 
SUM(shipping_fee) as total_ongkir,
AVG(shipping_fee) as avg_ongkir
from toko_peralatan_dapur.orders
WHERE EXTRACT (YEAR from sales_date) = 2025;


# SOAL NO.2 5 produk dengan unit terjual terbanyak 'complete'

#5 produk by unit terjual
select product_name, 
SUM(quantity) as total_unit
from toko_peralatan_dapur.orders
where status_clean= 'complete'
group by product_name
order by total_unit desc
LIMIT 5;

#5 produk by revenue
select product_name, 
SUM(total_sales) as revenue
from toko_peralatan_dapur.orders
where status_clean= 'complete'
group by product_name
order by revenue desc
LIMIT 5;


# SOAL NO 3. total pesanan dan revenue (okt-des) 2025
select COUNT(DISTINCT order_id) as total_pesanan,
SUM(total_sales) as revenue
from toko_peralatan_dapur.orders
where status_clean = 'complete'
AND sales_date between '2025-10-01' and '2025-12-31';


# SOAL NO4. kota dengan rata-rata ongkir terbanyak dan terkecil dan selisihnya
WITH avg_shipping AS (
    SELECT
        city_clean,
        AVG(shipping_fee) AS avg_ongkir
    FROM toko_peralatan_dapur.orders
    GROUP BY city_clean
)

SELECT
    (select city_clean from avg_shipping order by avg_ongkir desc limit 1) AS kota_termahal,
    (select MAX(avg_ongkir) from avg_shipping) AS avg_terbesar,
    (select city_clean from avg_shipping WHERE city_clean IS NOT NULL order by avg_ongkir asc   limit 1) AS kota_termurah,
    (select MIN(avg_ongkir) from avg_shipping) AS avg_terkecil,
    (select MAX(avg_ongkir) - MIN(avg_ongkir) FROM avg_shipping) AS selisih;


# SOAL NO.5 total sales refund / total sales seluruhnya
select 
  sum(case when status_clean = 'refund' then total_sales
    else 0 end) as total_refund,
  sum(total_sales) as gross_sales,
  ROUND(
        SUM(CASE 
              WHEN status_clean = 'refund' THEN total_sales
              ELSE 0 END) 
              * 100.0 / SUM(total_sales),
          2
      ) AS persen_refund
from toko_peralatan_dapur.orders
WHERE EXTRACT(YEAR FROM sales_date) = 2025;


# SOAL NO.6 produk dengan rata rata quantity pesanan tertinggi syarat min 50% complete
    SELECT
        product_name,
        AVG(quantity) AS avg_quantity,
        COUNT(DISTINCT order_id) AS total_pesanan
    FROM toko_peralatan_dapur.orders
    WHERE status_clean = 'complete'
    GROUP BY product_name
    HAVING COUNT(DISTINCT order_id) >=50
    order by avg_quantity desc
    LIMIT 5;

# SOAL NO.7 bulan dengan revenue complete tertinggi
WITH revenue_bulanan AS (
SELECT
    category_clean,FORMAT_DATE('%Y-%m', sales_date) AS bulan,
    SUM(total_sales) AS revenue
    FROM toko_peralatan_dapur.orders
    WHERE status_clean = 'complete'
    AND category_clean != '#REF!'
    GROUP BY category_clean, bulan 
    ),

    ranking AS (
        SELECT *,
              ROW_NUMBER() OVER (PARTITION BY category_clean ORDER BY revenue DESC) AS rank
        FROM revenue_bulanan 
    )

    SELECT
        category_clean, bulan, revenue
    FROM ranking
    WHERE rank = 1;

#SOAL NO.8 berapa banyak produk yang menyumbangkan 80% revenue complete
WITH product_revenue AS (
    SELECT 
    product_name,
    SUM(total_sales) AS revenue
    FROM toko_peralatan_dapur.orders
    WHERE status_clean ='complete'
    GROUP BY product_name

),
cumulative AS (
    SELECT
        product_name,
        revenue,
        SUM(revenue) OVER(ORDER BY revenue DESC) AS cumulative_revenue,
        SUM(revenue) OVER() AS total_revenue
    FROM product_revenue
)
SELECT
    COUNT(*) AS jumlah_produk_80_persen
FROM cumulative
WHERE cumulative_revenue <= total_revenue * 0.8;


# SOAL NO.9 siapa pelanggan dengan jeda rata-rata hari tersingkat?
WITH customer_orders AS(
    SELECT
    customer_name_clean,
    sales_date,
    LAG(sales_date) OVER (PARTITION BY customer_name_clean ORDER BY sales_date)
    AS previous_order
    FROM toko_peralatan_dapur.orders
    WHERE status_clean = 'complete'
),

    customer_gap AS (
    SELECT
        customer_name_clean,
        DATE_DIFF(sales_date, previous_order, DAY) AS jeda_hari
    FROM customer_orders
    WHERE previous_order IS NOT NULL
),

    hasil AS(
        SELECT
        customer_name_clean,
        AVG(jeda_hari) AS avg_jeda_hari,
        COUNT(*) + 1 AS total_pesanan
        FROM customer_gap
        GROUP BY customer_name_clean
        HAVING total_pesanan > 5
    )

    SELECT
    customer_name_clean,
    ROUND(avg_jeda_hari, 2) AS rata_rata_jeda_hari,
    hasil.total_pesanan
    FROM hasil
    ORDER BY customer_name_clean ASC
    LIMIT 1;

 # SOAL NO. 10 Produk apa yang memiliki refund rate tertinggi, dan berapa potensi revenue yang bisa diselamatkan
WITH refund_product AS (
    SELECT
        product_name,
        COUNT(order_id) AS total_order,
        COUNTIF(status_clean = 'refund') AS total_refund,
        SUM(CASE
                WHEN status_clean = 'refund'
                THEN total_sales
                ELSE 0
            END) AS refund_revenue
    FROM toko_peralatan_dapur.orders
    GROUP BY product_name
)

SELECT
    product_name,
    total_order,
    total_refund,
    ROUND(SAFE_DIVIDE(total_refund * 100.0, total_order), 2) AS refund_rate,
    refund_revenue,
    ROUND(
    refund_revenue *
    (SAFE_DIVIDE(total_refund, total_order) - 0.05),
    2
) AS potensi_revenue_diselamatkan

FROM refund_product
ORDER BY refund_rate DESC
LIMIT 1;
