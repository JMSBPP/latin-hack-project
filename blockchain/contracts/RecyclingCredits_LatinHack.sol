// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC1155} from "@papermoonio/openzeppelin-contracts-polkadot/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@papermoonio/openzeppelin-contracts-polkadot/contracts/access/Ownable.sol";
import {IRecyclingCredits_LatinHack} from "./interfaces/IRecyclingCredits_LatinHack.sol";

/**
 * @title RecyclingCredits_LatinHack
 * @author Equipo de desarrollo de E-co.lab
 * @notice Implementación mínima y autosuficiente de ERC-1155 para tokenizar créditos de reciclaje (RWA).
 * Cada lote de reciclaje certificado se convierte en un nuevo tipo de token con una cantidad específica.
 */
contract RecyclingCredits_LatinHack is IRecyclingCredits_LatinHack, ERC1155, Ownable{

    // --- Variables de Estado ---

    // Lógica de propiedad y control de acceso

    mapping(address => bool) public isCertifier;
    // Datos específicos del negocio: cada 'id' de token mapea a los detalles de un lote único

    mapping(uint256 => CreditData) public creditDetails;
    uint256 private _nextTokenId;


    // --- Modificadores ---

    modifier onlyCertifier() {
        require(isCertifier[msg.sender], "Caller is not a certifier");
        _;
    }

    // --- Constructor ---

    constructor(address initialAdmin, string memory uri) ERC1155(uri) Ownable(initialAdmin) {
        isCertifier[initialAdmin] = true;
        emit CertifierRoleGranted(initialAdmin);
    }

    // --- Gestión de Roles ---

    function grantCertifierRole(address certifier) external onlyOwner {
        isCertifier[certifier] = true;
        emit CertifierRoleGranted(certifier);
    }

    function revokeCertifierRole(address certifier) external onlyOwner {
        isCertifier[certifier] = false;
        emit CertifierRoleRevoked(certifier);
    }

    // --- Lógica Principal del Negocio ---

    /**
     * @notice (Certificador) Crea un nuevo tipo de token para un lote de reciclaje y acuña su cantidad total.
     */
    function certifyAndMintBatch(
        address creditOwner,
        string memory materialType,
        uint256 weightKg,
        string memory location,
        bytes32 proofHash
    ) external onlyCertifier {
        uint256 creditId = _nextTokenId++;
        
        creditDetails[creditId] = CreditData({
            materialType: materialType,
            totalWeightKg: weightKg,
            timestamp: block.timestamp,
            location: location,
            proofHash: proofHash
        });

        // Acuña la cantidad total de créditos para este nuevo lote/tipo
        _mint(creditOwner, creditId, weightKg, "");

        emit CreditBatchCertified(creditId, creditOwner, materialType, weightKg, proofHash);
    }
    /**
     * @notice (Dueño del token) Usa una cantidad de creditos para generar ingresos.
     */


    /**
     * @notice (Dueño del token) Retira (quema) una cantidad de créditos para certificar su uso.
     */
    function retireCredits(uint256 creditId, uint256 amount) external {
        // La quema se realiza desde la dirección del llamador de la función
        _burn(msg.sender, creditId, amount);
        emit CreditsRetired(creditId, msg.sender, amount);
    }


}