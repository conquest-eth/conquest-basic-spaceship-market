/* eslint-disable prefer-const */
import {
  ContinuousSpaceshipsForSale,
  ContinuousSaleCancelled,
} from '../generated/BasicContinuousSpaceshipSale/BasicContinuousSpaceshipSaleContract';
import {FleetArrived, ExitComplete} from '../generated/OuterSpace/OuterSpaceContract';
import {SpaceshipSale} from '../generated/schema';
import {store, BigInt} from '@graphprotocol/graph-ts';

export function toPlanetId(location: BigInt): string {
  return '0x' + location.toHex().slice(2).padStart(64, '0');
}

export function handleSpaceshipsForSale(event: ContinuousSpaceshipsForSale): void {
  let id = toPlanetId(event.params.location);
  let entity = SpaceshipSale.load(id);
  if (!entity) {
    entity = new SpaceshipSale(id);
  }
  entity.seller = event.params.owner;
  entity.pricePerUnit = event.params.pricePerUnit;
  entity.timestamp = event.block.timestamp;
  entity.spaceshipsToKeep = event.params.spaceshipsToKeep;
  entity.save();
}

export function handleSaleCancelled(event: ContinuousSaleCancelled): void {
  let id = toPlanetId(event.params.location);
  let entity = SpaceshipSale.load(id);
  if (entity) {
    store.remove('SpaceshipSale', id);
  }
}

export function handleFleetArrived(event: FleetArrived): void {
  let id = toPlanetId(event.params.destination);
  // TODO rename won to capture, new owner
  //  and check if recorded properly
  if (event.params.won) {
    let entity = SpaceshipSale.load(id);
    if (entity) {
      if (entity.seller != event.params.fleetOwner) {
        store.remove('SpaceshipSale', id);
      }
    }
  }
}

export function handleExitComplete(event: ExitComplete): void {
  let id = toPlanetId(event.params.location);
  let entity = SpaceshipSale.load(id);
  if (entity) {
    store.remove('SpaceshipSale', id);
  }
}
