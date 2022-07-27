// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Optimint, ERC721Metadata } from "./Optimint.sol";
import { ERC721Enumerable, ERC721 } from "./token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev Gas optimized ERC721 implementation, including optional extensions.
 * @author https://github.com/nftyte
 */
contract OptimintEnumerable is Optimint, ERC721Enumerable {
    /**
     * @dev See {ERC721-_mintTokens}.
     */
    function _mintTokens(address to, uint256 amount)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (uint256, uint256)
    {
        return super._mintTokens(to, amount);
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        return super._burn(tokenId);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Metadata, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
