// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";

/**
 * @dev Mock ERC721A implementation used in benchmarks.
 */
contract ERC721AMock is ERC721A("ERC721A", "ERC721A") {
    function mint(uint256 amount) public payable virtual {
        _mint(msg.sender, amount);
    }
}
