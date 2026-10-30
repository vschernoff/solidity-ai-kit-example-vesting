// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {TokenVesting} from "../src/TokenVesting.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TokenVestingTest is Test {
    MockERC20 internal token;
    TokenVesting internal vesting;

    address internal beneficiary = address(0xBEEF);
    uint256 internal amount = 1000e18;
    uint256 internal startTime;
    uint256 internal cliffTime;
    uint256 internal endTime;

    uint256 internal constant CLIFF_DURATION = 365 days;
    uint256 internal constant VESTING_DURATION = 4 * 365 days;

    function setUp() public {
        token = new MockERC20("Test Token", "TT", 18);
        startTime = block.timestamp;
        cliffTime = startTime + CLIFF_DURATION;
        endTime = startTime + VESTING_DURATION;

        vesting = new TokenVesting(
            IERC20(address(token)),
            beneficiary,
            amount,
            startTime,
            cliffTime,
            endTime
        );

        token.mint(address(vesting), amount);
    }

    // --- Constructor validation ---

    function test_constructorSetsImmutables() public view {
        assertEq(address(vesting.TOKEN()), address(token));
        assertEq(vesting.BENEFICIARY(), beneficiary);
        assertEq(vesting.AMOUNT(), amount);
        assertEq(vesting.START(), startTime);
        assertEq(vesting.CLIFF(), cliffTime);
        assertEq(vesting.END(), endTime);
        assertEq(vesting.released(), 0);
    }

    function test_revertIf_tokenIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(TokenVesting.ZeroAddress.selector, "token"));
        new TokenVesting(IERC20(address(0)), beneficiary, amount, startTime, cliffTime, endTime);
    }

    function test_revertIf_beneficiaryIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(TokenVesting.ZeroAddress.selector, "beneficiary"));
        new TokenVesting(IERC20(address(token)), address(0), amount, startTime, cliffTime, endTime);
    }

    function test_revertIf_amountIsZero() public {
        vm.expectRevert(TokenVesting.AmountIsZero.selector);
        new TokenVesting(IERC20(address(token)), beneficiary, 0, startTime, cliffTime, endTime);
    }

    function test_revertIf_cliffBeforeStart() public {
        vm.expectRevert(TokenVesting.CliffBeforeStart.selector);
        new TokenVesting(IERC20(address(token)), beneficiary, amount, startTime, startTime - 1, endTime);
    }

    function test_revertIf_endNotAfterCliff() public {
        vm.expectRevert(TokenVesting.EndNotAfterCliff.selector);
        new TokenVesting(IERC20(address(token)), beneficiary, amount, startTime, cliffTime, cliffTime);
    }

    // --- Vesting schedule ---

    function test_nothingVestedBeforeCliff() public view {
        assertEq(vesting.vestedAmount(), 0);
        assertEq(vesting.releasable(), 0);
    }

    function test_nothingVestedJustBeforeCliff() public {
        vm.warp(cliffTime - 1);
        assertEq(vesting.vestedAmount(), 0);
    }

    function test_vestingAtCliff() public {
        vm.warp(cliffTime);
        uint256 expected = (amount * CLIFF_DURATION) / VESTING_DURATION;
        assertEq(vesting.vestedAmount(), expected);
    }

    function test_vestingAtHalfway() public {
        vm.warp(startTime + VESTING_DURATION / 2);
        assertEq(vesting.vestedAmount(), amount / 2);
    }

    function test_fullyVestedAtEnd() public {
        vm.warp(endTime);
        assertEq(vesting.vestedAmount(), amount);
    }

    function test_fullyVestedAfterEnd() public {
        vm.warp(endTime + 365 days);
        assertEq(vesting.vestedAmount(), amount);
    }

    // --- Release ---

    function test_releaseRevertsBeforeCliff() public {
        vm.expectRevert(TokenVesting.NothingToRelease.selector);
        vesting.release();
    }

    function test_releaseAtCliff() public {
        vm.warp(cliffTime);
        uint256 expected = (amount * CLIFF_DURATION) / VESTING_DURATION;

        vesting.release();

        assertEq(token.balanceOf(beneficiary), expected);
        assertEq(vesting.released(), expected);
        assertEq(vesting.releasable(), 0);
    }

    function test_releaseEmitsEvent() public {
        vm.warp(cliffTime);
        uint256 expected = (amount * CLIFF_DURATION) / VESTING_DURATION;

        vm.expectEmit(true, false, false, false);
        emit TokenVesting.TokensReleased(expected);
        vesting.release();
    }

    function test_multipleReleases() public {
        vm.warp(cliffTime);
        vesting.release();
        uint256 firstRelease = token.balanceOf(beneficiary);

        vm.warp(startTime + VESTING_DURATION / 2);
        vesting.release();
        uint256 secondRelease = token.balanceOf(beneficiary) - firstRelease;

        vm.warp(endTime);
        vesting.release();
        uint256 thirdRelease = token.balanceOf(beneficiary) - firstRelease - secondRelease;

        assertEq(firstRelease + secondRelease + thirdRelease, amount);
        assertEq(token.balanceOf(beneficiary), amount);
        assertEq(vesting.released(), amount);
    }

    function test_releaseFullAmountAtEnd() public {
        vm.warp(endTime);
        vesting.release();
        assertEq(token.balanceOf(beneficiary), amount);
        assertEq(vesting.released(), amount);
    }

    function test_doubleReleaseReverts() public {
        vm.warp(cliffTime);
        vesting.release();

        vm.expectRevert(TokenVesting.NothingToRelease.selector);
        vesting.release();
    }

    function test_anyoneCanCallRelease() public {
        vm.warp(cliffTime);
        address caller = address(0xCAFE);
        vm.prank(caller);
        vesting.release();
        assertGt(token.balanceOf(beneficiary), 0);
    }

    // --- Fuzz tests ---

    function testFuzz_vestedNeverExceedsAmount(uint256 timestamp) public {
        timestamp = bound(timestamp, 0, type(uint128).max);
        vm.warp(timestamp);
        assertLe(vesting.vestedAmount(), amount);
    }

    function testFuzz_releasedNeverExceedsAmount(uint256 t1, uint256 t2) public {
        t1 = bound(t1, cliffTime, endTime);
        t2 = bound(t2, t1, endTime + 365 days);

        vm.warp(t1);
        vesting.release();

        vm.warp(t2);
        if (vesting.releasable() > 0) {
            vesting.release();
        }

        assertLe(vesting.released(), amount);
        assertEq(token.balanceOf(beneficiary), vesting.released());
    }

    function testFuzz_vestingIsMonotonic(uint256 t1, uint256 t2) public {
        t1 = bound(t1, 0, type(uint128).max);
        t2 = bound(t2, t1, type(uint128).max);

        vm.warp(t1);
        uint256 v1 = vesting.vestedAmount();

        vm.warp(t2);
        uint256 v2 = vesting.vestedAmount();

        assertGe(v2, v1);
    }

    function testFuzz_releaseAtEndGivesFullAmount(
        uint256 amount_,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) public {
        amount_ = bound(amount_, 1, type(uint128).max);
        cliffDuration = bound(cliffDuration, 1, 10 * 365 days);
        vestingDuration = bound(vestingDuration, cliffDuration + 1, cliffDuration + 10 * 365 days);

        uint256 s = block.timestamp;
        uint256 c = s + cliffDuration;
        uint256 e = s + vestingDuration;

        MockERC20 t = new MockERC20("T", "T", 18);
        TokenVesting v = new TokenVesting(IERC20(address(t)), beneficiary, amount_, s, c, e);
        t.mint(address(v), amount_);

        vm.warp(e);
        v.release();

        assertEq(t.balanceOf(beneficiary), amount_);
    }
}
