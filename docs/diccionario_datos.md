# Diccionario de datos del data warehouse

Este documento describe las 21 tablas del data warehouse: 11 dimensiones, 6 tablas de hechos y 4 data marts.


## Índice

| Tabla | Tipo | Grano | Filas |
|---|---|---|---:|
| [dim_date](#dim_date) | Dimensión | Una fila por fecha | 639 |
| [dim_mes](#dim_mes) | Dimensión | Una fila por mes | 21 |
| [dim_channel](#dim_channel) | Dimensión | Una fila por canal de venta | 2 |
| [dim_customer](#dim_customer) | Dimensión | Una fila por cliente | 3.471 |
| [dim_location](#dim_location) | Dimensión | Una fila por dirección | 3.829 |
| [dim_store](#dim_store) | Dimensión | Una fila por tienda física | 4 |
| [dim_product](#dim_product) | Dimensión | Una fila por producto | 2 |
| [dim_traffic_source](#dim_traffic_source) | Dimensión | Una fila por origen de tráfico | 4 |
| [dim_device](#dim_device) | Dimensión | Una fila por tipo de dispositivo | 3 |
| [dim_payment_method](#dim_payment_method) | Dimensión | Una fila por método de pago | 4 |
| [dim_carrier](#dim_carrier) | Dimensión | Una fila por transportista | 1 |
| [fact_sales](#fact_sales) | Hecho | Una fila por pedido | 11.969 |
| [fact_sales_item](#fact_sales_item) | Hecho | Una fila por ítem de pedido | 14.573 |
| [fact_payment](#fact_payment) | Hecho | Una fila por pago | 11.969 |
| [fact_shipment](#fact_shipment) | Hecho | Una fila por envío | 7.009 |
| [fact_nps](#fact_nps) | Hecho | Una fila por respuesta NPS | 3.083 |
| [fact_web_session](#fact_web_session) | Hecho | Una fila por sesión web | 100.363 |
| [mart_ventas_mensual](#mart_ventas_mensual) | Data mart | Mes × canal × provincia | 168 |
| [mart_producto_mensual](#mart_producto_mensual) | Data mart | Mes × producto | 42 |
| [mart_nps_mensual](#mart_nps_mensual) | Data mart | Mes × canal | 42 |
| [mart_usuarios_mensual](#mart_usuarios_mensual) | Data mart | Mes | 21 |

---

## Dimensiones

### dim_date

- **Tipo:** dimensión
- **Grano:** una fila por fecha calendario, del 2024-01-01 al 2025-09-30.
- **Origen:** se genera con `generate_series` (no viene de `raw/`).

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| date_id | INTEGER | PK | NOT NULL | de 20240101 a 20250930 | Clave de la fecha con formato AAAAMMDD (por ejemplo, 20240101). |
| full_date | DATE | ninguna | NOT NULL | de 2024-01-01 a 2025-09-30 | Fecha completa. Única y no nula. |
| day | INTEGER | ninguna | NULL | de 1 a 31 | Día del mes (1–31). |
| month | INTEGER | ninguna | NULL | de 1 a 12 | Número de mes (1–12). |
| year | INTEGER | ninguna | NULL | 2024 o 2025 | Año. |
| quarter | INTEGER | ninguna | NULL | de 1 a 4 | Trimestre del año (1–4). |

### dim_mes

- **Tipo:** dimensión (se crea en `04_marts.sql` para el dashboard)
- **Grano:** una fila por mes (de enero de 2024 a septiembre de 2025)
- **Origen:** meses distintos de `dim_date`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| mes | DATE | PK | NOT NULL | libre | Primer día del mes (por ejemplo, 2024-02-01). Se usa para unir con la columna `mes` de los data marts, aunque esa relación no está declarada como FK. |
| anio | INTEGER | ninguna | NOT NULL | libre | Año del mes. |
| nro_mes | INTEGER | ninguna | NOT NULL | de 1 a 12 | Número de mes (1–12). |

### dim_channel

- **Tipo:** dimensión
- **Grano:** una fila por canal de venta (`ONLINE` = Tienda Online, `OFFLINE` = Tiendas Físicas)
- **Origen:** `raw.channel`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| channel_id | INTEGER | PK | NOT NULL | libre | Identificador del canal (clave natural del sistema de origen). |
| code | VARCHAR(20) | ninguna | NOT NULL | `ONLINE` u `OFFLINE` | Código del canal (`ONLINE`, `OFFLINE`). Único y no nulo. |
| name | VARCHAR(50) | ninguna | NOT NULL | libre | Nombre descriptivo del canal. |

### dim_customer

- **Tipo:** dimensión
- **Grano:** una fila por cliente.
- **Origen:** `raw.customer`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| customer_id | INTEGER | PK | NOT NULL | libre | Identificador del cliente (clave natural del sistema de origen). |
| email | VARCHAR(120) | ninguna | NULL | libre | Correo electrónico del cliente. Único. |
| first_name | VARCHAR(80) | ninguna | NULL | libre | Nombre. |
| last_name | VARCHAR(80) | ninguna | NULL | libre | Apellido. |
| phone | VARCHAR(30) | ninguna | NULL | libre | Teléfono. |
| status | CHAR(1) | ninguna | NULL | `status IN ('A', 'I')` | Estado del cliente: solo admite `A` o `I` (valor por defecto: `A`). `A` = cliente activo; `I` = cliente que dio de baja su cuenta (sus compras anteriores siguen en los datos). |
| created_at | TIMESTAMP | ninguna | NOT NULL | libre | Fecha y hora de alta del cliente. |

### dim_location

- **Tipo:** dimensión
- **Grano:** una fila por dirección.
- **Origen:** `raw.address` unida con `raw.province`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| location_id | INTEGER | PK | NOT NULL | libre | Identificador de la dirección (`address_id` de origen). |
| address_line | VARCHAR(120) | ninguna | NULL | libre | Calle y número. |
| city | VARCHAR(80) | ninguna | NULL | libre | Ciudad. |
| province_name | VARCHAR(50) | ninguna | NULL | libre | Nombre de la provincia. |
| province_code | VARCHAR(10) | ninguna | NULL | `BA`, `CBA`, `SF` o `MZA` | Código de la provincia (por ejemplo, `BA`, `CBA`). |
| postal_code | VARCHAR(20) | ninguna | NULL | libre | Código postal. |
| country_code | CHAR(2) | ninguna | NULL | libre | Código de país (por ejemplo, `AR`). |

### dim_store

- **Tipo:** dimensión
- **Grano:** una fila por tienda física.
- **Origen:** `raw.store` unida con `raw.address` y `raw.province`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| store_id | INTEGER | PK | NOT NULL | libre | Identificador de la tienda. |
| store_name | VARCHAR(80) | ninguna | NOT NULL | libre | Nombre de la tienda (por ejemplo, "Tienda BA"). |
| address_id | INTEGER | ninguna | NULL | libre | Dirección de la tienda. En el origen es FK hacia `address.address_id`; en el DW coincide con `dim_location.location_id`, pero no está declarada como FK. |
| city | VARCHAR(80) | ninguna | NULL | libre | Ciudad de la tienda (copiada de la dirección). |
| province_name | VARCHAR(50) | ninguna | NULL | libre | Provincia de la tienda (copiada de la dirección). |

### dim_product

- **Tipo:** dimensión
- **Grano:** una fila por producto, con la jerarquía de categorías aplanada.
- **Origen:** `raw.product` unida con `raw.product_category` (categoría y categoría padre).

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| product_key | INTEGER | PK | NOT NULL | libre | Clave subrogada del producto, generada con `ROW_NUMBER()`. |
| product_id | INTEGER | ninguna | NOT NULL | libre | Clave natural del producto en el sistema de origen. |
| sku | VARCHAR | ninguna | NOT NULL | libre | Código SKU del producto. |
| name | VARCHAR | ninguna | NOT NULL | libre | Nombre del producto. |
| category | VARCHAR | ninguna | NULL | `Classic` o `Sport` | Categoría (`Classic` / `Sport`). |
| family | VARCHAR | ninguna | NULL | `Bottles` | Familia: la categoría padre (`Bottles`). |
| list_price | DECIMAL(12, 2) | ninguna | NULL | libre | Precio de lista en pesos argentinos, sin IVA. |

### dim_traffic_source

- **Tipo:** dimensión
- **Grano:** una fila por origen de tráfico web.
- **Origen:** valores distintos de `raw.web_session.source`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| traffic_source_key | INTEGER | PK | NOT NULL | libre | Clave subrogada generada con `ROW_NUMBER()`. |
| source | VARCHAR(50) | ninguna | NOT NULL | `ads`, `direct`, `referral`, `organic` o `unknown` | Origen de la sesión. Único. Si en origen viene vacío se carga como `unknown` (hoy no hay ninguno). |

### dim_device

- **Tipo:** dimensión
- **Grano:** una fila por tipo de dispositivo.
- **Origen:** valores distintos de `raw.web_session.device`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| device_key | INTEGER | PK | NOT NULL | libre | Clave subrogada generada con `ROW_NUMBER()`. |
| device | VARCHAR(30) | ninguna | NOT NULL | libre | Tipo de dispositivo. Único. Si viene vacío se carga como `unknown` (hoy no hay ninguno). |

### dim_payment_method

- **Tipo:** dimensión
- **Grano:** una fila por método de pago.
- **Origen:** valores distintos de `raw.payment.method`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| payment_method_key | INTEGER | PK | NOT NULL | libre | Clave subrogada generada con `ROW_NUMBER()`. |
| method | VARCHAR(20) | ninguna | NOT NULL | `CARD`, `CASH`, `GATEWAY`, `TRANSFER` o `unknown` | Método de pago. Único. Si viene vacío se carga como `unknown` (hoy no hay ninguno). |

### dim_carrier

- **Tipo:** dimensión
- **Grano:** una fila por transportista.
- **Origen:** valores distintos de `raw.shipment.carrier`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| carrier_key | INTEGER | PK | NOT NULL | libre | Clave subrogada generada con `ROW_NUMBER()`. |
| carrier | VARCHAR(40) | ninguna | NOT NULL | Correo Argentino o `unknown` | Nombre del transportista. Único. Si viene vacío se carga como `unknown` (hoy no hay ninguno). |

---

## Hechos

### fact_sales

- **Tipo:** hecho
- **Grano:** una fila por pedido (cabecera del pedido).
- **Origen:** `raw.sales_order`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| order_id | BIGINT | PK | NOT NULL | libre | Identificador del pedido. |
| date_id | INTEGER | FK → dim_date | NOT NULL | valor de `dim_date.date_id` | Fecha del pedido (AAAAMMDD), calculada a partir de `order_date`. |
| customer_id | INTEGER | FK → dim_customer | NOT NULL | valor de `dim_customer.customer_id` | Cliente que hizo el pedido. |
| channel_id | INTEGER | FK → dim_channel | NOT NULL | valor de `dim_channel.channel_id` | Canal de venta. |
| location_id | INTEGER | FK → dim_location | NULL | valor de `dim_location.location_id` | Dirección de envío (`shipping_address_id` de origen). En las compras en tienda es la dirección de la tienda. Es nula si el pedido no tiene dirección de envío. |
| store_id | INTEGER | FK → dim_store | NULL | valor de `dim_store.store_id` | Tienda física donde se hizo la venta. Admite nulos; viene vacía en las ventas online de la muestra. |
| order_date | TIMESTAMP | ninguna | NOT NULL | libre | Fecha y hora del pedido. |
| status | VARCHAR(20) | ninguna | NOT NULL | `status IN ('CREATED', 'PAID', 'CANCELLED', 'FULFILLED', 'REFUNDED')` | Estado del pedido: `CREATED`, `PAID`, `CANCELLED`, `FULFILLED` o `REFUNDED`. |
| currency_code | CHAR(3) | ninguna | NULL | libre | Moneda del pedido (por ejemplo, `ARS`). |
| subtotal | DECIMAL(12,2) | ninguna | NOT NULL | libre | Importe de los productos antes de impuestos y envío. |
| tax_amount | DECIMAL(12,2) | ninguna | NOT NULL | libre | IVA del pedido: 21 % del subtotal. |
| shipping_fee | DECIMAL(12,2) | ninguna | NOT NULL | 0 (envío gratis), 1.200, 1.500 o 1.800 | Costo de envío. |
| total_amount | DECIMAL(12,2) | ninguna | NOT NULL | libre | Importe total del pedido (en la muestra, subtotal + impuestos + envío). |

### fact_sales_item

- **Tipo:** hecho
- **Grano:** una fila por ítem de pedido (un producto dentro de un pedido).
- **Origen:** `raw.sales_order_item` unida con `raw.sales_order` y `dim_product`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| order_item_id | BIGINT | PK | NOT NULL | libre | Identificador del ítem del pedido. |
| order_id | BIGINT | FK → fact_sales | NOT NULL | valor de `fact_sales.order_id` | Pedido al que pertenece el ítem. |
| date_id | INTEGER | FK → dim_date | NOT NULL | valor de `dim_date.date_id` | Fecha del pedido (AAAAMMDD). |
| customer_id | INTEGER | FK → dim_customer | NOT NULL | valor de `dim_customer.customer_id` | Cliente del pedido. |
| channel_id | INTEGER | FK → dim_channel | NOT NULL | valor de `dim_channel.channel_id` | Canal de venta del pedido. |
| location_id | INTEGER | FK → dim_location | NULL | valor de `dim_location.location_id` | Dirección de envío del pedido. Admite nulos. |
| store_id | INTEGER | FK → dim_store | NULL | valor de `dim_store.store_id` | Tienda física del pedido. Admite nulos. |
| product_key | INTEGER | FK → dim_product | NOT NULL | valor de `dim_product.product_key` | Producto vendido. |
| status | VARCHAR(20) | ninguna | NOT NULL | `status IN ('CREATED', 'PAID', 'CANCELLED', 'FULFILLED', 'REFUNDED')` | Estado del pedido (se copia de la cabecera): `CREATED`, `PAID`, `CANCELLED`, `FULFILLED` o `REFUNDED`. |
| quantity | INTEGER | ninguna | NOT NULL | `quantity > 0` | Unidades vendidas. Debe ser mayor que 0. |
| unit_price | DECIMAL(12,2) | ninguna | NOT NULL | libre | Precio unitario. |
| discount_amount | DECIMAL(12,2) | ninguna | NOT NULL | libre | Descuento de la línea completa (no por unidad): `line_total` = `quantity` × `unit_price` − `discount_amount`. |
| line_total | DECIMAL(12,2) | ninguna | NOT NULL | libre | Importe total de la línea. |

### fact_payment

- **Tipo:** hecho
- **Grano:** una fila por pago.
- **Origen:** `raw.payment` unida con `raw.sales_order` y `dim_payment_method`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| payment_id | BIGINT | PK | NOT NULL | libre | Identificador del pago. |
| order_id | BIGINT | FK → fact_sales | NOT NULL | valor de `fact_sales.order_id` | Pedido que se paga. |
| date_id | INTEGER | FK → dim_date | NULL | valor de `dim_date.date_id` | Fecha del pago (AAAAMMDD), calculada a partir de `paid_at`. Es nula si el pago no se concretó. |
| customer_id | INTEGER | FK → dim_customer | NOT NULL | valor de `dim_customer.customer_id` | Cliente del pedido. |
| channel_id | INTEGER | FK → dim_channel | NOT NULL | valor de `dim_channel.channel_id` | Canal de venta del pedido. |
| payment_method_key | INTEGER | FK → dim_payment_method | NOT NULL | valor de `dim_payment_method.payment_method_key` | Método de pago. |
| status | VARCHAR(20) | ninguna | NOT NULL | `status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')` | Estado del pago: `PENDING`, `PAID`, `FAILED` o `REFUNDED`. |
| amount | DECIMAL(12,2) | ninguna | NOT NULL | libre | Importe pagado. |
| paid_at | TIMESTAMP | ninguna | NULL | libre | Fecha y hora del pago. Admite nulos. |
| transaction_ref | VARCHAR(80) | ninguna | NULL | libre | Referencia de la transacción (por ejemplo, `CARD-4INSXR5RXC`). |

### fact_shipment

- **Tipo:** hecho
- **Grano:** una fila por envío. Usa `dim_date` dos veces (fecha de despacho y fecha de entrega).
- **Origen:** `raw.shipment` unida con `raw.sales_order` y `dim_carrier`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| shipment_id | BIGINT | PK | NOT NULL | libre | Identificador del envío. |
| order_id | BIGINT | FK → fact_sales | NOT NULL | valor de `fact_sales.order_id` | Pedido enviado. |
| customer_id | INTEGER | FK → dim_customer | NOT NULL | valor de `dim_customer.customer_id` | Cliente del pedido. |
| channel_id | INTEGER | FK → dim_channel | NOT NULL | valor de `dim_channel.channel_id` | Canal de venta del pedido. |
| carrier_key | INTEGER | FK → dim_carrier | NOT NULL | valor de `dim_carrier.carrier_key` | Transportista. |
| shipped_date_id | INTEGER | FK → dim_date | NULL | valor de `dim_date.date_id` | Fecha de despacho (AAAAMMDD). Es nula si todavía no salió. |
| delivered_date_id | INTEGER | FK → dim_date | NULL | valor de `dim_date.date_id` | Fecha de entrega (AAAAMMDD). Es nula si todavía no se entregó. |
| tracking_number | VARCHAR(60) | ninguna | NULL | libre | Número de seguimiento. |
| status | VARCHAR(20) | ninguna | NOT NULL | `status IN ('READY', 'SHIPPED', 'DELIVERED', 'CANCELLED')` | Estado del envío: `READY`, `SHIPPED`, `DELIVERED` o `CANCELLED`. |
| shipped_at | TIMESTAMP | ninguna | NULL | libre | Fecha y hora de despacho. |
| delivered_at | TIMESTAMP | ninguna | NULL | libre | Fecha y hora de entrega. |
| delivery_days | INTEGER | ninguna | NULL | libre | Días entre el despacho y la entrega, calculados con `DATE_DIFF('day', ...)`: cuenta cambios de día calendario, no períodos de 24 horas. |

### fact_nps

- **Tipo:** hecho
- **Grano:** una fila por respuesta a la encuesta NPS.
- **Origen:** `raw.nps_response`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| nps_id | BIGINT | PK | NOT NULL | libre | Identificador de la respuesta. |
| date_id | INTEGER | FK → dim_date | NOT NULL | valor de `dim_date.date_id` | Fecha de la respuesta (AAAAMMDD). |
| customer_id | INTEGER | FK → dim_customer | NULL | valor de `dim_customer.customer_id` | Cliente que respondió. Es nulo si la respuesta es anónima. |
| channel_id | INTEGER | FK → dim_channel | NOT NULL | valor de `dim_channel.channel_id` | Canal sobre el que se responde la encuesta. |
| score | SMALLINT | ninguna | NOT NULL | `score BETWEEN 0 AND 10` (de 0 a 10) | Puntaje de 0 a 10. |
| comment | VARCHAR | ninguna | NULL | libre | Comentario libre (opcional). |
| responded_at | TIMESTAMP | ninguna | NOT NULL | libre | Fecha y hora de la respuesta. |

### fact_web_session

- **Tipo:** hecho
- **Grano:** una fila por sesión web.
- **Origen:** `raw.web_session` unida con `dim_traffic_source` y `dim_device`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| session_id | BIGINT | PK | NOT NULL | libre | Identificador de la sesión. |
| date_id | INTEGER | FK → dim_date | NOT NULL | valor de `dim_date.date_id` | Fecha de inicio de la sesión (AAAAMMDD). |
| customer_id | INTEGER | FK → dim_customer | NULL | valor de `dim_customer.customer_id` | Cliente identificado. Es nulo si el visitante es anónimo. |
| traffic_source_key | INTEGER | FK → dim_traffic_source | NOT NULL | valor de `dim_traffic_source.traffic_source_key` | Origen del tráfico. |
| device_key | INTEGER | FK → dim_device | NOT NULL | valor de `dim_device.device_key` | Tipo de dispositivo. |
| started_at | TIMESTAMP | ninguna | NOT NULL | libre | Fecha y hora de inicio. |
| ended_at | TIMESTAMP | ninguna | NULL | libre | Fecha y hora de fin. Admite nulos. |
| duration_minutes | INTEGER | ninguna | NULL | libre | Duración calculada con `DATE_DIFF('minute', ...)`: cuenta cambios de minuto, no minutos completos (por ejemplo, 3 min 43 s da 4). Es nula si no hay `ended_at`. |

---

## Data marts

Los data marts son tablas agregadas por mes que alimentan el dashboard. No tienen FK declaradas: guardan los nombres (de canal, provincia o producto) en lugar de las claves de las dimensiones. La columna `mes` siempre es el primer día del mes y se puede unir con `dim_mes.mes`.

### mart_ventas_mensual

- **Tipo:** data mart
- **Grano:** una fila por mes × canal × provincia.
- **Origen:** `fact_sales` unida con `dim_date`, `dim_channel` y `dim_location`. Solo incluye pedidos con estado `PAID` o `FULFILLED`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| mes | DATE | PK (compuesta) | NOT NULL | libre | Primer día del mes. |
| canal | VARCHAR(50) | PK (compuesta) | NOT NULL | libre | Nombre del canal (`dim_channel.name`). |
| provincia | VARCHAR(50) | PK (compuesta) | NOT NULL | libre | Provincia de la dirección de envío. Vale `Sin provincia` si el pedido no tiene dirección o provincia. |
| ventas | DECIMAL(14,2) | ninguna | NOT NULL | libre | Suma de `total_amount`. |
| pedidos | INTEGER | ninguna | NOT NULL | libre | Cantidad de pedidos. |
| ticket_promedio | DECIMAL(12,2) | ninguna | NULL | libre | Ventas / pedidos, redondeado a 2 decimales. |

### mart_producto_mensual

- **Tipo:** data mart
- **Grano:** una fila por mes × producto.
- **Origen:** `fact_sales_item` unida con `dim_date` y `dim_product`. Solo incluye ítems de pedidos con estado `PAID` o `FULFILLED`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| mes | DATE | PK (compuesta) | NOT NULL | libre | Primer día del mes. |
| producto | VARCHAR(80) | PK (compuesta) | NOT NULL | libre | Nombre del producto (`dim_product.name`). |
| ventas | DECIMAL(14,2) | ninguna | NOT NULL | libre | Suma de `line_total`. |
| unidades | INTEGER | ninguna | NOT NULL | libre | Suma de `quantity`. |
| ranking | INTEGER | ninguna | NOT NULL | libre | Puesto del producto dentro del mes según ventas, de mayor a menor (`RANK()`: los empates comparten puesto). |

### mart_nps_mensual

- **Tipo:** data mart
- **Grano:** una fila por mes × canal.
- **Origen:** `fact_nps` unida con `dim_date` y `dim_channel`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| mes | DATE | PK (compuesta) | NOT NULL | libre | Primer día del mes. |
| canal | VARCHAR(50) | PK (compuesta) | NOT NULL | libre | Nombre del canal (`dim_channel.name`). |
| respuestas | INTEGER | ninguna | NOT NULL | libre | Cantidad de respuestas. |
| promotores | INTEGER | ninguna | NOT NULL | libre | Respuestas con puntaje de 9 o 10. |
| detractores | INTEGER | ninguna | NOT NULL | libre | Respuestas con puntaje de 0 a 6. |
| nps | DECIMAL(5,1) | ninguna | NULL | de −100 a 100 | Net Promoter Score: 100 × (promotores − detractores) / respuestas, redondeado a 1 decimal. Va de −100 a 100. |

### mart_usuarios_mensual

- **Tipo:** data mart
- **Grano:** una fila por mes.
- **Origen:** `fact_web_session` unida con `dim_date`.

| Columna | Tipo de dato | Clave | Nulo | Dominio | Descripción |
|---|---|---|---|---|---|
| mes | DATE | PK | NOT NULL | libre | Primer día del mes. |
| usuarios_activos | INTEGER | ninguna | NOT NULL | libre | Clientes identificados distintos con al menos una sesión en el mes (las sesiones anónimas no cuentan). |
| sesiones | INTEGER | ninguna | NOT NULL | libre | Cantidad total de sesiones, anónimas incluidas. |
| sesiones_anonimas | INTEGER | ninguna | NOT NULL | libre | Sesiones sin cliente identificado (`customer_id` nulo). |
