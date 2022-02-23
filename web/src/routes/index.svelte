<script lang="ts">
  import {chainTempo} from '$lib/blockchain/chainTempo';
  import {wallet} from '$lib/blockchain/wallet';
  import {nativeTokenSymbol} from '$lib/config';

  import {context} from '$lib/plugin/plugin';
  import {salesQuery} from '$lib/sales/salesQuery';
  import {BigNumber} from '@ethersproject/bignumber';
  import {defaultAbiCoder} from '@ethersproject/abi';
  import {parseEther, formatEther} from '@ethersproject/units';
  import {Contract} from '@ethersproject/contracts';
  // import {onMount} from 'svelte';
  import {contractsInfos} from '$lib/blockchain/contracts';

  chainTempo.startOrUpdateProvider(wallet.provider);

  $: sale =
    $salesQuery.step === 'READY'
      ? $salesQuery.data?.sales.find((v) => v.id == $context.planet?.info.location.id)
      : undefined;

  $: numForSale =
    sale && $context.planet?.state?.numSpaceships
      ? Math.max(0, $context.planet.state.numSpaceships - sale.spaceshipsToKeep)
      : 0;

  let numSpaceships = 0;
  let pricePerUnit = 1;
  let numToBuy = 0;

  // onMount(() => {
  //   numSpaceships = Math.floor(($context.planet?.state?.numSpaceships || 0) / 2);
  // });

  async function submit(event: MouseEvent) {
    event.preventDefault();
    event.stopPropagation();

    // const txData = wallet.contracts.BasicSpaceshipMarket.populateTransaction.setSpaceshipsForSale(
    //   $state.planet.info.location.id,
    //   BigNumber.from(pricePerUnit).mul('1000000000000000000'),
    //   numSpaceships
    // );

    const OuterSpace = new Contract(
      $contractsInfos.contracts.OuterSpace.address,
      $contractsInfos.contracts.OuterSpace.abi
    );
    const BasicSpaceshipMarket = new Contract(
      $contractsInfos.contracts.BasicSpaceshipMarket.address,
      $contractsInfos.contracts.BasicSpaceshipMarket.abi
    );

    const saleCallData = defaultAbiCoder.encode(
      ['uint256', 'uint184', 'uint32'],
      [$context.planet.info.location.id, parseEther(pricePerUnit.toFixed(18)), numSpaceships]
    );

    const txData = await OuterSpace.populateTransaction.setApprovalForAllIfNeededAndCall(
      BasicSpaceshipMarket.address,
      saleCallData
    );

    context.send_tx(txData as {to: string; data: string});
  }

  async function cancel(event: MouseEvent) {
    event.preventDefault();
    event.stopPropagation();

    const BasicSpaceshipMarket = new Contract(
      $contractsInfos.contracts.BasicSpaceshipMarket.address,
      $contractsInfos.contracts.BasicSpaceshipMarket.abi
    );

    const txData = await BasicSpaceshipMarket.populateTransaction.cancelSale($context.planet.info.location.id);
    context.send_tx(txData as {to: string; data: string});
  }

  async function purchase(event: MouseEvent) {
    event.preventDefault();
    event.stopPropagation();

    const location = $context.planet.info.location.id;
    const fleetSender = $context.planet.state.owner;
    const data = {
      abi: $contractsInfos.contracts.BasicSpaceshipMarket.abi.filter((v) => v.name === 'purchase')[0],
      numSpaceships: numToBuy,
      location,
      pricePerUnit: sale.pricePerUnit.toString(),
      contractAddress: $contractsInfos.contracts.BasicSpaceshipMarket.address,
      numSpaceshipsToKeep: sale.spaceshipsToKeep,
      args: [location, '{numSpaceships}', fleetSender, '{toHash}'],
      fleetSender,
      msgValue: '{numSpaceships*pricePerUnit}',
    };
    context.startSendFlow(data);
  }
</script>

<!-- <h1>Basic Spaceship Marketplace</h1> -->

{#if $context.initialized}
  {#if $salesQuery.step !== 'READY'}
    <p>Loading...</p>
  {:else if $context.planet}
    {#if $context.planet.state.owner?.toLowerCase() === $context.account?.toLowerCase()}
      <p>There is {$context.planet.state.numSpaceships} spaceships on planet "{$context.planet.info.stats.name}"</p>
      <hr class="m-2" />

      {#if sale}
        <p>Current Sale:</p>
        <p>
          price per unit : {formatEther(sale.pricePerUnit)}
          {nativeTokenSymbol}
        </p>
        <p>
          available for sale : {numForSale}
        </p>

        <hr class="m-2" />
        <hr class="m-2" />

        <form>
          <div>
            <button
              on:click={cancel}
              type="submit"
              class="m-4 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >Cancel</button
            >
          </div>
        </form>

        <p>Or do you want to update the sale?</p>
      {:else}
        <p>Put spaceships for sale</p>
      {/if}

      <form>
        <div>
          <label for="numSpaceships">Num of spaceship to keep on planet at all time: </label>
          <div>
            <input
              class="text-cyan-300 bg-cyan-300"
              type="range"
              id="numSpaceships"
              name="numSpaceships"
              bind:value={numSpaceships}
              min="0"
              max={$context.planet.state.numSpaceships}
            />
            <p>
              {numSpaceships}{#if numSpaceships >= $context.planet.info.stats.cap}<span class="text-red-500"
                  >(can only sale if over capacity)</span
                >{/if}{#if numSpaceships <= 0}<span class="text-red-500"
                  >(a buyer can thus buy all spaceship and put the planet at risk)</span
                >{/if}
            </p>
          </div>
        </div>
        <div>
          <label for="pricePerUnit">Price per spaceship ({nativeTokenSymbol}) </label>
          <div>
            <input type="number" id="pricePerUnit" name="pricePerUnit" bind:value={pricePerUnit} />
          </div>
        </div>
        <div>
          <button
            on:click={submit}
            type="submit"
            class="m-4 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >Put For Sale</button
          >
        </div>
      </form>
    {:else if sale}
      {#if numForSale == 0}
        <p>No spaceships available right now, come back later</p>

        <p>
          price per unit : {formatEther(sale.pricePerUnit)}
          {nativeTokenSymbol}
        </p>
      {:else}
        <p>How many spaceships do you want to purchase ?</p>
        <p>
          price per unit : {formatEther(sale.pricePerUnit)}
          {nativeTokenSymbol}
        </p>
        <p>
          available for sale : {numForSale}
        </p>

        <hr class="m-2" />
        <hr class="m-2" />

        <form>
          <div>
            <label for="numToBuy">Number of spaceships to buy</label>
            <div>
              <input
                class="text-cyan-300 bg-cyan-300"
                type="range"
                id="numToBuy"
                name="numToBuy"
                bind:value={numToBuy}
                min="0"
                max={numForSale}
              />
              <p>
                {numToBuy}
              </p>
            </div>
          </div>
          <div>
            <button
              on:click={purchase}
              type="submit"
              class="m-4 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >Purchase</button
            >
          </div>
        </form>
      {/if}
    {:else}
      <p>No Sale</p>
    {/if}
  {:else}
    <p>Waiting for showing instruction...</p>
  {/if}
{:else}
  <p>Waiting for initialization to complete....</p>
{/if}
