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
  TestingMathLib,
  EasyAuction,
  AddressBook,
  OtokenFactory,
  Controller,
  Whitelist,
  Oracle,
  GaussianCDF,
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
let math: TestingMathLib;
let cdf: GaussianCDF;
let auction: EasyAuction;

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
let mathAddr: string;
let cdfAddr: string;
let auctionAddr: string;

const provider = waffle.provider;
const AddressZero = ethers.constants.AddressZero;

function getTokenAmount(num: string): BigNumber {
  return ethers.utils.parseEther(num);
}

function getZ(num: string): BigNumber {
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

async function mineBlockAtTimestamp(timestamp: number): Promise<void> {
  await ethers.provider.send("evm_setNextBlockTimestamp", [timestamp]);
  await ethers.provider.send("evm_mine", []);
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
  math = await ethers.getContract("TestingMathLib");
  cdf = await ethers.getContract("GaussianCDF");
  auction = await ethers.getContract("EasyAuction");

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
  mathAddr = math.address;
  cdfAddr = cdf.address;
  auctionAddr = auction.address;
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

describe("OptionsPremiumPricerInStables", function () {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      expect(await pricer.optionId()).to.equal(
        "0xdfa4c666f67b671dba2d2cf7741a92bd2d871bd55fb6ef706acc30284618f986"
      );
      expect(await pricer.volatilityOracle()).to.equal(volOracleAddr);
      expect(await pricer.priceOracle()).to.equal(priceOracleAddr);
      expect(await pricer.stablesOracle()).to.equal(stableOracleAddr);
      expect(await pricer.getUnderlyingPrice()).to.equal(1863855809);
      const strikePrice = 2050000000;
      const currentTime = 1667548800;
      const expiry = currentTime + 3600 * 24 * 10;
      const isPut = false;
      await mineBlockAtTimestamp(currentTime);
      console.log("Current time: ", await latestTime());
      console.log("Expiry: ", expiry);
      console.log(
        "Premiusm: ",
        await pricer.getPremium(strikePrice, expiry, isPut)
      );
    });
  });
});

describe.only("TestingMathLib", function () {
  describe("Testing cdf & ncdf", () => {
    it("Should return the scaled cumulateive probabilities", async function () {
      console.log(
        "1e37",
        await math.getCDF(
          BigNumber.from("1000000000000000000000000000000000000")
        )
      );
      console.log(
        "2e37",
        await math.getCDF(
          BigNumber.from("2000000000000000000000000000000000000")
        )
      );
      console.log(
        "3e37",
        await math.getCDF(
          BigNumber.from("3000000000000000000000000000000000000")
        )
      );
      console.log(
        "4e37",
        await math.getCDF(
          BigNumber.from("4000000000000000000000000000000000000")
        )
      );
      console.log(
        "5e37",
        await math.getCDF(
          BigNumber.from("5000000000000000000000000000000000000")
        )
      );
      console.log(
        "5e38",
        await math.getCDF(
          BigNumber.from("50000000000000000000000000000000000000")
        )
      );
      console.log(
        "6e38",
        await math.getCDF(
          BigNumber.from("60000000000000000000000000000000000000")
        )
      );
      console.log(
        "7e38",
        await math.getCDF(
          BigNumber.from("70000000000000000000000000000000000000")
        )
      );
      console.log(
        "8e38",
        await math.getCDF(
          BigNumber.from("80000000000000000000000000000000000000")
        )
      );
      console.log(
        "1e39",
        await math.getCDF(
          BigNumber.from("100000000000000000000000000000000000000")
        )
      );
      console.log(
        "2e39",
        await math.getCDF(
          BigNumber.from("200000000000000000000000000000000000000")
        )
      );
      console.log(
        "3e39",
        await math.getCDF(
          BigNumber.from("300000000000000000000000000000000000000")
        )
      );
      console.log(
        "3.2e39",
        await math.getCDF(
          BigNumber.from("320000000000000000000000000000000000000")
        )
      );
      console.log(
        "3.3e39",
        await math.getCDF(
          BigNumber.from("320000000000000000000000000000000000000")
        )
      );
      console.log(
        "3.4e39",
        await math.getCDF(
          BigNumber.from("320000000000000000000000000000000000000")
        )
      );
    });
  });
  describe("Testing optimalExp", () => {
    it("Should return the scaled cumulateive probabilities", async function () {
      console.log(await math.getOptimalExp(BigNumber.from(0)));
    });
  });

  describe("Testing exp", () => {
    it("Should return the exponentiated values", async function () {
      console.log(await math.getExp(BigNumber.from(0)));
      console.log(await math.getExp(BigNumber.from(1)));
      console.log(await math.getExp(BigNumber.from(2)));
      console.log(await math.getExp(BigNumber.from(20000)));
    });
  });

  describe("Testing getNum", () => {
    it("Should return the original floating number from numerator", async function () {
      console.log(await math.getNum(BigNumber.from("36893488147419103232")));
      console.log(await math.getNum(BigNumber.from("36893488157419103232")));
      console.log(
        await math.getNum(BigNumber.from("42391158275216203514294433201"))
      );
      console.log(
        await math.getNum(BigNumber.from("10301051460877537453973547267843"))
      );
    });
  });
});

describe("GaussianCDF", () => {
  describe("CDF", () => {
    it("Should set the right initial parameters", async function () {
      console.log(await cdf.cdf(getZ("0")));
      console.log(await cdf.cdf(getZ("1")));
      console.log(await cdf.cdf(getZ("-1")));
      console.log(await cdf.cdf(getZ("-2")));
      console.log(await cdf.cdf(getZ("2")));
      console.log(await cdf.cdf(getZ("3")));
      console.log(await cdf.cdf(getZ("-3")));
      console.log(await cdf.cdf(getZ("4")));
      console.log(await cdf.cdf(getZ("-4")));
    });
  });
});

describe.only("GnosisAuction", () => {
  describe("deployment", () => {
    it("Should set the right initial parameters", async function () {
      expect(await auction.numUsers()).to.equal(0);
      expect(await auction.feeReceiverUserId()).to.equal(1);
      expect(await auction.auctionCounter()).to.equal(0);
      expect(await auction.feeNumerator()).to.equal(0);
      expect(await auction.FEE_DENOMINATOR()).to.equal(1000);
    });
  });
});
