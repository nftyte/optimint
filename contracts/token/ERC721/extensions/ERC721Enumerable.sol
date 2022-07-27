// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721, IERC165 } from "../ERC721.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { ERC721Inventory } from "../utils/ERC721Inventory.sol";
import { ERC721TokenId } from "../utils/ERC721TokenId.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Enumerable extension.
 */
contract ERC721Enumerable is ERC721, IERC721Enumerable {
    using ERC721Inventory for uint256;
    using ERC721TokenId for uint256;
    using ERC721TokenId for address;

    // Global enumeration index, set to 1 to save gas during mint
    uint256 private _supply = 1;
    
    // Burned supply counter, set to 1 to save gas during burn
    uint256 private _burnedSupply = 1;

    // Array with all minter addresses, used for enumeration
    mapping(uint256 => address) private _minters;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        unchecked {
            return _supply - _burnedSupply;
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256 tokenId) {
        unchecked {
            require(index++ < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
            uint256 supply = _supply - 1;

            for (uint i; i < supply; i++) {
                address minter = _minters[i];

                if (minter != address(0)) {
                    tokenId = minter.toTokenId();
                    uint256 maxTokenId = tokenId + _mintBalanceOf(minter);

                    while (tokenId < maxTokenId) {
                        if (ownerOf(tokenId) == owner && --index == 0) {
                            return tokenId;
                        }

                        tokenId++;
                    }
                }
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256 tokenId) {
        unchecked {
            require(index++ < totalSupply(), "ERC721Enumerable: global index out of bounds");
            uint256 supply = _supply - 1;

            for (uint i; i < supply; i++) {
                address minter = _minters[i];

                if (minter != address(0)) {
                    tokenId = minter.toTokenId();
                    uint256 maxTokenId = tokenId + _mintBalanceOf(minter);

                    while (tokenId < maxTokenId) {
                        if (_exists(tokenId) && --index == 0) {
                            return tokenId;
                        }

                        tokenId++;
                    }
                }
            }
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
        (tokenId, maxTokenId) = super._mintTokens(to, amount);

        unchecked {
            if (tokenId.index() == 0) {
                _minters[_supply - 1] = to;
            }

            _supply += amount;
        }
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        unchecked {
            _burnedSupply++;
        }
    }
}
