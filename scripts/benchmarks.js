const fs = require("fs");
const { join } = require("path");
const { deployable } = require("./libraries/deployable");

const TransferType = {
        OwnerToNonOwner: {
            label: "Owner to non-owner",
            transferTokens: [1],
        },
        OwnerToOwner: {
            label: "Owner to owner",
            transferTokens: [1],
        },
        MinterToNonOwner: {
            label: "Minter to non-owner",
            transferTokens: [1, 2, 3, 4, 5, 10, 50, 100],
        },
        MinterToOwner: {
            label: "Minter to owner",
            transferTokens: [1, 2, 3, 4, 5, 10, 50, 100],
        },
    },
    mintAmounts = [1, 2, 3, 4, 5, 10, 50, 100],
    contracts = ["Optimint", "OptimintEnumerable", "ERC721AMock"],
    results = Object.fromEntries(
        contracts.map((c) => [
            c,
            {
                mint: {},
                transfer: Object.fromEntries(
                    Object.keys(TransferType).map((k) => [k, {}])
                ),
            },
        ])
    );

async function benchmarks() {
    const [owner, ...accs] = await ethers.getSigners();

    let tx, receipt;

    for (let contractName of contracts) {
        const Contract = await deployable(contractName).contract();
        let contract = await Contract.deploy();
        tx = await contract.deployed();
        results[contractName].deploy = tx.deployTransaction.gasLimit;

        for (let amount of mintAmounts) {
            contract = await deployable(contractName).deploy();
            if (contractName == "ERC721AMock") {
                // Preliminary mint to reduce gas during benchmark
                await contract.connect(accs[accs.length - 1]).mint(1);
            }
            tx = await contract.mint(amount);
            receipt = await tx.wait();
            results[contractName].mint[amount] = receipt.gasUsed;
        }

        for (let k of Object.keys(TransferType)) {
            await Promise.all(
                TransferType[k].transferTokens.map((i) =>
                    transferBenchmark(contractName, owner, accs, parseInt(i), k)
                )
            );
        }

        console.log(`Completed benchmarks for ${contractName.replace("Mock", "")}`);
    }

    let res = `## Deployment\n\n${deployResults(results)}\n\n`;
    res += `## Mint\n\n${mintResults(results)}\n\n`;
    res += "## Transfer\n\n";
    for (let [k, { label }] of Object.entries(TransferType)) {
        res += `### ${label}\n\n${transferResults(results, k)}\n\n`;
    }

    console.log("Completed benchmarks, writing to file...\n");
    fs.writeFileSync(join(process.cwd(), "benchmarks.md"), res);
    console.log(res);
}

function deployResults(results) {
    let table = tableRow("Contract", "Deploy");
    table += "\n" + tableRow("---", "---");

    for (let [c, r] of Object.entries(results)) {
        table +=
            "\n" + tableRow(c.replace("Mock", ""), parseInt(r.deploy).toLocaleString());
    }

    return table;
}

function mintResults(results) {
    let table = tableRow("Contract", ...mintAmounts.map((m) => `Mint ${m}`));
    table += "\n" + tableRow("---", ...mintAmounts.map(() => "---"));

    for (let [c, r] of Object.entries(results)) {
        table +=
            "\n" +
            tableRow(
                c.replace("Mock", ""),
                ...mintAmounts.map((m) => parseInt(r.mint[m]).toLocaleString())
            );
    }

    return table;
}

function transferResults(results, k) {
    const transferTokens = TransferType[k].transferTokens;
    let table = tableRow("Contract", ...transferTokens.map((t) => `Token #${t}`));
    table += "\n" + tableRow("---", ...transferTokens.map(() => "---"));

    for (let [c, r] of Object.entries(results)) {
        table +=
            "\n" +
            tableRow(
                c.replace("Mock", ""),
                ...transferTokens.map((t) => parseInt(r.transfer[k][t]).toLocaleString())
            );
    }

    return table;
}

function tableRow(...values) {
    return `| ${values.join(" | ")} |`;
}

async function transferBenchmark(contractName, owner, accs, nthToken, transferType) {
    const tokens = {},
        contract = await deployable(contractName).deploy();
    await contract.mint(nthToken + 1);
    await new Promise((resolve) => {
        let count = 0;
        contract.on("Transfer", (from, to, tokenId) => {
            if (from == ethers.constants.AddressZero && to == owner.address) {
                tokens[tokenId.toHexString()] = tokenId;
                if (++count == nthToken + 1) {
                    resolve();
                }
            }
        });
    });

    let from, to;
    const tokenIds = Object.values(tokens);

    switch (TransferType[transferType]) {
        case TransferType.MinterToOwner:
            await contract.connect(accs[0]).mint(1);
        case TransferType.MinterToNonOwner:
            from = owner;
            to = accs[0];
            break;
        case TransferType.OwnerToOwner:
            await contract.connect(accs[1]).mint(1);
        case TransferType.OwnerToNonOwner:
            const transfers = [];
            for (let j = 0; j < nthToken + 1; j++) {
                transfers.push(
                    contract.transferFrom(owner.address, accs[0].address, tokenIds[j])
                );
            }
            await Promise.all(transfers);
            from = accs[0];
            to = accs[1];
            break;
    }

    const tx = await contract
            .connect(from)
            .transferFrom(from.address, to.address, tokenIds[nthToken - 1]),
        receipt = await tx.wait();
    results[contractName].transfer[transferType][nthToken] = receipt.gasUsed;
}

if (require.main === module) {
    benchmarks()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}
