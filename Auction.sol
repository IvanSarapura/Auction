// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Auction Contract
 * @author Iván
 * @notice Smart contract for managing auctions with bids, deposits, and refunds.
*/

contract Auction {

    // ========== STATE VARIABLES ==========

    /// @dev Contract owner
    address private propietario;

    /// @dev Auction information
    uint256 public tiempoSubasta;
    bool public subastaActiva;

    /// @dev Current best bid
    uint256 private mejorOferta;
    address private mejorOfertante;

    /// @dev Constants
    uint256 private constant INCREMENTO_MINIMO = 5;
    uint256 private constant COMISION_GAS = 2;
    uint256 private constant EXTENSION_OFERTA = 10 minutes;

    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor that initializes the contract.
     */
    constructor() {
        propietario = msg.sender;
        tiempoSubasta = block.timestamp + 10 minutes;
        subastaActiva = true;
    }

    // ========== DATA STRUCTURES ==========

    /**
     * @dev Data structure to store offers.
     * @param ofertante The address of the bidder.
     * @param oferta The amount of the offer.
     * @param momentoOferta The timestamp of the offer.
     */
    struct Oferta {
        address ofertante;
        uint256 oferta;
        uint256 momentoOferta;
    }

    /// @dev Mapping to store the balance of each bidder.
    mapping(address => uint256) private balance;

    /// @dev Arrays to store the offers and the bidders.
    Oferta[] public ofertas;
    address[] public ofertantesUnicos;

    // ========== MODIFIERS ==========

    /**
     * @dev Modifier to check if the caller is the owner.
     */
    modifier soloPropietario() {
        require(msg.sender == propietario, "Solo el propietario puede ejecutar esta funcion");
        _;
    }

    /**
     * @dev Modifier to check if the auction is active.
     */
    modifier subastaEnCurso() {
        require(subastaActiva == true, "The auction is not active");
        _;
    }

    /**
     * @dev Modifier to check if the auction is finished.
     */
    modifier subastaTerminada() {
        require(subastaActiva == false, "The auction is active");
        _;
    }

    // ========== OFFER FUNCTION ==========

    /**
     * @dev Function to make an offer.
     * @notice The offer must be greater than the minimum offer (5% increment).
     * The function automatically handles bid validation, bidder registration, and auction time extension.
     */
    function ofertar() external subastaEnCurso payable {

        uint256 _valorOferta = msg.value;
        uint256 _ofertaMinima = mejorOferta + (mejorOferta * INCREMENTO_MINIMO / 100);
        address _addrOfertante = msg.sender;
        bool _ofertanteRegistrado = false;

        // Check if the offer is greater than the minimum offer with 5% increment.
        if (_valorOferta > _ofertaMinima) {
            mejorOfertante = _addrOfertante;
            mejorOferta = _valorOferta;

            // Check if the bidder is registered.
            for (uint256 i = 0; i < ofertas.length; i++) {
                if (_addrOfertante == ofertas[i].ofertante) {
                    ofertas[i].oferta = _valorOferta;
                    ofertas[i].momentoOferta = block.timestamp;
                    _ofertanteRegistrado = true;
                    break;
                }
            }

            // If the bidder is not registered, add the offer to the array.
            if (!_ofertanteRegistrado) {
                ofertas.push(Oferta(_addrOfertante, _valorOferta, block.timestamp));
            }

            // If the bidder is not registered, add the bidder to the array.
            if (balance[_addrOfertante] == 0) {
                ofertantesUnicos.push(_addrOfertante);
            }

            // Add the offer to the balance of the bidder.
            balance[_addrOfertante] += _valorOferta;

            // Emit the event of the new offer.
            emit nuevaOferta(_addrOfertante, _valorOferta, block.timestamp);

            // If the auction is about to end, extend the auction time by 10 minutes.
            if (block.timestamp >= (tiempoSubasta - EXTENSION_OFERTA)) {
                tiempoSubasta = block.timestamp + EXTENSION_OFERTA;
            }

        } else {
            // If the offer is not greater than the minimum offer with 5% increment, revert the transaction.
              revert("The offer is too low");
        }
    }

    // ========== WITHDRAW FUNCTION ==========

    /**
     * @dev Function to return the deposits of the bidders who did not make the best offer.
     * @notice The function can only be called by the owner when the auction is finished.
     * Returns deposits to losing bidders minus gas commission, and transfers remaining balance to owner.
     */
    function devolverDepositos() external soloPropietario subastaTerminada {
        uint256 _valorDevolver;
        uint256 _mejorOferta = mejorOferta;

        // Loop through the bidders and return the deposits of the bidders who did not make the best offer.
        for (uint256 i = 0; i < ofertantesUnicos.length; i++) {
            // If the balance of the bidder is less than the best offer, return the deposit.
            if (balance[ofertantesUnicos[i]] < _mejorOferta) {
                // Calculate the amount to return subtracting the gas commission.
                _valorDevolver = balance[ofertantesUnicos[i]] - (balance[ofertantesUnicos[i]] * COMISION_GAS / 100);
                balance[ofertantesUnicos[i]] = 0;
                payable(ofertantesUnicos[i]).transfer(_valorDevolver);
            }
        }
        payable(propietario).transfer(address(this).balance);
    }

    // ========== PARTIAL REFUND FUNCTION ==========

    /**
     * @dev Function to return the bidder's remaining deposits when he made another higher bid.
     * @notice The function can only be called by the bidder when the auction is active.
     * Allows bidders to withdraw excess funds from previous bids while keeping their current bid active.
     */
    function reembolsoParcial() external subastaEnCurso {
        uint256 _valorDevolver;
        address _extractor = msg.sender;
        bool _ofertaEncontrada = false;
        uint256 i;

        // Loop through the offers and determine if the bidder has made an offer previously.
        for (i = 0; i < ofertas.length; i++) {
            // If the bidder has made an offer previously, break the loop.
            if (ofertas[i].ofertante == _extractor) {
                _ofertaEncontrada = true;
                break;
            }
        }

        // If the bidder has not made an offer previously, revert the transaction.
        require(_ofertaEncontrada, "The user does not have any offers registered");

        // Calculate the amount to return.
        _valorDevolver = balance[_extractor] - ofertas[i].oferta;

        // If the amount to return is greater than 0, return the amount.
        require(_valorDevolver > 0, "The user does not have any values to withdraw");

        // Subtract the amount to return from the balance of the bidder.
        balance[_extractor] = balance[_extractor] - _valorDevolver;
        
        payable(_extractor).transfer(_valorDevolver);
    }

    // ========== FUNCTION TO END THE AUCTION ==========

    /**
     * @dev Function to end the auction.
     * @notice The function can only be called by the owner when the auction is finished.
     */
    function terminarSubasta() external soloPropietario {
        require(block.timestamp > tiempoSubasta, "La subasta aun esta activa. Espera a que termine.");
        subastaActiva = false;
        emit subastaFinalizada(mejorOfertante, mejorOferta);
    }

    // ========== FUNCTION TO SHOW THE WINNER ==========

    /**
     * @dev Function to show the winner of the auction.
     * @return mejorOfertante The address of the winner.
     * @return mejorOferta The amount of the best offer.
     */
    function mostrarGanador() external view returns (address, uint256) {
        return (mejorOfertante, mejorOferta);
    }

    // ========== FUNCTION TO SHOW THE LIST OF OFFERS ==========

    /**
     * @dev Function to show the list of offers.
     * @return ofertas The list of offers.
     */
    function listaOfertas() external view returns (Oferta[] memory) {
        return ofertas;
    }

    // ========== EVENTS ==========

    /**
     * @dev Event to emit when a new offer is made.
     * @param ofertante The address of the bidder.
     * @param oferta The amount of the offer.
     * @param momentoOferta The timestamp of the offer.
     */
    event nuevaOferta(address indexed ofertante, uint256 indexed oferta, uint256 momentoOferta);

    /**
     * @dev Event to emit when the auction is finished.
     * @param mejorOfertante The address of the winner.
     * @param mejorOferta The amount of the best offer.
     */
    event subastaFinalizada(address indexed mejorOfertante, uint256 mejorOferta);
}