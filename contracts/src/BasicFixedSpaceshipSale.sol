// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./outerspace/interfaces/IOuterSpace.sol";
import "./outerspace/interfaces/IApprovalReceiver.sol";

contract BasicFixedSpaceshipSale is IApprovalReceiver {
    event FixedSpaceshipsForSale(
        uint256 indexed location,
        address indexed owner,
        uint256 pricePerUnit,
        uint256 spaceshipsToSell
    );
    event FixedSaleCancelled(uint256 indexed location, address indexed owner);

    event SpaceshipsSold(uint256 indexed location, address indexed fleetOwner, uint256 numSpaceships);

    struct FixedSpaceshipSale {
        uint184 pricePerUnit;
        uint32 spaceshipsToSell;
        uint40 timestamp;
    }

    mapping(uint256 => FixedSpaceshipSale) internal _sales;

    IOuterSpace internal immutable _outerspace;

    constructor(IOuterSpace outerspace) {
        _outerspace = outerspace;
    }

    ///@dev useful to get data without any off-chain caching, but does not scale to many locations
    function getSales(uint256[] calldata locations) external view returns (FixedSpaceshipSale[] memory sales) {
        sales = new FixedSpaceshipSale[](locations.length);
        for (uint256 i = 0; i < locations.length; i++) {
            sales[i] = _sales[locations[i]];
        }
    }

    function onApprovalForAllBy(address owner, bytes calldata data) external {
        require(msg.sender == address(_outerspace), "APPROVEDBY_EXPECTS_OUTERSPACE");
        (uint256 location, uint184 pricePerUnit, uint32 spaceshipsToSell) = abi.decode(
            data,
            (uint256, uint184, uint32)
        );
        _setSpaceshipsForSale(owner, location, pricePerUnit, spaceshipsToSell);
    }

    function setSpaceshipsForSale(
        uint256 location,
        uint184 pricePerUnit,
        uint32 spaceshipsToSell
    ) external {
        _setSpaceshipsForSale(msg.sender, location, pricePerUnit, spaceshipsToSell);
    }

    function cancelSale(uint256 location) external {
        address currentOwner = _outerspace.ownerOf(location);
        require(currentOwner == msg.sender, "NOT_PLANET_OWNER");
        _sales[location].pricePerUnit = 0;
        _sales[location].spaceshipsToSell = 0;
        _sales[location].timestamp = 0;

        emit FixedSaleCancelled(location, currentOwner);
    }

    function purchase(
        uint256 location,
        uint32 numSpaceships,
        address payable fleetSender,
        bytes32 toHash
    ) external payable {
        FixedSpaceshipSale memory sale = _sales[location];
        (, uint40 ownershipStartTime) = _outerspace.ownerAndOwnershipStartTimeOf(location);

        require(sale.timestamp > ownershipStartTime, "OWNERSHIP_CHANGED_SALE_OUTDATED");

        require(numSpaceships <= sale.spaceshipsToSell, "PURCHASING_TOO_MANY");
        _sales[location].spaceshipsToSell = sale.spaceshipsToSell - numSpaceships;

        uint256 toPay = numSpaceships * sale.pricePerUnit;
        require(msg.value >= toPay, "NOT_ENOUGH_FUND");
        fleetSender.transfer(toPay);
        if (msg.value > toPay) {
            payable(msg.sender).transfer(msg.value - toPay);
        }

        IOuterSpace.FleetLaunch memory launch;
        launch.fleetSender = fleetSender; // this is checked by outerspace
        launch.fleetOwner = msg.sender;
        launch.from = location;
        launch.quantity = numSpaceships;
        launch.toHash = toHash;
        _outerspace.sendFor(launch);

        emit SpaceshipsSold(location, msg.sender, numSpaceships);
    }

    // ----------------------------------------
    // INTERNAL
    // ----------------------------------------

    function _setSpaceshipsForSale(
        address seller,
        uint256 location,
        uint184 pricePerUnit,
        uint32 spaceshipsToSell
    ) internal {
        address currentOwner = _outerspace.ownerOf(location);
        require(currentOwner == seller, "NOT_PLANET_OWNER");
        _sales[location].pricePerUnit = pricePerUnit;
        _sales[location].spaceshipsToSell = spaceshipsToSell;
        _sales[location].timestamp = uint40(block.timestamp);

        emit FixedSpaceshipsForSale(location, currentOwner, pricePerUnit, spaceshipsToSell);
    }
}
