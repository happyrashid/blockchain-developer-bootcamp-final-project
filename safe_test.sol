// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../forge-std/src/Test.sol";
import "../safe.sol";
 /**
   * @title ContractName
   * @dev ContractDescription
   * @custom:dev-run-script scripts/deploy_with_ethers.ts
   */
contract MultiSignerSafeTest is Test {
    MultiSignerSafe safe;
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address recipient = address(0x4);
    uint256 threshold = 2;

    function setUp() internal  {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;
        safe = new MultiSignerSafe(owners, threshold);
    }

    function testInitialization() public {
        assertEq(safe.getOwners().length, 3);
        assertEq(safe.threshold(), threshold);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        safe.submitTransaction(recipient, 1 ether, "0x");
        (address dest, uint256 value, , , uint256 confirmations) = safe.getTransaction(0);
        assertEq(dest, recipient);
        assertEq(value, 1 ether);
        assertEq(confirmations, 1);
    }

    function testConfirmTransaction() public {
        vm.prank(owner1);
        safe.submitTransaction(recipient, 1 ether, "0x");
        vm.prank(owner2);
        safe.confirmTransaction(0);
        (, , , , uint256 confirmations) = safe.getTransaction(0);
        assertEq(confirmations, 2);
    }

    function testExecuteTransaction() public {
        vm.deal(address(safe), 2 ether);
        vm.prank(owner1);
        safe.submitTransaction(recipient, 1 ether, "0x");
        vm.prank(owner2);
        safe.confirmTransaction(0);
        vm.prank(owner1);
        safe.executeTransaction(0);
        (, , , bool executed, ) = safe.getTransaction(0);
        assertTrue(executed);
        assertEq(recipient.balance, 1 ether);
    }

    function testFailExecuteWithoutThreshold() public {
        vm.deal(address(safe), 2 ether);
        vm.prank(owner1);
        safe.submitTransaction(recipient, 1 ether, "0x");
        vm.prank(owner1);
        safe.executeTransaction(0); // Should fail because threshold not met
    }
}
