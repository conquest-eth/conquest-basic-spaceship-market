/* eslint-disable prefer-const */
import {SpaceshipsForSale, SaleCancelled} from '../generated/BasicSpaceshipMarket/BasicSpaceshipMarketContract';
import {FleetArrived, ExitComplete} from '../generated/OuterSpace/OuterSpaceContract';
import {SpaceshipSale} from '../generated/schema';
import {store} from '@graphprotocol/graph-ts';

export function handleSpaceshipsForSale(event: SpaceshipsForSale): void {
  let id = event.params.location.toHex();
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

export function handleSaleCancelled(event: SaleCancelled): void {
  let id = event.params.location.toHex();
  let entity = SpaceshipSale.load(id);
  if (entity) {
    store.remove('SpaceshipSale', id);
  }
}

export function handleFleetArrived(event: FleetArrived): void {
  let id = event.params.destination.toHex();
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
  let id = event.params.location.toHex();
  let entity = SpaceshipSale.load(id);
  if (entity) {
    store.remove('SpaceshipSale', id);
  }
}
