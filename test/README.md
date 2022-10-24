
# Test Suite


## Test Cases

- [X] Create new market
- [X] Only factory admin can create market
- [X] Set oracle role
- [X] Set Escrow role
- [X] Remove escrow role
- [X] Remove oracle role
- [X] Make single prediction
- [X] Make multi prediction
- [X] Can't cashout if market has not finalized
- [X] Cashout if market has finalized, winning prediction only
- [X] Pause market
- [X] Can't act upon a market that is not yet open
- [X] Can't buy invalid prediction option
- [X] Can't cashout prediction not held in wallet
- [X] Can't act upon a paused market
- [X] unPause market
- [X] Can act upon an unpaused market
- [X] Can't cashout losing prediction
- [X] Can't externally call burn function (not escrow)
- [X] Submit market result
- [X] Can't submit market result unless oracle
- [X] Can't submit market result unless market is closed

## Invariants

### 1
If market is not finalized: Sum(all circulating nft tokens) = pot

### 2
Sum(totalDeposited - totalPaidOut) = paymentToken.balanceOf(escrow)

> This assumes no one has "maliciously" sent funds to the escrow wallet. This is a reasonable assumption because 
the funds are un-redeemable.
