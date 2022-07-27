# Optimint Hardhat Implementation

Optimint is a gas-optimized ERC721 reference implementation that's based on OpenZeppelin Contracts, and requires only 1 SSTORE operation per batch-mint. Please see the [benchmarks](./benchmarks.md) file to compare gas-usage.

**Note:** We use OpenZeppelin Contracts as a base, but these optimizations can be utilized in other implemenations.

## Optimized Gas

`Optimint` gas optimization is achieved by storing owner addresses inside token identifiers, instead of writing them to storage:

```Solidity
uint tokenId = (uint(owner) << x) | N;
ownerOf(tokenId) = address(tokenId >> x);
```

We commit a token owner's address to storage only after the token's been transferred for the first time:

```Solidity
ownerOf(tokenId) = _owners[tokenId];
```

### Limitations

- Total supply should be limited based on the `ERC721Inventory.BALANCE_BITSIZE` setting. For example, if it's set to `16`, then supply should be limited to `type(uint16).max`.
The `ERC721Supply` extension is provided to enforce this limitation, and its `_maxSupply` method can be overridden to enforce a lower one.
- The maximum number of tokens a single address can mint is limited based on `ERC721Inventory.SLOTS_PER_INVENTORY`. It's set to `232` by default, but may change when updating other settings. You can enforce a lower limit by overriding `ERC721._maxMintBalance`.
- Enumerability isn't trivial.

### Enumerability

This repo includes an `ERC721Enumerable` implementation that can be used to provide on-chain enumerability. While most interactions remain unaffected, gas usage on mint is a little higher than ERC721A's. See [benchmarks](./benchmarks.md) for more details.

## Benchmarks

You can run the benchmarks locally:

```console
npx hardhat run scripts/benchmarks.js
```

**Note:** Benchmarks may take a minute to complete.

## Contributations

All contribuations are welcome! Feel free to open a PR or an issue.

## License

MIT license. Anyone can use or modify this software for their purposes.
