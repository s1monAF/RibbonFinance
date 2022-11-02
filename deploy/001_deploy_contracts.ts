import { ethers, upgrades } from "hardhat";
import { BigNumber } from "ethers";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

// Deploys a copy of all the contracts
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployProxy } = upgrades;
  const { admin, keeper, wallet } = await getNamedAccounts();

  const baseDeployArgs = {
    from: admin,
    log: true,
    autoMine: true,
    // deterministicDeployment: !hre.network.tags.test,
    deterministicDeployment: false,
  };

  console.log(baseDeployArgs);

  // USDC
  const usdc = await deploy("TestingUSDC", {
    ...baseDeployArgs,
    args: [],
  });

  // WETH
  const weth = await deploy("TestingWETH", {
    ...baseDeployArgs,
    args: [],
  });

  // AddressBook
  const addressBook = await deploy("AddressBook", {
    ...baseDeployArgs,
    args: [],
  });

  // MarginVault
  const marginVault = await deploy("MarginVault", {
    ...baseDeployArgs,
    args: [],
  });

  // Controller
  const gammaController = await deploy("Controller", {
    ...baseDeployArgs,
    args: [],
    libraries: {
      MarginVault: marginVault.address,
    },
  });

  // MarginPool
  const marginPool = await deploy("MarginPool", {
    ...baseDeployArgs,
    args: [addressBook.address],
  });

  // Swap contract
  const swapContract = await deploy("Swap", {
    ...baseDeployArgs,
    args: [],
  });

  // Whitelist
  const whitelist = await deploy("Whitelist", {
    ...baseDeployArgs,
    args: [addressBook.address],
  });

  // OtokenFactory
  const otokenFactory = await deploy("OtokenFactory", {
    ...baseDeployArgs,
    args: [addressBook.address],
  });

  const optionId =
    "0xdfa4c666f67b671dba2d2cf7741a92bd2d871bd55fb6ef706acc30284618f986";

  const priceOracle = await deploy("TestPriceOracle", {
    ...baseDeployArgs,
    args: [1863855809],
  });

  const volatilityOracle = await deploy("TestVolOracle", {
    ...baseDeployArgs,
    args: [165000000],
  });

  const stableOracle = await deploy("TestStableOracle", {
    ...baseDeployArgs,
    args: [99991338],
  });

  const oracle = await deploy("Oracle", {
    ...baseDeployArgs,
    args: [],
  });

  const marginCalculator = await deploy("MarginCalculator", {
    ...baseDeployArgs,
    args: [oracle.address],
  });

  const optionsPremiumPricer = await deploy("OptionsPremiumPricerInStables", {
    ...baseDeployArgs,
    args: [
      optionId,
      volatilityOracle.address,
      priceOracle.address,
      stableOracle.address,
    ],
    gasLimit: 10000000,
  });

  const strikeSelection = await deploy("ManualStrikeSelection", {
    ...baseDeployArgs,
    args: [],
  });

  const shareMath = await deploy("ShareMath", {
    ...baseDeployArgs,
    args: [],
  });

  const vaultLifecycle = await deploy("VaultLifecycle", {
    ...baseDeployArgs,
    args: [],
  });

  const vaultLifecycleWithSwap = await deploy("VaultLifecycleWithSwap", {
    ...baseDeployArgs,
    args: [],
  });

  const ribbonThetaVaultWithSwap = await deploy("RibbonThetaVaultWithSwap", {
    ...baseDeployArgs,
    args: [
      weth.address,
      usdc.address,
      otokenFactory.address,
      gammaController.address,
      marginPool.address,
      swapContract.address,
    ],
    libraries: {
      VaultLifecycle: vaultLifecycle.address,
      VaultLifecycleWithSwap: vaultLifecycleWithSwap.address,
    },
    unsafeAllowLinkedLibraries: true,
    unsafeAllow: ["delegatecall"],
  });

  await deploy("TestingMathLib", {
    ...baseDeployArgs,
    args: [],
  });

  console.log("001-deploy-contracts is finished");

  return true;
};
func.id = "001-deploy-contracts";
export default func;
