// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./lib/tick.sol";
import "./lib/Position.sol";
import "./lib/SafeCast.sol";
import "./Interfaces/IERC20.sol";

contract CLAMM {
    using SafeCast for uint256;
    using SafeCast for int256;

      struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        bool unlocked;
    }

    Slot0 public slot0;
    mapping (bytes32 => Position.Info) public positions;

    modifier lock(){
        require(slot0.unlocked, "locked");
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }

    address public immutable token0;
    address public immutable token1;
    uint24 public immutable fee;
    int24 public immutable tickSpacing;
    uint maxLiquidityPerTick;
    constructor(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ){
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        tickSpacing = _tickSpacing;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    }

    function initialize(uint160 sqrtPriceX96) external {
        require(slot0.sqrtPriceX96 == 0,"already initialze");

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            unlocked: true
        });
    }
    struct ModifyPositionParams {
        address owner;
        int24 tickLower;
        int24 tickUpper;
        int24 liquidityDelta;
    }

    function _modifyPositionPrams(
        ModifyPositionParams memory params) 
        private 
        returns (Position.Info storage position , int256 amount0,int256 amount1){
            return(positions[bytes32(0)], 0, 0);
        }

    function mint(
        address recepient,
        int24 tickLower,
        int24 tickUpper,
        int128 amount
    ) external lock returns (uint256 amount0, uint256 amount1){
        require(amount > 0,"amount = 0");
        (, int256 amoun0tInt, int256 amount1Int) = 
            _modifyPositionPrams(
                ModifyPositionParams({
                    owner: recepient,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: int24(amount)
                })

            ); 

        amount0 = uint256(amoun0tInt);
        amount1 = uint256(amount1Int);

        if (amount0 > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        }
    }



}