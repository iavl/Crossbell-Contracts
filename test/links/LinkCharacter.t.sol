// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../contracts/Web3Entry.sol";
import "../../contracts/libraries/DataTypes.sol";
import "../../contracts/libraries/Error.sol";
import "../helpers/Const.sol";
import "../helpers/utils.sol";
import "../helpers/SetUp.sol";

contract LinkProfileTest is Test, SetUp, Utils {
    /* solhint-disable comprehensive-interface */
    function setUp() public {
        _setUp();

        // create character
        web3Entry.createCharacter(makeCharacterData(Const.MOCK_CHARACTER_HANDLE, alice));
        web3Entry.createCharacter(makeCharacterData(Const.MOCK_CHARACTER_HANDLE2, bob));
    }

    function testLinkCharacter() public {
        vm.startPrank(alice);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.LinkCharacter(
            alice,
            Const.FIRST_CHARACTER_ID,
            Const.SECOND_CHARACTER_ID,
            Const.FollowLinkType,
            1
        );
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // check linklist
        assertEq(linklist.ownerOf(1), alice);

        // link twice
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );
        vm.stopPrank();

        // periphery can link
        // the first input is msg.sender and the second input is tx.origin
        vm.prank(address(periphery), alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // check state
        assertEq(linklist.getOwnerCharacterId(1), Const.FIRST_CHARACTER_ID);
        assertEq(linklist.getLinkingCharacterIds(1).length, 1);
        assertEq(linklist.getLinkingCharacterIds(1)[0], 2);
        assertEq(linklist.getLinkingCharacterListLength(1), 1);
    }

    function testLinkCharacterFail() public {
        // case 1: NotEnoughPermission
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ErrNotEnoughPermission.selector));
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // case 2: CharacterNotExists
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ErrCharacterNotExists.selector, Const.THIRD_CHARACTER_ID)
        );
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.THIRD_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // case 3: link a burned character
        vm.prank(bob);
        web3Entry.burn(Const.SECOND_CHARACTER_ID);
        vm.expectRevert(
            abi.encodeWithSelector(ErrCharacterNotExists.selector, Const.SECOND_CHARACTER_ID)
        );
        vm.prank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );
    }

    function testUnlinkCharacter() public {
        vm.startPrank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // unlink
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.UnlinkCharacter(
            alice,
            Const.FIRST_CHARACTER_ID,
            Const.SECOND_CHARACTER_ID,
            Const.FollowLinkType
        );
        web3Entry.unlinkCharacter(
            DataTypes.unlinkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType
            )
        );

        // unlink twice
        web3Entry.unlinkCharacter(
            DataTypes.unlinkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType
            )
        );

        // unlink a non-existing character
        web3Entry.unlinkCharacter(
            DataTypes.unlinkCharacterData(Const.FIRST_CHARACTER_ID, 99999, Const.FollowLinkType)
        );
        vm.stopPrank();

        // check linklist
        assertEq(linklist.ownerOf(1), alice);

        // check state
        assertEq(linklist.getOwnerCharacterId(1), Const.FIRST_CHARACTER_ID);
        assertEq(linklist.getLinkingCharacterIds(1).length, 0);
        assertEq(linklist.getLinkingCharacterListLength(1), 0);
    }

    function testUnlinkCharacterFail() public {
        vm.prank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // unlink
        vm.expectRevert(abi.encodeWithSelector(ErrNotEnoughPermission.selector));
        vm.prank(bob);
        web3Entry.unlinkCharacter(
            DataTypes.unlinkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType
            )
        );
    }

    function testLinklistTotalSupply() public {
        vm.startPrank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // check linklist
        assertEq(linklist.ownerOf(1), alice);
        assertEq(linklist.characterOwnerOf(1), 1);
        assertEq(linklist.totalSupply(), 1);

        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.LikeLinkType,
                new bytes(0)
            )
        );

        // check linklist
        assertEq(linklist.ownerOf(2), alice);
        assertEq(linklist.characterOwnerOf(2), 1);
        assertEq(linklist.totalSupply(), 2);

        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                bytes32("LinkTypeAB"),
                new bytes(0)
            )
        );

        // check linklist
        assertEq(linklist.ownerOf(3), alice);
        assertEq(linklist.characterOwnerOf(3), 1);
        assertEq(linklist.totalSupply(), 3);
        vm.stopPrank();
    }

    function testCreateThenLinkCharacter() public {
        vm.prank(alice);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.LinkCharacter(alice, Const.FIRST_CHARACTER_ID, 3, Const.FollowLinkType, 1);
        web3Entry.createThenLinkCharacter(
            DataTypes.createThenLinkCharacterData(
                Const.FIRST_CHARACTER_ID,
                address(0x56789),
                Const.FollowLinkType
            )
        );

        // check state
        assertEq(linklist.getOwnerCharacterId(1), Const.FIRST_CHARACTER_ID);
        assertEq(linklist.getLinkingCharacterIds(1).length, 1);
        assertEq(linklist.getLinkingCharacterIds(1)[0], 3);
        assertEq(linklist.getLinkingCharacterListLength(1), 1);
    }
}
