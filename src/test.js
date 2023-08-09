const { ethers } = require("hardhat");

async function main() {
  const contract = "0x7f652e14b2740a2c1199964cef30cc7ea6b229c1";
  const tokenId = ethers.BigNumber.from(695).toHexString().substring(2);
  const contractAddressBytes = hexStringToByteArray(contract.substring(2)); // 去掉 '0x' 前缀
  const tokenIdBytes = hexStringToByteArray(tokenId);

  // 连接字节数组
  const combinedBytes = contractAddressBytes.concat(tokenIdBytes);

  // 计算哈希值
  const hash = ethers.utils.keccak256(ethers.utils.arrayify(combinedBytes));

  console.log(hash);
}

function hexStringToByteArray(hexString) {
  const byteArray = [];
  for (let i = 0; i < hexString.length; i += 2) {
    byteArray.push(parseInt(hexString.slice(i, i + 2), 16));
  }
  return byteArray;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
