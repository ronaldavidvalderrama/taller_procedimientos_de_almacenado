-- Active: 1749956386295@@127.0.0.1@3306@pizzas

CREATE DATABASE IF NOT EXISTS pizzas COLLATE utf8mb4_general_ci;

DROP DATABASE IF EXISTS pizzas;

USE pizzas;

CREATE TABLE IF NOT EXISTS cliente (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(100)   NOT NULL,
  telefono         VARCHAR(15)    NOT NULL,
  direccion        VARCHAR(150)   NOT NULL
);


CREATE TABLE IF NOT EXISTS metodo_pago (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(50)    NOT NULL
);


CREATE TABLE IF NOT EXISTS pedido (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  fecha_recogida   DATETIME       NOT NULL,
  total            DECIMAL(10,2)  NOT NULL,
  cliente_id       INT UNSIGNED   NOT NULL,
  metodo_pago_id   INT UNSIGNED   NOT NULL,
  FOREIGN KEY (cliente_id)     REFERENCES cliente(id),
  FOREIGN KEY (metodo_pago_id) REFERENCES metodo_pago(id)
);


CREATE TABLE IF NOT EXISTS factura (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  total            DECIMAL(10,2)  NOT NULL,
  fecha            DATETIME       NOT NULL,
  pedido_id        INT UNSIGNED   NOT NULL,
  cliente_id       INT UNSIGNED   NOT NULL,
  FOREIGN KEY (pedido_id)  REFERENCES pedido(id),
  FOREIGN KEY (cliente_id) REFERENCES cliente(id)
);


CREATE TABLE IF NOT EXISTS tipo_producto (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(50)    NOT NULL
);


CREATE TABLE IF NOT EXISTS producto (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(100)   NOT NULL,
  tipo_producto_id INT UNSIGNED   NOT NULL,
  FOREIGN KEY (tipo_producto_id) REFERENCES tipo_producto(id)
);


CREATE TABLE IF NOT EXISTS presentacion (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(50)    NOT NULL
);


CREATE TABLE IF NOT EXISTS producto_presentacion (
  producto_id      INT UNSIGNED   NOT NULL,
  presentacion_id  INT UNSIGNED   NOT NULL,
  precio           DECIMAL(10,2)  NOT NULL,
  PRIMARY KEY (producto_id, presentacion_id),
  FOREIGN KEY (producto_id)     REFERENCES producto(id),
  FOREIGN KEY (presentacion_id) REFERENCES presentacion(id)
);


CREATE TABLE IF NOT EXISTS combo (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(100)   NOT NULL,
  precio           DECIMAL(10,2)  NOT NULL
);


CREATE TABLE IF NOT EXISTS combo_producto (
  combo_id         INT UNSIGNED   NOT NULL,
  producto_id      INT UNSIGNED   NOT NULL,
  PRIMARY KEY (combo_id, producto_id),
  FOREIGN KEY (combo_id)    REFERENCES combo(id),
  FOREIGN KEY (producto_id) REFERENCES producto(id)
);


CREATE TABLE IF NOT EXISTS detalle_pedido (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id        INT UNSIGNED   NOT NULL,
  cantidad         INT            NOT NULL,
  FOREIGN KEY (pedido_id) REFERENCES pedido(id)
);


CREATE TABLE IF NOT EXISTS detalle_pedido_producto (
  detalle_id       INT UNSIGNED   NOT NULL,
  producto_id      INT UNSIGNED   NOT NULL,
  PRIMARY KEY (detalle_id, producto_id),
  FOREIGN KEY (detalle_id)   REFERENCES detalle_pedido(id),
  FOREIGN KEY (producto_id)  REFERENCES producto(id)
);


CREATE TABLE IF NOT EXISTS detalle_pedido_combo (
  detalle_id       INT UNSIGNED   NOT NULL,
  combo_id         INT UNSIGNED   NOT NULL,
  PRIMARY KEY (detalle_id, combo_id),
  FOREIGN KEY (detalle_id) REFERENCES detalle_pedido(id),
  FOREIGN KEY (combo_id)   REFERENCES combo(id)
);


CREATE TABLE IF NOT EXISTS ingrediente (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(100)   NOT NULL,
  stock            INT            NOT NULL,
  precio           DECIMAL(10,2)  NOT NULL
);


CREATE TABLE IF NOT EXISTS ingredientes_extra (
  detalle_id       INT UNSIGNED   NOT NULL,
  ingrediente_id   INT UNSIGNED   NOT NULL,
  cantidad         INT            NOT NULL,
  PRIMARY KEY (detalle_id, ingrediente_id),
  FOREIGN KEY (detalle_id)     REFERENCES detalle_pedido(id),
  FOREIGN KEY (ingrediente_id) REFERENCES ingrediente(id)
);

INSERT INTO cliente (nombre, telefono, direccion) VALUES
('María López', '3001234567', 'Calle 10 #20-30, Bogotá'),
('Juan Pérez', '3107654321', 'Carrera 5 #45-67, Medellín'),
('Ana Gómez',  '3209876543', 'Av. Siempre Viva 742, Cali');

INSERT INTO metodo_pago (nombre) VALUES
('Efectivo'),
('Tarjeta Crédito'),
('Nequi');

INSERT INTO tipo_producto (nombre) VALUES
('Bebida'),
('Pizza'),
('Otros');

INSERT INTO producto (nombre, tipo_producto_id) VALUES
('Coca-Cola',1),
('Pizza Jamón Queso', 2),
('Papas Fritas',3);

INSERT INTO presentacion (nombre) VALUES
('Pequeña'),
('Mediana'),
('Grande');
INSERT INTO producto_presentacion (producto_id, presentacion_id, precio) VALUES
(1, 1, 5000),  
(1, 2, 7500),  
(1, 3, 13500),
(2, 1, 20000),  
(2, 2, 35000),  
(2, 3, 50000),
(3, 1, 10000),  
(3, 2, 14750),  
(3, 3, 20500);

INSERT INTO combo (nombre, precio) VALUES
('Pack Pizzas & Papas', 26500),
('Pack Bebida & Pizza', 24000),
('Combo Familiar', 65000);

INSERT INTO combo_producto (combo_id, producto_id) VALUES
(1, 2), (1, 3),
(2, 1), (2, 3),
(3, 1), (3, 2), (3, 3);

INSERT INTO ingrediente (nombre, stock, precio) VALUES
('Queso',    50, 2500),
('Bacon',    30, 3500),
('Aguacate', 20, 1500);

INSERT INTO pedido (fecha_recogida, total, cliente_id, metodo_pago_id) VALUES
('2025-06-10 12:00:00', 35000, 1, 1),
('2025-06-09 13:30:00', 50000, 2, 2),
('2025-06-08 18:45:00', 20000, 3, 3);

INSERT INTO detalle_pedido (pedido_id, cantidad) VALUES
(1, 2),
(1, 1),
(2, 3),
(3, 1),
(3, 2),
(3, 1);

INSERT INTO detalle_pedido_producto (detalle_id, producto_id) VALUES
(1, 1),
(3, 1),
(3, 3),
(4, 2),
(5, 2),
(6, 3);

INSERT INTO detalle_pedido_combo (detalle_id, combo_id) VALUES
(2, 1),
(5, 2),
(6, 3);

INSERT INTO ingredientes_extra (detalle_id, ingrediente_id, cantidad) VALUES
(1, 1, 1),
(3, 2, 2),
(4, 3, 1);

INSERT INTO factura(total, fecha, pedido_id, cliente_id) VALUES
(35000, '2025-06-10 12:05:00', 1, 1),
(50000, '2025-06-09 13:35:00', 2, 2),
(20000, '2025-06-08 18:50:00', 3, 3);