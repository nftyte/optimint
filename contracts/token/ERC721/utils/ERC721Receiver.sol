// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ERC721 token receiver utilities
 * @author https://github.com/nftyte
 */
library ERC721Receiver {
    function checkOnERC721Received(
        address to,
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (
            bytes4 retval
        ) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(reason, 0x20), mload(reason))
                }
            }
        }
    }
}
