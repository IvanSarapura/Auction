# Auction Smart Contract

He desarrollado un contrato inteligente que simula una subasta donde los usuarios puede hacer multiples ofertas y competir por la victoria.

## Descripción general

El contrato `Auction.sol` implementa un sistema descentralizado de subasta donde:
- Las personas pueden hacer ofertas enviando Ether.
- Cada oferta tiene que ser por lo menos 5% más alta que la anterior para que se trate de una oferta válida, de lo contrario no podrá realizarse dicha oferta.
- La subasta se extiende automáticamente 10 minutos cuando un usuario realiza una oferta durante los últimos 10 minutos de la subasta.
- Al finalizar la subasta las ofertas perdedoras se devuelven a los usuarios y la oferta ganadora se transfiere al propietario.

## Variables de estado

### Variables principales
- **`propietario`**: Es la dirección del usuario que inicializó la subasta y quien la podrá administrar.
- **`tiempoSubasta`**: Timestamp que indica cuándo termina la subasta.
- **`subastaActiva`**: Es un buleano que indica cuando la subasta se encuentra en curso.

### Variables de ofertas
- **`mejorOferta`**: Es el monto más alto que se haya ofertado hasta el momento.
- **`mejorOfertante`**: La dirección del usuarui que hizo la mejor oferta.
- **`balance`**: Registra cuánto Ether ha depositado cada usuario.
- **`ofertas`**: Array que almacena en una lista todas las ofertas realizadas por los usuarios.
- **`ofertantesUnicos`**: Lista de todas las direcciones de los usuarios que han participado.

### Constantes
- **`INCREMENTO_MINIMO`** = 5: Cada oferta nueva tiene que ser 5% más alta que la anterior.
- **`COMISION_GAS`** = 2: Se cobra una comisión del 2% para cubrir el costo del gas. 
- **`EXTENSION_OFERTA`** = 10 minutos: Tiempo que se extiende la subasta cuando hay ofertas cercanas a su final.

## Funciones principales

### `constructor()` 
- **Description**: Inicializa el contrato al desplegarlo.
- **Lo que pasa**: 
  - Establece como propietario al usuario que ejecuta el contrato.
  - Establece una duración inicial para la subasta de 10 minutos.
  - Indica mediante un buleano que la subasta esta activa.

### `ofertar()`
- Esta función es `payable`, lo cual significa que puede recibir dinero.
- Solo funciona si la subasta está activa.
- **Lógica**:
  1. Verifica que la nueva oferta sea por lo menos 5% más alta que la anterior mejor oferta.
  2. Actualiza los valores para indicar la nueva mejor oferta y el nuevo mejor ofertante.
  3. Registra al usuario si es la primera vez que realiza una oferta.
  4. Actualiza el balance del usuario sumándole su nueva oferta.
  5. Extiende el tiempo de la subasta si la oferta ocurre cercana al final de la subasta.
  6. Emite un evento para indicar que hubo una nueva oferta.

### `devolverDepositos()`
- Solo el propietario puede ejecutar esta función.
- Solo se podrá ejecutar esta función cuando la subasta se encuentra activa.
- **Description**: Reintegra los Ether ofertados a los usuarios que no ganaron.
- **Lógica**:
  1. Verifica a todos los participantes de la subasta.
  2. Si el balance del usuario es menor que el del mejor ofertante, se le reintegra su Ether.
  3. Se descuenta la comisión del 2% para cubrir el gas.
  4. Se transfiere el resto del balance al propietario del contrato.

### `reembolsoParcial()`
- Cualquier usuario puede llamar a esta función mientras la subasta esté activa.
- **Description**: Permite a los usuarios retirar el exceso de sus depósitos anteriores.
- **Lógica**:
  1. Busca todas las ofertas realizadas por el usuario.
  2. Calcula la diferencia entre su balance total y su oferta actual.
  3. Le devuelve solo el exceso, pero su oferta actual sigue activa.

### `terminarSubasta()`
- Solo el propietario puede ejecutar esta función.
- **Description**: Finaliza oficialmente la subasta.
- **Requisito**: Solo funciona después de que haya expirado el tiempo de la subasta.
- **Efecto**: Indica que la subasta está inactiva y emite el evento de subasta finalizada.

### `mostrarGanador()`
- Al tratarse de una función `view` no gasta gas.
- **Retorna**: La dirección y el monto del ganador de la subasta.
- **Description**: Permite consultar el usuario ganador y el monto ganador.

### `listaOfertas()`
- Al tratarse de una función `view` no gasta agas.
- **Retorna**: Toda la lista de ofertas que se han realizado.
- **Description**: Permite ver el historial completo de ofertas realizadas.

## Eventos

### `nuevaOferta` 
- **Cuando se emite**: Cada vez que se hace una oferta válida.
- **Parámetros**: 
  - `ofertante`: Quién hizo la oferta
  - `oferta`: Monto ofertado
  - `momentoOferta`: Timestamp de cuándo se hizo

### `subastaFinalizada`

- **Cuando se emite**: Cuando el propietario termina la subasta oficialmente.  
- **Parámetros**:
  - `mejorOfertante`: Dirección del ganador
  - `mejorOferta`: Monto ganador

## Como usar mi contrato

### Para participar en la subasta:
1. Usa la función `ofertar()` enviando Ether. Esta oferta debe ser como mínimo 5% mayor que la oferta anterior.
2. Si el usuario ya había ofertado antes y quiere retirar el Ether de dicha oferta anterior, debe usarse la función `reembolsoParcial()`.  
3. Consultando la función `mostrarGanador()` puede verse quien va ganando.

### Para el propietario de la subasta, quien ejecuta el contrato:
1. Debe esperar que se termine el tiempo de la subasta. 
2. Llama a la función `terminarSubasta()` para desactivar todo oficialmente.
3. Llama a la función `devolverDepositos()` para que se reintegre el Ether a los usuarios perdedores.

---
*Desarrollado como parte del Módulo 2 de ETH KIPU* 