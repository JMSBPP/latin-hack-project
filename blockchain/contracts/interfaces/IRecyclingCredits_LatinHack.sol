// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1155} from "@papermoonio/openzeppelin-contracts-polkadot/contracts/token/ERC1155/IERC1155.sol";

interface IRecyclingCredits_LatinHack is IERC1155 {
    // Eventos personalizados del negocio
    event CertifierRoleGranted(address indexed certifier);
    event CertifierRoleRevoked(address indexed certifier);
    event CreditBatchCertified(uint256 indexed creditId, address indexed initialOwner, string materialType, uint256 weightKg, bytes32 proofHash);
    event CreditsRetired(uint256 indexed creditId, address indexed retiredBy, uint256 amount);

    struct CreditData {
        string materialType;
        uint256 totalWeightKg; // Peso total original del lote certificado
        uint256 timestamp;
        string location;
        bytes32 proofHash;
    }

    function grantCertifierRole(address certifier) external;
    function revokeCertifierRole(address certifier) external;
    function creditDetails(uint256 creditId) external view returns (string memory, uint256, uint256, string memory, bytes32);
    function certifyAndMintBatch(
        address creditOwner,
        string memory materialType,
        uint256 weightKg,
        string memory location,
        bytes32 proofHash
    ) external;
    function retireCredits(uint256 creditId, uint256 amount) external;
}
