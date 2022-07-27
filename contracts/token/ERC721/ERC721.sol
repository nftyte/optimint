// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC721Inventory } from "./utils/ERC721Inventory.sol";
import { ERC721TokenId } from "./utils/ERC721TokenId.sol";
import { ERC721Receiver } from "./utils/ERC721Receiver.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * excluding optional extensions.
 * Note: Modified from OpenZeppelin Contracts, see:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is Context, ERC165, IERC721 {
    using ERC721Inventory for uint256;
    using ERC721TokenId for uint256;
    using ERC721TokenId for address;
    using ERC721Receiver for address;
    using Address for address;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _inventories;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _inventories[owner].balance();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address owner) {
        if ((owner = _owners[tokenId]) == address(0)) {
            address minter = tokenId.minter();
            if (_inventories[minter].has(tokenId.index())) {
                owner = minter;
            }
        }

        require(owner != address(0), "ERC721: invalid token ID");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);

        if (to.isContract()) {
            require(
                to.checkOnERC721Received(msg.sender, from, tokenId, data),
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        if (_owners[tokenId] == address(0)) {
            return _inventories[tokenId.minter()].has(tokenId.index());
        }
        
        return true;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `amount` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - `to` cannot mint more than {_maxMintBalance} tokens.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 amount) internal virtual {
        _safeMint(to, amount, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 amount, bytes memory data) internal virtual {
        if (to.isContract()) {
            (uint256 tokenId, uint256 maxTokenId) = _mintTokens(to, amount);

            unchecked {
                while (tokenId < maxTokenId) {
                    emit Transfer(address(0), to, tokenId);
                    require(
                        to.checkOnERC721Received(msg.sender, address(0), tokenId++, data),
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                }
            }
        } else {
            _mint(to, amount);
        }
    }

    /**
     * @dev Mints `amount` tokens and transfers them to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` cannot mint more than {_maxMintBalance} tokens.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 amount) internal virtual {
        (uint256 tokenId, uint256 maxTokenId) = _mintTokens(to, amount);

        unchecked {
            while (tokenId < maxTokenId) {
                emit Transfer(address(0), to, tokenId++);
            }
        }
    }

    /**
     * @dev Mints `amount` tokens into `to`'s inventory.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` cannot mint more than {_maxMintBalance} tokens.
     */
    function _mintTokens(address to, uint256 amount) internal virtual returns (uint256 tokenId, uint256 maxTokenId) {
        require(to != address(0), "ERC721: mint to the zero address");
        uint256 minted = _mintBalanceOf(to);

        unchecked {
            require(minted + amount < _maxMintBalance() + 1, "ERC721: mint balance exceeded");
            tokenId = to.toTokenId() | minted;
            maxTokenId = tokenId + amount;
        }

        _inventories[to] = _inventories[to].add(amount);
    }
    
    /**
     * @dev Returns the number of tokens minted by `owner`'s account.
     */
    function _mintBalanceOf(address minter) internal view virtual returns (uint256) {
        return _inventories[minter].current();
    }

    /**
     * @dev Returns the maximum number of tokens that can be minted by an account.
     */
    function _maxMintBalance() internal view virtual returns (uint256) {
        return ERC721Inventory.SLOTS_PER_INVENTORY;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        // Clear approvals
        if (_tokenApprovals[tokenId] != address(0)) {
            _approve(address(0), tokenId);
        }

        if (_owners[tokenId] == owner) {
            delete _owners[tokenId];
            unchecked {
                _inventories[owner]--;
            }
        } else {
            _inventories[owner] = _inventories[owner].remove(tokenId.index());
        }

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        if (_tokenApprovals[tokenId] != address(0)) {
            _approve(address(0), tokenId);
        }

        unchecked {
            if (_owners[tokenId] == from) {
                _inventories[from]--;
            } else {
                _inventories[from] = _inventories[from].remove(tokenId.index());
            }

            _owners[tokenId] = to;
            _inventories[to]++;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
}
