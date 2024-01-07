const { ethers } = require("hardhat");
const keccak256 = require("keccak256");
const { MerkleTree } = require("merkletreejs");

// Create an array of ABI-encoded elements to put in the Merkle Tree
const list = [encodeLeaf(process.env.WALLET, ethers.utils.parseEther("200000"))];
// Using keccak256 as the hashing algorithm, create a Merkle Tree
// We use keccak256 because Solidity supports it
// We can use keccak256 directly in smart contracts for verification
// Make sure to sort the tree so it can be reproduced deterministically each time
const merkleTree = new MerkleTree(list, keccak256, {
    hashLeaves: true, // Hash each leaf using keccak256 to make them fixed-size
    sortPairs: true, // Sort the tree for determinstic output
    sortLeaves: true,
});

const networkConfig = {
    31337: {
        name: "localhost",
        registrar: process.env.WALLET,
        fallbackAddress: process.env.WALLET,
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
        merkleRoot: merkleTree.getHexRoot(),
    },
    5: {
        name: "goerli",
        registrar: process.env.WALLET,
        fallbackAddress: process.env.WALLET,
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
        merkleRoot: merkleTree.getHexRoot(),
    },
    97: {
        name: "BSCTest",
        registrar: process.env.WALLET,
        fallbackAddress: process.env.WALLET,
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
        merkleRoot: merkleTree.getHexRoot(),
    },
    56: {
        name: "BSC",
        registrar: process.env.WALLET,
        fallbackAddress: process.env.WALLET,
        fee: ethers.utils.parseEther("0.1"),
        payPercent: 60,
        merkleRoot: merkleTree.getHexRoot(),
    },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
    developmentChains,
    networkConfig,
};

function encodeLeaf(address, amount) {
    // Same as `abi.encodePacked` in Solidity
    return ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256"], // The datatypes of arguments to encode
        [address, amount] // The actual values
    );
}

// Compute the Merkle Root in Hexadecimal
const root = merkleTree.getHexRoot();

// Check for valid addresses
// for (let i = 0; i < list.length; i++) {
//     // Compute the Merkle Proof for `testAddresses[i]`
//     const leaf = keccak256(list[i]); // The hash of the node
//     const proof = merkleTree.getHexProof(leaf); // Get the Merkle Proof
//     console.log(proof);
// }
