// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721 } from "../ERC721.sol";
import { ERC721Inventory } from "../utils/ERC721Inventory.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard.
 * Note: Tracks and limits mint supply.
 * @author https://github.com/nftyte
 */
contract ERC721Supply is ERC721 {
    using ERC721Inventory for uint256;

    // Supply counter, set to 1 to save gas during mint
    uint256 private _supply = 1;

    /**
     * @dev Returns the maximum number of tokens that can be minted.
     * Note: Based on {ERC721Inventory-BALANCE_BITSIZE}.
     */
    function _maxSupply() internal view virtual returns (uint256) {
        unchecked {
            return (1 << ERC721Inventory.BALANCE_BITSIZE) - 1;
        }
    }

    /**
     * @dev Returns the number of minted tokens.
     */
    function _mintedSupply() internal view virtual returns (uint256) {
        unchecked {
            return _supply - 1;
        }
    }

    /**
     * @dev See {ERC721-_mintTokens}.
     */
    function _mintTokens(address to, uint256 amount)
        internal
        virtual
        override
        returns (uint256 tokenId, uint256 maxTokenId)
    {
        unchecked {
            require(_mintedSupply() + amount < _maxSupply() + 1, "ERC721Supply: exceeds maximum supply");
            (tokenId, maxTokenId) = super._mintTokens(to, amount);

            _supply += amount;
        }
    }
}
