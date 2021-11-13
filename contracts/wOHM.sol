// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );

    function unstake( uint _amount, address _recipient ) external returns ( bool );

    function index() external view returns ( uint );
}

contract wOHM is ERC20 {
    using SafeERC20 for ERC20;
    using Address for address;

    address public immutable staking;
    address public immutable OHM;
    address public immutable sOHM;

    constructor(address _staking, address _OHM, address _sOHM)
        ERC20('Wrapped sOHM', 'wsOHM')
    {
        require(_staking != address(0));
        staking = _staking;
        require(_OHM != address(0));
        OHM = _OHM;
        require(_sOHM != address(0));
        sOHM = _sOHM;
    }

        /**
        @notice stakes OHM and wraps sOHM
        @param _amount uint
        @return uint
     */
    function wrapFromOHM(uint _amount) external returns (uint) {
        IERC20(OHM).transferFrom(msg.sender, address(this), _amount);

        IERC20(OHM).approve(staking, _amount); // stake OHM for sOHM
        IStaking(staking).stake(_amount, address(this));

        uint value = wOHMValue(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap sOHM and unstake OHM
        @param _amount uint
        @return uint
     */
    function unwrapToOHM(uint _amount) external returns (uint) {
        _burn(msg.sender, _amount);

        uint value = sOHMValue(_amount);
        IERC20(sOHM).approve(staking, value); // unstake sOHM for OHM
        IStaking(staking).unstake(value, address(this));

        IERC20(OHM).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice wrap sOHM
        @param _amount uint
        @return uint
     */
    function wrapFromsOHM(uint _amount) external returns (uint) {
        IERC20(sOHM).transferFrom(msg.sender, address(this), _amount);

        uint value = wOHMValue(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap sOHM
        @param _amount uint
        @return uint
     */
    function unwrapTosOHM(uint _amount) external returns (uint) {
        _burn(msg.sender, _amount);

        uint value = sOHMValue(_amount);
        IERC20(sOHM).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice converts wOHM amount to sOHM
        @param _amount uint
        @return uint
     */
    function sOHMValue(uint _amount) public view returns (uint) {
        return _amount * IStaking(staking).index() / 10**decimals();
    }

    /**
        @notice converts sOHM amount to wOHM
        @param _amount uint
        @return uint
     */
    function wOHMValue(uint _amount) public view returns (uint) {
        return _amount * 10**decimals() / IStaking(staking).index();
    }
}
