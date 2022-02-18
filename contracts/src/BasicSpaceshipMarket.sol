// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./outerspace/interfaces/IOuterSpace.sol";
import "./outerspace/interfaces/IApprovalReceiver.sol";

contract BasicSpaceshipMarket is IApprovalReceiver {
    event SpaceshipsForSale(
        uint256 indexed location,
        address indexed owner,
        uint256 pricePerUnit,
        uint256 spaceshipsToKeep
    );

    event SpaceshipsSold(uint256 indexed location, address indexed fleetOwner, uint256 numSpaceships);

    struct SpaceshipSale {
        uint184 pricePerUnit;
        uint32 spaceshipsToKeep;
        uint40 timestamp;
    }

    mapping(uint256 => SpaceshipSale) internal _sales;

    IOuterSpace internal immutable _outerspace;

    constructor(IOuterSpace outerspace) {
        _outerspace = outerspace;
    }

    function onApprovedBy(address owner, bytes calldata data) external {
        require(msg.sender == address(_outerspace), "APPROVED_BY_EXPECT_OUTERSPACE");
        (uint256 location, uint184 pricePerUnit, uint32 spaceshipsToKeep) = abi.decode(
            data,
            (uint256, uint184, uint32)
        );
        _setSpaceshipsForSale(owner, location, pricePerUnit, spaceshipsToKeep);
    }

    function setSpaceshipsForSale(
        uint256 location,
        uint184 pricePerUnit,
        uint32 spaceshipsToKeep
    ) external {
        _setSpaceshipsForSale(msg.sender, location, pricePerUnit, spaceshipsToKeep);
    }

    function purchase(
        uint256 location,
        uint32 numSpaceships,
        address payable planetOwner,
        bytes32 toHash
    ) external payable {
        SpaceshipSale memory sale = _sales[location];
        (, uint40 ownershipStartTime) = _outerspace.ownerAndOwnershipStartTimeOf(location);

        require(sale.timestamp > ownershipStartTime, "OWNERSHIP_CHANGED_SALE_OUTDATED");

        uint256 toPay = numSpaceships * sale.pricePerUnit;
        require(msg.value >= toPay, "NOT_ENOUGH_FUND");
        planetOwner.transfer(toPay);
        if (msg.value > toPay) {
            payable(msg.sender).transfer(msg.value - toPay);
        }

        IOuterSpace.FleetLaunch memory launch;
        launch.fleetSender = planetOwner; // this is checked by outerspace
        launch.fleetOwner = msg.sender;
        launch.from = location;
        launch.quantity = numSpaceships;
        launch.toHash = toHash;
        _outerspace.sendFor(launch);

        IOuterSpace.Planet memory planetUpdated = _outerspace.getPlanetState(location);

        // TODO could update OuterSpace.sendFor function to actually specify the amount left, and then pay for that amount if smaller that what wanted
        require(planetUpdated.numSpaceships >= sale.spaceshipsToKeep, "TOO_MANY_SPACESHIPS_BOUGHT");

        emit SpaceshipsSold(location, msg.sender, numSpaceships);
    }

    // ----------------------------------------
    // INTERNAL
    // ----------------------------------------

    function _setSpaceshipsForSale(
        address seller,
        uint256 location,
        uint184 pricePerUnit,
        uint32 spaceshipsToKeep
    ) internal {
        address currentOwner = _outerspace.ownerOf(location);
        require(currentOwner == seller, "NOT_PLANET_OWNER");
        _sales[location].pricePerUnit = pricePerUnit;
        _sales[location].spaceshipsToKeep = spaceshipsToKeep;
        _sales[location].timestamp = uint40(block.timestamp);

        emit SpaceshipsForSale(location, currentOwner, pricePerUnit, spaceshipsToKeep);
    }
}
