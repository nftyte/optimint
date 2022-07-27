// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Metadata } from "./token/ERC721/extensions/ERC721Metadata.sol";

/**
 * @dev Gas optimized ERC721 implementation, including the Metadata extension.
 */
contract Optimint is ERC721Metadata("Optimint", "OPTI") {
    function mint(uint256 amount) public payable virtual {
        _mint(msg.sender, amount);
    }
}
