// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Optimint, ERC721Metadata } from "./Optimint.sol";
import { ERC721Supply, ERC721 } from "./token/ERC721/extensions/ERC721Supply.sol";

/**
 * @dev Gas optimized ERC721 implementation, including the Metadata extension.
 * Note: Tracks and limits mint supply, see {ERC721Supply-_maxSupply}.
 * @author https://github.com/nftyte
 */
contract OptimintSupply is Optimint, ERC721Supply {
    /**
     * @dev See {ERC721-_mintTokens}.
     */
    function _mintTokens(address to, uint256 amount)
        internal
        virtual
        override(ERC721, ERC721Supply)
        returns (uint256, uint256)
    {
        return super._mintTokens(to, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Metadata)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
