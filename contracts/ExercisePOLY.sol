// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    function depositReserves(uint256 amount) external returns (bool);
}

interface IPOLY {
    function burnFrom(address account, uint256 amount) external;
}

contract ExercisePOLY is Ownable {
    using SafeERC20 for IERC20;

    // in hundreths i.e. 50 = 0.5%
    mapping(address => uint256) public percentCanVest;
    mapping(address => uint256) public amountClaimed;
    mapping(address => uint256) public maxAllowedToClaim;

    address public pOLY;
    address public OHM;
    address public DAI;

    address public treasury;

    constructor(address pOLY_, address ohm_, address dai_, address treasury_) {
        pOLY = pOLY_;
        OHM = ohm_;
        DAI = dai_;
        treasury = treasury_;
    }

    function setTerms(address vester, uint256 amountCanClaim, uint256 rate) external onlyOwner returns (bool) {
        require(amountCanClaim >= maxAllowedToClaim[vester], "cannot lower amount claimable");
        require(rate >= percentCanVest[vester], "cannot lower vesting rate");

        maxAllowedToClaim[vester] = amountCanClaim;
        percentCanVest[vester] = rate;

        return true;
    }

    function exercisePOLY(uint256 amountToExercise) external returns (bool) {
        require(getPOLYAbleToClaim(_msgSender()) >= amountToExercise, 'Not enough OHM vested');
        require(maxAllowedToClaim[_msgSender()] >= amountClaimed[_msgSender()] + amountToExercise, 'Claimed over max');

        IERC20(DAI).safeTransferFrom(_msgSender(), address(this), amountToExercise);
        IERC20(DAI).approve(treasury, amountToExercise);

        IVault(treasury).depositReserves(amountToExercise);
        IPOLY(pOLY).burnFrom(_msgSender(), amountToExercise);

        amountClaimed[_msgSender()] += amountToExercise;

        uint256 amountOHMToSend = amountToExercise / 1e9;

        IERC20(OHM).safeTransfer(_msgSender(), amountOHMToSend);

        return true;
    }

    function getPOLYAbleToClaim(address vester) public view returns (uint256) {
        return IERC20(OHM).totalSupply() * percentCanVest[vester] * 1e9 / 10000 - amountClaimed[vester];
    }
}
