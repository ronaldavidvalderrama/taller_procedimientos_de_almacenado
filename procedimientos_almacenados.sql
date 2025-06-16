-- Active: 1749956386295@@127.0.0.1@3306@pizzas

--**`ps_add_pizza_con_ingredientes`**
--Crea un procedimiento que inserte una nueva pizza en la tabla `pizza` 
--junto con sus ingredientes en `pizza_ingrediente`.












--**`ps_actualizar_precio_pizza`**
--Procedimiento que reciba `p_pizza_id` y `p_nuevo_precio` y actualice el precio.

-- Antes de actualizar, valide con un `IF` que el nuevo 
--precio sea mayor que 0; de lo contrario, lance un `SIGNAL`.

DELIMITER $$
DROP PROCEDURE IF EXISTS ps_actualizar_precio_pizza;

CREATE PROCEDURE ps_actualizar_precio_pizza(
    IN p_pizza_id INT,
    IN p_presentacion_id INT,
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