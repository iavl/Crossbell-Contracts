// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @dev Character ID not exists
error ErrCharacterNotExists(uint256 characterId);

/// @dev Not owner of address
error ErrNotAddressOwner();

/// @dev Caller is not the owner of character
error ErrNotCharacterOwner();

/// @dev Note has been locked
error ErrNoteLocked();

/// @dev Handle does not exist
error ErrHandleExists();

/// @dev Social token address does not exist
error ErrSocialTokenExists();

/// @dev Handle length too long or too short
error ErrHandleLengthInvalid();

/// @dev Handle contains invalid characters
error ErrHandleContainsInvalidCharacters();

/// @dev  Operator has not enough permission for this character
error ErrNotEnoughPermission();

/// @dev Operator has not enough permissions for this note
error ErrNotEnoughPermissionForThisNote();

/// @dev Target address already has primary character
error ErrTargetAlreadyHasPrimaryCharacter();

/// @dev ERC721 token does not exist
error ErrREC721NotExists();

/// @dev Note has been deleted
error ErrNoteIsDeleted();

/// @dev Note does not exist
error ErrNoteNotExists();

/// @dev Array length mismatch
error ErrArrayLengthMismatch();
