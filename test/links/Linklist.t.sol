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

contract LinklistTest is Test, SetUp, Utils {
    event Transfer(address indexed from, uint256 indexed characterId, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /* solhint-disable comprehensive-interface */
    function setUp() public {
        _setUp();

        // create character
        web3Entry.createCharacter(makeCharacterData(Const.MOCK_CHARACTER_HANDLE, alice));
        web3Entry.createCharacter(makeCharacterData(Const.MOCK_CHARACTER_HANDLE2, bob));
    }

    function testMint() public {
        // link character
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Transfer(address(0), Const.FIRST_CHARACTER_ID, Const.FIRST_LINKLIST_ID);
        vm.prank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.LikeLinkType,
                new bytes(0)
            )
        );

        // check state
        assertEq(linklist.totalSupply(), 1);
        assertEq(linklist.balanceOf(alice), 1);
        assertEq(linklist.balanceOf(Const.FIRST_CHARACTER_ID), 1);
        assertEq(linklist.ownerOf(1), alice);
        assertEq(linklist.characterOwnerOf(1), Const.FIRST_CHARACTER_ID);
        assertEq(linklist.getOwnerCharacterId(1), 1);
        assertEq(linklist.Uri(1), "");
        assertEq(linklist.getLinkingCharacterIds(1).length, 1);
        assertEq(linklist.getLinkingCharacterIds(1)[0], 2);
        assertEq(linklist.getLinkType(1), Const.LikeLinkType);
    }

    function testMintFail() public {
        // not owner can't link character
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

        // check state
        assertEq(linklist.totalSupply(), 0);
    }

    function testSetUri() public {
        // link character
        vm.startPrank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );
        // case 1: set linklist uri by alice
        linklist.setUri(1, Const.MOCK_TOKEN_URI);
        // check linklist uri
        assertEq(linklist.Uri(1), Const.MOCK_TOKEN_URI);
        vm.stopPrank();

        // case 2: set linklist uri by web3Entry
        vm.prank(address(web3Entry));
        linklist.setUri(1, Const.MOCK_NEW_TOKEN_URI);
        // check linklist uri
        assertEq(linklist.Uri(1), Const.MOCK_NEW_TOKEN_URI);

        // check state
        string memory uri = linklist.Uri(1);
        assertEq(uri, Const.MOCK_NEW_TOKEN_URI);
    }

    function testSetUriFail() public {
        // link character
        vm.prank(alice);
        web3Entry.linkCharacter(
            DataTypes.linkCharacterData(
                Const.FIRST_CHARACTER_ID,
                Const.SECOND_CHARACTER_ID,
                Const.FollowLinkType,
                new bytes(0)
            )
        );

        // bob sets linklist uri
        vm.expectRevert(abi.encodeWithSelector(ErrCallerNotWeb3EntryOrNotOwner.selector));
        vm.prank(bob);
        linklist.setUri(1, Const.MOCK_TOKEN_URI);
    }

    function testTotalSupply(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100);
        vm.startPrank(address(web3Entry));

        for (uint256 i = 1; i <= amount; i++) {
            linklist.mint(Const.FIRST_CHARACTER_ID, Const.FollowLinkType);
        }

        uint256 totalSupply = linklist.totalSupply();
        uint256 expectedTotalSupply = amount;
        console.log(totalSupply);
        console.log(expectedTotalSupply);
        assertEq(totalSupply, expectedTotalSupply);
    }

    function testBalanceOf(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 100);
        vm.startPrank(address(web3Entry));

        for (uint256 i = 1; i <= amount; i++) {
            linklist.mint(Const.FIRST_CHARACTER_ID, Const.FollowLinkType);
        }

        uint256 balanceOfCharacter = linklist.balanceOf(1);
        assertEq(balanceOfCharacter, amount);

        uint256 balanceOfAddress = linklist.balanceOf(alice);
        assertEq(balanceOfAddress, amount);
    }
}
