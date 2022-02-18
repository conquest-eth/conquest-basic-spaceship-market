// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

interface ImportingOuterSpaceEvents {
    event PlanetStake(
        address indexed acquirer,
        uint256 indexed location,
        uint32 numSpaceships,
        int40 travelingUpkeep,
        uint32 overflow,
        uint256 stake
    );
    event FleetSent(
        address indexed fleetSender,
        address indexed fleetOwner,
        uint256 indexed from,
        address operator,
        uint256 fleet,
        uint32 quantity,
        uint32 newNumSpaceships,
        int40 newTravelingUpkeep,
        uint32 newOverflow
    );

    event FleetArrived(
        uint256 indexed fleet,
        address indexed fleetOwner,
        address indexed destinationOwner,
        uint256 destination,
        bool gift,
        uint32 fleetLoss,
        uint32 planetLoss,
        uint32 inFlightFleetLoss,
        uint32 inFlightPlanetLoss,
        bool won,
        uint32 newNumspaceships,
        int40 newTravelingUpkeep,
        uint32 newOverflow
    );

    event TravelingUpkeepReductionFromDestruction(
        uint256 indexed origin,
        uint256 indexed fleet,
        uint32 newNumspaceships,
        int40 newTravelingUpkeep,
        uint32 newOverflow
    );

    event PlanetReset(uint256 indexed location);

    event PlanetExit(address indexed owner, uint256 indexed location);

    event ExitComplete(address indexed owner, uint256 indexed location, uint256 stake);

    event RewardSetup(uint256 indexed location, address indexed giver, uint256 rewardId);
    event RewardToWithdraw(address indexed owner, uint256 indexed location, uint256 indexed rewardId);

    event StakeToWithdraw(address indexed owner, uint256 newStake);

    event Initialized(uint32 minX, uint32 maxX, uint32 minY, uint32 maxY, bytes32 genesis);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // TODO use it
    event Transfer(address indexed from, address indexed to, uint256 indexed location);
}
