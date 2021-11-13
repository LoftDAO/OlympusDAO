// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

contract StakingHelper {

    address public immutable staking;
    address public immutable OHM;

    constructor(address _staking, address _OHM) {
        require(_staking != address(0));
        staking = _staking;
        require(_OHM != address(0));
        OHM = _OHM;
    }

    function stake(uint _amount) external {
        IERC20(OHM).transferFrom(msg.sender, address(this), _amount);
        IERC20(OHM).approve(staking, _amount);
        IStaking(staking).stake(_amount, msg.sender);
        IStaking(staking).claim(msg.sender);
    }
}
