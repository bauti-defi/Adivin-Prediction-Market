# Invariants

### 1
If market is not finalized: Sum(all circulating nft tokens) = pot

### 2
Sum(totalDeposited - totalPaidOut) = paymentToken.balanceOf(escrow)

> This assumes no one has "maliciously" sent funds to the escrow wallet. This is a reasonable assumption because 
the funds are un-redeemable.