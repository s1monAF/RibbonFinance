import { BigNumber } from "ethers";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  TestingUSDC,
  TestingWETH,
  AddressBook,
  Controller,
  VaultLifecycle,
  VaultLifecycleWithSwap,
  RibbonThetaVaultWithSwap,
  OptionsPremiumPricerInStables,
  ManualStrikeSelection,
} from "../typechain";

// Deploys a copy of all the contracts
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { admin, keeper, wallet } = await getNamedAccounts();
  const { deploy } = deployments;

  const baseDeployArgs = {
    from: admin,
    log: true,
    autoMine: true,
    // deterministicDeployment: !hre.network.tags.test,
    deterministicDeployment: false,
  };

  const usdc = await ethers.getContract<TestingUSDC>("TestingUSDC");
  const weth = await ethers.getContract<TestingWETH>("TestingWETH");
  const addressBook = await ethers.getContract<AddressBook>("AddressBook");
  const controller = await ethers.getContract<Controller>("Controller");
  const marginVault = await ethers.getContract<MarginVault>("MarginVault");
  const vault = await ethers.getContract<RibbonThetaVaultWithSwap>(
    "RibbonThetaVaultWithSwap"
  );
  const optionsPremiumPricer =
    await ethers.getContract<OptionsPremiumPricerInStables>(
      "OptionsPremiumPricerInStables"
    );
  const vaultLifecycle = await ethers.getContract<VaultLifecycle>(
    "VaultLifecycle"
  );
  const vaultLifecycleWithSwap =
    await ethers.getContract<VaultLifecycleWithSwap>("VaultLifecycleWithSwap");

  const strikeSelection = await ethers.getContract<ManualStrikeSelection>(
    "ManualStrikeSelection"
  );
  const ribbonThetaVaultWithSwap =
    await ethers.getContract<RibbonThetaVaultWithSwap>(
      "RibbonThetaVaultWithSwap"
    );

  const initParams = {
    _owner: admin,
    _keeper: keeper,
    _feeRecipient: wallet,
    _managementFee: 0,
    _performanceFee: 0,
    _tokenName: "Ribbon AVAX Theta Vault",
    _tokenSymbol: "rAVAX-THETA",
    _optionsPremiumPricer: optionsPremiumPricer.address,
    _strikeSelection: strikeSelection.address,
  };

  const vaultParams = {
    isPut: false,
    decimals: 18,
    asset: weth.address,
    underlying: weth.address,
    minimumSupply: 10000000000,
    cap: BigNumber.from("200000000000000000000000"),
  };

  const RibbonThetaVault = await ethers.getContractFactory(
    "RibbonThetaVaultWithSwap",
    {
      libraries: {
        VaultLifecycle: vaultLifecycle.address,
        VaultLifecycleWithSwap: vaultLifecycleWithSwap.address,
      },
    }
  );

  const GammaController = await ethers.getContractFactory("Controller", {
    libraries: {
      MarginVault: marginVault.address,
    },
  });

  const vaultArgs = [initParams, vaultParams];
  const vaultData = RibbonThetaVault.interface.encodeFunctionData(
    "initialize",
    vaultArgs
  );
  const controllerArgs = [addressBook.address, admin];
  const controllerData = GammaController.interface.encodeFunctionData(
    "initialize",
    controllerArgs
  );
  const vaultProxy = await deploy("AdminUpgradeabilityProxy", {
    ...baseDeployArgs,
    args: [ribbonThetaVaultWithSwap.address, admin, vaultData],
  });
  const controllerProxy = await deploy("AdminUpgradeabilityProxy", {
    ...baseDeployArgs,
    args: [controller.address, admin, controllerData],
  });

  console.log(`RibbonThetaVaultWithSwap @ ${vaultProxy.address}`);
  console.log(`Controller @ ${controllerProxy.address}`);

  console.log("003-initial-configurations is finished");
  return true;
};
func.id = "003-initial-configurations";
export default func;
