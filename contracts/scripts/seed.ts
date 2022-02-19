// import {getUnnamedAccounts, ethers} from 'hardhat';

// async function waitFor<T>(p: Promise<{wait: () => Promise<T>}>): Promise<T> {
//   const tx = await p;
//   try {
//     await ethers.provider.send('evm_mine', []); // speed up on local network
//   } catch (e) {}
//   return tx.wait();
// }

async function main() {
  // const others = await getUnnamedAccounts();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
