-- Active: 1749956386295@@127.0.0.1@3306@pizzas

--**`ps_add_pizza_con_ingredientes`**
--Crea un procedimiento que inserte una nueva pizza en la tabla `pizza` 
--junto con sus ingredientes en `pizza_ingrediente`.

DELIMITER $$

DROP PROCEDURE IF EXISTS ps_add_pizza_con_ingredientes;


CREATE PROCEDURE ps_add_pizza_con_ingredientes(
    IN p_nombre_pizza VARCHAR(100),
    IN p_precio_pequeña DECIMAL(10,2),
    IN p_precio_mediana DECIMAL(10,2),
    IN p_precio_grande DECIMAL(10,2),
    IN p_ingrediente1_id INT,
    IN p_ingrediente1_cantidad INT,
    IN p_ingrediente2_id INT,
    IN p_ingrediente2_cantidad INT
)
BEGIN 
    DECLARE v_producto_id INT;
    DECLARE v_detalle_id INT;

    -- Insertar la nueva pizza en producto
    INSERT INTO producto(nombre, tipo_producto_id)
    VALUES (p_nombre_pizza, 2);

    SET v_producto_id = LAST_INSERT_ID();
    -- Insertar las presentaciones de la pizza
    INSERT INTO producto_presentacion(producto_id, presentacion_id, precio)
    VALUES (v_producto_id, 1, p_precio_pequeña), -- Pequeña
           (v_producto_id, 2, p_precio_mediana), -- Mediana
           (v_producto_id, 3, p_precio_grande); -- Grande
    
    -- CREAR UN DETALLE TEMPORAL PARA INGREDIENTES
    INSERT INTO detalle_pedido(pedido_id, cantidad)
    VALUES (1, 1);

    SET v_detalle_id = LAST_INSERT_ID();

    -- 4. Insertar ingredientes como extras en ingredientes_extra
    INSERT INTO ingredientes_extra (detalle_id, ingrediente_id, cantidad)
    VALUES
        (v_detalle_id, p_ingrediente1_id, p_ingrediente1_cantidad),
        (v_detalle_id, p_ingrediente2_id, p_ingrediente2_cantidad);
END $$

DELIMITER ;

-- Llamada ejemplo
CALL ps_add_pizza_con_ingredientes(
    'choripizza', -- Nombre de la pizza
    150.00, -- Precio pequeña
    200.00, -- Precio mediana
    250.00, -- Precio grande
    1,       -- ID del ingrediente 1 (ejemplo: Queso)
    2,       -- Cantidad del ingrediente 1
    2,       -- ID del ingrediente 2 (ejemplo: Tomate)
    3        -- Cantidad del ingrediente 2
);

SELECT * FROM producto WHERE tipo_producto_id = 2; -- Verificar que la pizza se haya insertado correctamente


--**`ps_actualizar_precio_pizza`**
--Procedimiento que reciba `p_pizza_id` y `p_nuevo_precio` y actualice el precio.

-- Antes de actualizar, valide con un `IF` que el nuevo 
--precio sea mayor que 0; de lo contrario, lance un `SIGNAL`.

DELIMITER $$
DROP PROCEDURE IF EXISTS ps_actualizar_precio_pizza;

CREATE PROCEDURE ps_actualizar_precio_pizza(
    IN p_nombre_pizza INT,
    IN p_nuevo_precio DECIMAL(10,2)
)
BEGIN
    -- Validar que el nuevo precio sea mayor que 0
    IF p_nuevo_precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El nuevo precio debe ser mayor que 0';
    END IF;

-- Actualizar el precio de una presentación específica de la pizza
    UPDATE producto_presentacion
    SET precio = p_nuevo_precio
    WHERE producto_id = p_pizza_id
    AND presentacion_id = p_presentacion_id;
END $$

DELIMITER ;
-- Llamada ejemplo
CALL ps_actualizar_precio_pizza(2, 3, 51000);-- Actualizar el producto con id 2 que son las pizzas 

SELECT * FROM producto_presentacion WHERE producto_id = 2;


--**`ps_generar_pedido`** *(**usar TRANSACTION**)*
--Procedimiento que reciba:

--`p_cliente_id`,
-- una lista de pizzas y cantidades (`p_items`),
-- `p_metodo_pago_id`.
--  **Dentro de una transacción**:

--1. Inserta en `pedido`.
--2. Para cada ítem, inserta en `detalle_pedido` y en `detalle_pedido_pizza`.
--3. Si todo va bien, hace `COMMIT`; si falla, `ROLLBACK` y devuelve un mensaje de error.

DELIMITER $$

CREATE PROCEDURE ps_generador_pedido(
    IN p_cliente_id INT,
    IN p_producto_id INT,
    IN p_presentacion_id INT,
    IN p_cantidad INT,
    IN p_metodo_pago_id INT,
    OUT p_mensaje VARCHAR(255) 
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_pedido_id INT;
    DECLARE v_detalle_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error no se pudo generar el pedido';
    END;

    START TRANSACTION;

    -- Paso 1: Obtener el precio
    SELECT precio INTO v_precio FROM producto_presentacion
    WHERE producto_id = p_producto_id AND presentacion_id = p_presentacion_id;

    -- Paso 2: Calcular el total
    SET v_total = v_precio * p_cantidad;

    -- Paso 3: Insertar el pedido
    INSERT INTO pedido(fecha_recogida, total, cliente_id, metodo_pago_id)
    VALUES (NOW(), v_total, p_cliente_id, p_metodo_pago_id);

    SET v_pedido_id = LAST_INSERT_ID();

    -- Paso 4: Insertar el detalle del pedido
    INSERT INTO detalle_pedido(pedido_id, cantidad)
    VALUES (v_pedido_id, p_cantidad);

    SET v_detalle_id = LAST_INSERT_ID();

    -- Paso 5: Insertar el detalle del pedido para la pizza
    INSERT INTO detalle_pedido_producto(detalle_id, producto_id)
    VALUES (v_detalle_id, p_producto_id);

    COMMIT;
    SET p_mensaje = 'Pedido generado correctamente';

END $$
DELIMITER ;

CALL ps_generador_pedido(
    1, -- p_cliente_id
    1, -- p_producto_id (Coca-Cola)
    1, -- p_presentacion_id (Pequeña)
    2, -- p_cantidad
    1, -- p_metodo_pago_id (Efectivo)
    @mensaje
);

SELECT * FROM pedido WHERE cliente_id = 1;

--**`ps_cancelar_pedido`**
--Recibe `p_pedido_id` y:

-- Marca el pedido como “cancelado” (p. ej. actualiza un campo `estado`),
-- Elimina todas sus líneas de detalle (`DELETE FROM detalle_pedido WHERE pedido_id = …`).
-- Devuelve el número de líneas eliminadas.

DELIMITER $$

DROP PROCEDURE IF EXISTS ps_cancelar_pedido $$

CREATE PROCEDURE ps_cancelar_pedido(
    IN p_pedido_id INT
)
BEGIN
    DECLARE filas_detalle INT;

    -- eliminar ingredientes extra asociados al pedido
    DELETE ie
    FROM ingredientes_extra ie
    JOIN detalle_pedido dp ON ie.detalle_id = dp.id
    WHERE dp.pedido_id = p_pedido_id;

    -- Eliminar los combos relacionados
    DELETE dpc
    FROM detalle_pedido_combo dpc
    JOIN detalle_pedido dp ON dpc.detalle_id = dp.id
    WHERE dp.pedido_id = p_pedido_id;

    -- Eliminar productos relacionados
    DELETE dpp
    FROM detalle_pedido_producto dpp
    JOIN detalle_pedido dp ON dpp.detalle_id = dp.id
    WHERE dp.pedido_id = p_pedido_id;

    -- Eliminar el detalle del pedido
    DELETE FROM detalle_pedido
    WHERE pedido_id = p_pedido_id;

    -- Saber cuantas líneas de detalle se eliminaron
    SET filas_detalle = ROW_COUNT();

    -- Devolver el número de líneas eliminadas
    SELECT filas_detalle AS 'Líneas eliminadas';

END $$

DELIMITER ;


-- Llamada ejemplo
CALL ps_cancelar_pedido(1);



-- Verificar que el pedido se haya cancelado
SELECT * FROM detalle_pedido ;



--**`ps_facturar_pedido`**
--Crea la factura asociada a un pedido dado (`p_pedido_id`). Debe:

-- Calcular el total sumando precios de pizzas × cantidad,
-- Insertar en `factura`.
-- Devolver el `factura_id` generado.

DELIMITER $$

DROP PROCEDURE IF EXISTS ps_facturar_pedido $$

CREATE PROCEDURE ps_facturar_pedido(
    IN p_pedido_id INT
)
BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_cliente_id INT;
    DECLARE v_factura_id INT;

    -- Obtener el ID del cliente para la factura
    SELECT cliente_id INTO v_cliente_id
    FROM pedido
    WHERE id = p_pedido_id;

    -- Calcular total de productos (producto_presentacion)
    SELECT SUM(pp.precio * dp.cantidad)
    INTO v_total
    FROM detalle_pedido dp
    JOIN detalle_pedido_producto dpp ON dp.id = dpp.detalle_id
    JOIN producto_presentacion pp ON dpp.producto_id = pp.producto_id
    WHERE dp.pedido_id = p_pedido_id;

    -- Agregar total de combos
    SELECT v_total + IFNULL(SUM(c.precio * dp.cantidad), 0)
    INTO v_total
    FROM detalle_pedido dp
    JOIN detalle_pedido_combo dpc ON dp.id = dpc.detalle_id
    JOIN combo c ON dpc.combo_id = c.id
    WHERE dp.pedido_id = p_pedido_id;

    -- Insertar en la tabla factura
    INSERT INTO factura (total, fecha, pedido_id, cliente_id)
    VALUES (v_total, NOW(), p_pedido_id, v_cliente_id);

    -- Obtener el ID de la factura generada
    SET v_factura_id = LAST_INSERT_ID();

    -- Devolver el ID de la factura
    SELECT v_factura_id AS factura_id, v_total AS total_factura;
END $$

DELIMITER ;

-- Llamada ejemplo
CALL ps_facturar_pedido(1);
CALL ps_facturar_pedido(2);



--## Ejercicios de **Funciones**

-- **`fc_calcular_subtotal_pizza`**
--  - Parámetro: `p_pizza_id`
--  - Retorna el precio base de la pizza más la suma de precios de sus ingredientes.


DELIMITER $$

DROP FUNCTION IF EXISTS fc_calcular_subtotal_pizza $$

CREATE FUNCTION fc_calcular_subtotal_pizza(
    p_detalle_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_precio_base DECIMAL(10,2) DEFAULT 0;
    DECLARE v_precio_ingredientes DECIMAL(10,2) DEFAULT 0;
    DECLARE v_producto_id INT;
    DECLARE v_presentacion_id INT;

    -- Obtener el producto asociado al detalle
    SELECT producto_id INTO v_producto_id
    FROM detalle_pedido_producto
    WHERE detalle_id = p_detalle_id
    LIMIT 1;

    -- Suponiendo que se quiere la presentación "Mediana" (id = 2)
    SET v_presentacion_id = 2;

    -- Obtener el precio base de la pizza según su presentación
    SELECT precio INTO v_precio_base
    FROM producto_presentacion
    WHERE producto_id = v_producto_id
      AND presentacion_id = v_presentacion_id;

    -- Calcular el precio total de los ingredientes extra
    SELECT IFNULL(SUM(ie.cantidad * i.precio), 0)
    INTO v_precio_ingredientes
    FROM ingredientes_extra ie
    JOIN ingrediente i ON ie.ingrediente_id = i.id
    WHERE ie.detalle_id = p_detalle_id;

    -- Retornar la suma del precio base + ingredientes extra
    RETURN v_precio_base + v_precio_ingredientes;
END $$

DELIMITER ;

-- Llamada ejemplo
SELECT fc_calcular_subtotal_pizza(3) AS subtotal_pizza;

SELECT *FROM detalle_pedido_producto;


--**fc_descuento_por_cantidad**- Parámetros: p_cantidad INT, p_precio_unitario DECIMAL
-- Si p_cantidad ≥ 5 aplica 10% de descuento, sino 0%. Retorna el monto de descuento.


DELIMITER $$

DROP FUNCTION IF EXISTS fc_descuento_por_cantidad $$

CREATE FUNCTION fc_descuento_por_cantidad(
    p_cantidad INT,
    p_precio_unitario DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_descuento DECIMAL(10,2);

    IF p_cantidad >= 5 THEN
        SET v_descuento = p_cantidad * p_precio_unitario * 0.10;
    ELSE
        SET v_descuento = 0;
    END IF;

    RETURN v_descuento;
END $$

DELIMITER ;

-- Llamada ejemplo

SELECT fc_descuento_por_cantidad(6, 100.00) AS descuento; 