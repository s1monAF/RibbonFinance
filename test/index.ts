import { expect } from "chai";
import { BigNumber, Contract, Signer } from "ethers";
import {
  deployments,
  ethers,
  getNamedAccounts,
  getUnnamedAccounts,
  waffle,
} from "hardhat";
import {
  TestingUSDC,
  TestingWETH,
  TestPriceOracle,
  TestVolOracle,
  TestStableOracle,
  AddressBook,
  OtokenFactory,
  Controller,
  Whitelist,
  Oracle,
  RibbonThetaVaultWithSwap,
  OptionsPremiumPricerInStables,
  ManualStrikeSelection,
} from "../typechain";

let admin: Signer;
let user: Signer;
let keeper: Signer;
let wallet: Signer;
let accounts: Signer[];

let adminAddr: string;
let userAddr: string;
let keeperAddr: string;
let walletAddr: string;

let usdc: TestingUSDC;
let weth: TestingWETH;
let vault: RibbonThetaVaultWithSwap;
let pricer: OptionsPremiumPricerInStables;
let factory: OtokenFactory;
let strikeSelection: ManualStrikeSelection;
let controller: Controller;
let addressbook: AddressBook;
let priceOracle: TestPriceOracle;
let volOracle: TestVolOracle;
let stableOracle: TestStableOracle;
let whitelist: Whitelist;
let oracle: Oracle;

let controllerAddr: string;
let pricerAddr: string;
let factoryAddr: string;
let addressbookAddr: string;
let strikeSelectionAddr: string;
let priceOracleAddr: string;
let volOracleAddr: string;
let stableOracleAddr: string;
let whitelistAddr: string;
let oracleAddr: string;

const provider = waffle.provider;
const AddressZero = ethers.constants.AddressZero;

function getTokenAmount(num: string): BigNumber {
  return ethers.utils.parseEther(num);
}

async function latestTime(): Promise<number> {
  const rslt = await latestBlock();
  return rslt.ts;
}

async function latestBlock(): Promise<{ num: number; ts: number }> {
  const latestBlock = await provider.getBlock("latest");
  return { num: latestBlock.number, ts: latestBlock.timestamp };
}

async function fastForward(time: number): Promise<void> {
  await ethers.provider.send("evm_mine", []); // force mine the next block
  await ethers.provider.send("evm_increaseTime", [time]); // add `time` seconds
  await ethers.provider.send("evm_mine", []); // force mine the next block
}

beforeEach("load deployment fixture", async function () {
  await deployments.fixture();

  ({ admin, user, keeper } = await ethers.getNamedSigners());
  ({
    admin: adminAddr,
    user: userAddr,
    keeper: keeperAddr,
  } = await getNamedAccounts());
  [walletAddr] = await getUnnamedAccounts();
  wallet = await ethers.getSigner(walletAddr);
  accounts = await ethers.getUnnamedSigners();
  factory = await ethers.getContract("OtokenFactory");

  vault = await ethers.getContract("RibbonThetaVaultWithSwap");
  pricer = await ethers.getContract("OptionsPremiumPricerInStables");
  strikeSelection = await ethers.getContract("ManualStrikeSelection");
  controller = await ethers.getContract("Controller");
  addressbook = await ethers.getContract("AddressBook");
  priceOracle = await ethers.getContract("TestPriceOracle");
  volOracle = await ethers.getContract("TestVolOracle");
  stableOracle = await ethers.getContract("TestStableOracle");
  oracle = await ethers.getContract("Oracle");

  whitelist = await ethers.getContract("Whitelist");

  addressbookAddr = addressbook.address;
  factoryAddr = factory.address;
  pricerAddr = pricer.address;
  controllerAddr = controller.address;
  strikeSelectionAddr = strikeSelection.address;
  priceOracleAddr = priceOracle.address;
  volOracleAddr = volOracle.address;
  stableOracleAddr = stableOracle.address;
  oracleAddr = oracle.address;
  whitelistAddr = whitelist.address;
});

describe("Vault", function () {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      expect(await vault.overriddenStrikePrice()).to.equal(0);
      expect(await vault.lastStrikeOverrideRound()).to.equal(0);
      expect(await vault.liquidityGauge()).to.equal(AddressZero);
      expect(await vault.currentOtokenPremium()).to.equal(AddressZero);
      expect(await vault.vaultPauser()).to.equal(AddressZero);
      expect(await vault.optionsPremiumPricer()).to.equal(AddressZero); // why
      expect(await vault.strikeSelection()).to.equal(AddressZero); // why?
      expect(await vault.lastStrikeOverrideRound()).to.equal(0);
      expect(await vault.overriddenStrikePrice()).to.equal(0);
      expect(await vault.auctionDuration()).to.equal(0);
      expect(await vault.optionAuctionID()).to.equal(0);
      expect(await vault.premiumDiscount()).to.equal(0);
      expect(await vault.currentOtokenPremium()).to.equal(0);
      expect(await vault.lastQueuedWithdrawAmount()).to.equal(0);
      expect(await vault.optionsPurchaseQueue()).to.equal(AddressZero);
      expect(await vault.currentQueuedWithdrawShares()).to.equal(0);
      expect(await vault.OTOKEN_FACTORY()).to.equal(factoryAddr);

      console.log(await vault.optionState());
    });
  });

  describe("commitNextOption", () => {
    it("Should be able to commit the next option", async function () {});
  });
});

describe("Controller", function () {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      expect(await controller.addressbook()).to.equal(AddressZero); // why?
      expect(await controller.whitelist()).to.equal(AddressZero); // why?
      expect(await controller.oracle()).to.equal(AddressZero); // why?
      expect(await controller.calculator()).to.equal(AddressZero);
      expect(await controller.pool()).to.equal(AddressZero);
    });
  });

  describe("commitNextOption", () => {
    it("Should be able to commit the next option", async function () {});
  });
});

describe("PriceOracle", function () {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      expect(await priceOracle.latestAnswer()).to.equal(1863855809);
      expect(await priceOracle.decimals()).to.equal(8);
    });
  });
});

describe("volOracle", function () {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      const optionId =
        "0xdfa4c666f67b671dba2d2cf7741a92bd2d871bd55fb6ef706acc30284618f986";
      expect(await volOracle.annualizedVol(optionId)).to.equal(165000000);
      expect(await volOracle.decimals()).to.equal(8);
    });
  });
});

describe("stableOracle", function () {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      expect(await stableOracle.latestAnswer()).to.equal(99991338);
      expect(await stableOracle.decimals()).to.equal(8);
    });
  });
});
