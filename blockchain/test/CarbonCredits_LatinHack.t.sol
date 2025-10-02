// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {CarbonCredits_LatinHack} from "../src/CarbonCredits_LatinHack.sol";
import {ICarbonCredits_LatinHack} from "../src/interfaces/ICarbonCredits_LatinHack.sol";

contract CarbonCredits_LatinHackTest is Test {
    CarbonCredits_LatinHack public carbonCredits;
    
    address public owner;
    address public certifier;
    address public verifier;
    address public organization;
    address public company;
    
    bytes32 public constant proofHash = 0x123456789012345678901234567890123456789012345678901234567890abcd;
    uint256 public constant FIRST_CREDIT_ID = 0;

    function setUp() public {
        owner = makeAddr("owner");
        certifier = makeAddr("certifier");
        verifier = makeAddr("verifier");
        organization = makeAddr("organization");
        company = makeAddr("company");
        
        vm.prank(owner);
        carbonCredits = new CarbonCredits_LatinHack(owner);
    }

    // --- Deployment and Role Management Tests ---
    
    function test_Deployment_SetsCorrectAdmin() public {
        assertTrue(carbonCredits.hasRole(carbonCredits.DEFAULT_ADMIN_ROLE(), owner));
    }
    
    function test_Deployment_GrantsCertifierRoleToOwner() public {
        assertTrue(carbonCredits.hasRole(carbonCredits.CERTIFIER_ROLE(), owner));
    }
    
    function test_GrantCertifierRole_Success() public {
        vm.prank(owner);
        carbonCredits.grantCertifierRole(certifier);
        
        assertTrue(carbonCredits.hasRole(carbonCredits.CERTIFIER_ROLE(), certifier));
    }
    
    function test_RevokeCertifierRole_Success() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        carbonCredits.revokeCertifierRole(certifier);
        vm.stopPrank();
        
        assertFalse(carbonCredits.hasRole(carbonCredits.CERTIFIER_ROLE(), certifier));
    }
    
    function test_GrantVerifierRole_Success() public {
        vm.prank(owner);
        carbonCredits.grantVerifierRole(verifier);
        
        assertTrue(carbonCredits.hasRole(carbonCredits.VERIFIER_ROLE(), verifier));
    }
    
    function test_RevokeVerifierRole_Success() public {
        vm.startPrank(owner);
        carbonCredits.grantVerifierRole(verifier);
        carbonCredits.revokeVerifierRole(verifier);
        vm.stopPrank();
        
        assertFalse(carbonCredits.hasRole(carbonCredits.VERIFIER_ROLE(), verifier));
    }
    
    function test_GrantCertifierRole_RevertWhen_NotAdmin() public {
        vm.prank(certifier);
        vm.expectRevert();
        carbonCredits.grantCertifierRole(company);
    }
    
    function test_RevokeCertifierRole_RevertWhen_NotAdmin() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        vm.prank(company);
        vm.expectRevert();
        carbonCredits.revokeCertifierRole(certifier);
    }

    // --- Credit Certification and Minting Tests ---
    
    function test_CertifyAndMintCarbonCredit_Success() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 co2eAmount = 1000;
        
        vm.expectEmit(true, true, true, true);
        emit ICarbonCredits_LatinHack.CreditCertified(
            FIRST_CREDIT_ID, 
            organization, 
            "VCS", 
            co2eAmount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            co2eAmount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        assertEq(carbonCredits.balanceOf(organization, FIRST_CREDIT_ID), co2eAmount);
        
        (string memory methodology, uint256 amount, uint256 timestamp, string memory location, bytes32 hash) = 
            carbonCredits.creditDetails(FIRST_CREDIT_ID);
        assertEq(methodology, "VCS");
        assertEq(amount, co2eAmount);
        assertEq(location, "Amazon Rainforest");
        assertEq(hash, proofHash);
    }
    
    function test_CertifyAndMintCarbonCredit_RevertWhen_NotCertifier() public {
        vm.prank(company);
        vm.expectRevert();
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            1000, 
            "Amazon Rainforest", 
            proofHash
        );
    }
    
    function test_CertifyAndMintCarbonCredit_RevertWhen_ZeroAddress() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        vm.prank(certifier);
        vm.expectRevert();
        carbonCredits.certifyAndMintCarbonCredit(
            address(0), 
            "VCS", 
            1000, 
            "Amazon Rainforest", 
            proofHash
        );
    }

    // --- Credit Retirement Tests ---
    
    function test_RetireCarbonCredits_Success() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 totalAmount = 1000;
        uint256 retireAmount = 300;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            totalAmount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.expectEmit(true, true, true, true);
        emit ICarbonCredits_LatinHack.CreditRetired(FIRST_CREDIT_ID, organization, retireAmount);
        
        vm.prank(organization);
        carbonCredits.retireCredit(FIRST_CREDIT_ID, retireAmount);
        
        assertEq(carbonCredits.balanceOf(organization, FIRST_CREDIT_ID), totalAmount - retireAmount);
    }
    
    function test_RetireCarbonCredits_RevertWhen_InsufficientBalance() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 totalAmount = 1000;
        uint256 retireAmount = totalAmount + 1;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            totalAmount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(organization);
        vm.expectRevert();
        carbonCredits.retireCredit(FIRST_CREDIT_ID, retireAmount);
    }

    // --- ERC-1155 Functionality Tests ---
    
    function test_Transfer_Success() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 amount = 1000;
        uint256 transferAmount = 300;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            amount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(organization);
        carbonCredits.safeTransferFrom(organization, company, FIRST_CREDIT_ID, transferAmount, "");
        
        assertEq(carbonCredits.balanceOf(organization, FIRST_CREDIT_ID), amount - transferAmount);
        assertEq(carbonCredits.balanceOf(company, FIRST_CREDIT_ID), transferAmount);
    }
    
    function test_Transfer_RevertWhen_InsufficientBalance() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 amount = 1000;
        uint256 transferAmount = amount + 1;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            amount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(organization);
        vm.expectRevert();
        carbonCredits.safeTransferFrom(organization, company, FIRST_CREDIT_ID, transferAmount, "");
    }
    
    function test_Transfer_RevertWhen_ZeroAddress() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 amount = 1000;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            amount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(organization);
        vm.expectRevert();
        carbonCredits.safeTransferFrom(organization, address(0), FIRST_CREDIT_ID, 100, "");
    }
    
    function test_Burn_Success() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 amount = 1000;
        uint256 burnAmount = 200;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            amount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(organization);
        carbonCredits.burn(organization, FIRST_CREDIT_ID, burnAmount);
        
        assertEq(carbonCredits.balanceOf(organization, FIRST_CREDIT_ID), amount - burnAmount);
    }
    
    function test_Burn_RevertWhen_InsufficientBalance() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 amount = 1000;
        uint256 burnAmount = amount + 1;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            amount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(organization);
        vm.expectRevert();
        carbonCredits.burn(organization, FIRST_CREDIT_ID, burnAmount);
    }
    
    function test_Burn_RevertWhen_NotOwner() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        uint256 amount = 1000;
        
        vm.prank(certifier);
        carbonCredits.certifyAndMintCarbonCredit(
            organization, 
            "VCS", 
            amount, 
            "Amazon Rainforest", 
            proofHash
        );
        
        vm.prank(company);
        vm.expectRevert();
        carbonCredits.burn(organization, FIRST_CREDIT_ID, 100);
    }

    // --- Event Tests ---
    
    function test_CertifierRoleGranted_Event() public {
        vm.expectEmit(true, false, false, false);
        emit ICarbonCredits_LatinHack.CertifierRoleGranted(certifier);
        
        vm.prank(owner);
        carbonCredits.grantCertifierRole(certifier);
    }
    
    function test_CertifierRoleRevoked_Event() public {
        vm.startPrank(owner);
        carbonCredits.grantCertifierRole(certifier);
        vm.stopPrank();
        
        vm.expectEmit(true, false, false, false);
        emit ICarbonCredits_LatinHack.CertifierRoleRevoked(certifier);
        
        vm.prank(owner);
        carbonCredits.revokeCertifierRole(certifier);
    }
    
    function test_VerifierRoleGranted_Event() public {
        vm.expectEmit(true, false, false, false);
        emit ICarbonCredits_LatinHack.VerifierRoleGranted(verifier);
        
        vm.prank(owner);
        carbonCredits.grantVerifierRole(verifier);
    }
    
    function test_VerifierRoleRevoked_Event() public {
        vm.startPrank(owner);
        carbonCredits.grantVerifierRole(verifier);
        vm.stopPrank();
        
        vm.expectEmit(true, false, false, false);
        emit ICarbonCredits_LatinHack.VerifierRoleRevoked(verifier);
        
        vm.prank(owner);
        carbonCredits.revokeVerifierRole(verifier);
    }
}