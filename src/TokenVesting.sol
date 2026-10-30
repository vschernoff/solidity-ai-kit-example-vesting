// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// @title TokenVesting
/// @author solidity-ai-kit-example
/// @notice Linear token vesting with a cliff. Tokens vest between start and end;
///         nothing is released before the cliff. Anyone may call release().
contract TokenVesting {
    /// @notice ERC-20 token being vested.
    IERC20 public immutable TOKEN;
    /// @notice Address that receives the vested tokens.
    address public immutable BENEFICIARY;
    /// @notice Total amount of tokens to vest.
    uint256 public immutable AMOUNT;
    /// @notice Timestamp when vesting begins accruing.
    uint256 public immutable START;
    /// @notice Timestamp before which nothing can be released.
    uint256 public immutable CLIFF;
    /// @notice Timestamp when vesting is fully complete.
    uint256 public immutable END;

    /// @notice Cumulative tokens already released to the beneficiary.
    uint256 public released;

    /// @notice Emitted when tokens are released.
    /// @param amount The number of tokens released.
    event TokensReleased(uint256 indexed amount);

    error ZeroAddress(string param);
    error AmountIsZero();
    error CliffBeforeStart();
    error EndNotAfterCliff();
    error NothingToRelease();
    error TransferFailed();

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 amount_,
        uint256 start_,
        uint256 cliff_,
        uint256 end_
    ) {
        if (address(token_) == address(0)) revert ZeroAddress("token");
        if (beneficiary_ == address(0)) revert ZeroAddress("beneficiary");
        if (amount_ == 0) revert AmountIsZero();
        if (cliff_ < start_) revert CliffBeforeStart();
        if (end_ <= cliff_) revert EndNotAfterCliff();

        TOKEN = token_;
        BENEFICIARY = beneficiary_;
        AMOUNT = amount_;
        START = start_;
        CLIFF = cliff_;
        END = end_;
    }

    /// @notice Returns the amount of tokens that can be released right now.
    function releasable() public view returns (uint256) {
        return vestedAmount() - released;
    }

    /// @notice Returns the total amount of tokens that have vested so far.
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < CLIFF) {
            return 0;
        }
        if (block.timestamp >= END) {
            return AMOUNT;
        }
        return (AMOUNT * (block.timestamp - START)) / (END - START);
    }

    /// @notice Releases vested tokens to the beneficiary.
    function release() external {
        uint256 unreleased = releasable();
        if (unreleased == 0) revert NothingToRelease();

        released += unreleased;
        emit TokensReleased(unreleased);

        if (!TOKEN.transfer(BENEFICIARY, unreleased)) revert TransferFailed();
    }
}
