// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

contract UniswapLiquidityPoolHandler {
  using SafeMath for uint256;

  address public FACTORY_UNISWAP_TOKEN;
  address public ROUTER_UNISWAP_TOKEN;
  address public MULTISIG_WALLET;

  // ============== EVENT ==============
  event AddLiquidityUniswap(
    address provider,
    uint256 liquidity,
    uint256 amountAFee,
    uint256 amountBFee
  );
  event RemoveLiquidityUniswap(
    address provider,
    uint256 claimTokenA,
    uint256 claimTokenB,
    uint256 claimTimestamp
  );

  // ============== ERROR ==============
  error InvalidZeroAmount();

  // ============== MODIFIER ==============
  modifier onlyValidAmount(uint256 amount) {
    if (amount <= 0) revert InvalidZeroAmount();
    _;
  }

  constructor(
    address factoryUniswapTokenAddress,
    address routerUniswapTokenAddress,
    address multisigAddress
  ) {
    FACTORY_UNISWAP_TOKEN = factoryUniswapTokenAddress;
    ROUTER_UNISWAP_TOKEN = routerUniswapTokenAddress;
    MULTISIG_WALLET = multisigAddress;
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired
  ) external onlyValidAmount(amountADesired) onlyValidAmount(amountBDesired) {
    _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
  }

  function addLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external onlyValidAmount(amountADesired) onlyValidAmount(amountBDesired) {
    IERC20Permit(tokenA).permit(
      msg.sender,
      address(this),
      amountADesired,
      block.timestamp + 15 minutes,
      v,
      r,
      s
    );
    IERC20Permit(tokenB).permit(
      msg.sender,
      address(this),
      amountBDesired,
      block.timestamp + 15 minutes,
      v,
      r,
      s
    );
    _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
  }

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin
  ) external onlyValidAmount(liquidity) {
    _removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin);
  }

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    address pair = IUniswapV2Factory(FACTORY_UNISWAP_TOKEN).getPair(
      tokenA,
      tokenB
    );
    IERC20Permit(pair).permit(
      msg.sender,
      address(this),
      liquidity,
      block.timestamp + 15 minutes,
      v,
      r,
      s
    );
  }

  // ==================== INTERNAL FUNCTIONS ====================

  function _addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired
  ) internal {
    IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

    // Add Liquidity to Uniswap
    uint256 amountAFee = SafeMath.div(amountADesired, 1000); // 0.1% fee
    uint256 amountBFee = SafeMath.div(amountBDesired, 1000); // 0.1% fee

    IERC20(tokenA).approve(ROUTER_UNISWAP_TOKEN, amountADesired);
    IERC20(tokenB).approve(ROUTER_UNISWAP_TOKEN, amountBDesired);

    (, , uint256 liquidity) = IUniswapV2Router02(ROUTER_UNISWAP_TOKEN)
      .addLiquidity(
        tokenA,
        tokenB,
        SafeMath.sub(amountADesired, amountAFee),
        SafeMath.sub(amountBDesired, amountBFee),
        SafeMath.sub(amountADesired, amountAFee),
        SafeMath.sub(amountBDesired, amountBFee),
        msg.sender,
        block.timestamp + 15 minutes
      );

    IUniswapV2Router02(ROUTER_UNISWAP_TOKEN).addLiquidity(
      tokenA,
      tokenB,
      amountAFee,
      amountBFee,
      amountAFee,
      amountBFee,
      MULTISIG_WALLET,
      block.timestamp + 15 minutes
    );

    emit AddLiquidityUniswap(msg.sender, liquidity, amountAFee, amountBFee);
  }

  function _removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal {
    address pair = IUniswapV2Factory(FACTORY_UNISWAP_TOKEN).getPair(
      tokenA,
      tokenB
    );
    IERC20(pair).transferFrom(msg.sender, address(this), liquidity);

    // Remove Liquidity to Uniswap
    uint256 liquidityFee = SafeMath.div(liquidity, 1000); // 0.1% fee

    IERC20(pair).approve(ROUTER_UNISWAP_TOKEN, liquidity);
    IERC20(pair).approve(ROUTER_UNISWAP_TOKEN, liquidityFee);
    (uint256 amountA, uint256 amountB) = IUniswapV2Router02(
      ROUTER_UNISWAP_TOKEN
    ).removeLiquidity(
        tokenA,
        tokenB,
        liquidity,
        amountAMin,
        amountBMin,
        msg.sender,
        block.timestamp + 15 minutes
      );
    IUniswapV2Router02(ROUTER_UNISWAP_TOKEN).removeLiquidity(
      tokenA,
      tokenB,
      liquidityFee,
      SafeMath.div(amountAMin, 1000),
      SafeMath.div(amountBMin, 1000),
      MULTISIG_WALLET,
      block.timestamp + 15 minutes
    );

    emit RemoveLiquidityUniswap(msg.sender, amountA, amountB, block.timestamp);
  }
}
