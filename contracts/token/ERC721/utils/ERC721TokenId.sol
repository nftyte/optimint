// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token id utilities
 */
library ERC721TokenId {
    uint256 constant MINTER_OFFSET = 8;
    uint256 constant INDEX_BITMASK = (1 << MINTER_OFFSET) - 1; // 0xFF

    function toTokenId(address owner) internal pure returns (uint256) {
        return uint256(uint160(owner)) << MINTER_OFFSET;
    }

    function index(uint256 tokenId) internal pure returns (uint256) {
        return tokenId & INDEX_BITMASK;
    }

    function minter(uint256 tokenId) internal pure returns (address) {
        return address(uint160(tokenId >> MINTER_OFFSET));
    }
}
