import { Manifest } from "@openzeppelin/upgrades-core";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  TestingUSDC,
  TestingWETH,
  RibbonThetaVaultWithSwap,
  OptionsPremiumPricerInStables,
  ManualStrikeSelection,
} from "../typechain";

// Deploys a copy of all the contracts
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, ethers } = hre;
  const { admin, keeper, wallet } = await getNamedAccounts();
  const { provider } = hre.network;
  const manifest = await Manifest.forNetwork(provider);

  console.log("Before getContract");
  const usdc = await ethers.getContract<TestingUSDC>("TestingUSDC");
  const weth = await ethers.getContract<TestingWETH>("TestingWETH");
  const addressBook = await ethers.getContract<AddressBook>("AddressBook");
  const ribbonThetaVaultWithSwap =
    await ethers.getContract<RibbonThetaVaultWithSwap>(
      "RibbonThetaVaultWithSwap"
    );
  const optionsPremiumPricer =
    await ethers.getContract<OptionsPremiumPricerInStables>(
      "OptionsPremiumPricerInStables"
    );
  const manualStrikeSelection = await ethers.getContract<ManualStrikeSelection>(
    "ManualStrikeSelection"
  );

  console.log("002-wire-up-interdependencies is finished");

  return true;
};
func.id = "002-wire-up-interdependencies";
export default func;
