function Deployable(contractName) {
    this.contractName = contractName;
}

Object.assign(Deployable.prototype, {
    async contract() {
        return await ethers.getContractFactory(this.contractName);
    },
    async at(address) {
        return await ethers.getContractAt(this.contractName, address);
    },
    async deploy(...args) {
        const contract = await this.contract();
        const deployed = await contract.deploy(...args);
        await deployed.deployed();
        return deployed;
    },
});

exports.deployer = (contractName) => ({
    async deploy(...args) {
        const deployable = new Deployable(await ethers.getContractFactory(contractName));
        return await deployable.deploy(...args);
    },
});

exports.deployable = (contractName) => new Deployable(contractName);
