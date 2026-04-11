// Simple bank with transfers -- a classic spec example
// Demonstrates: maps, records, multiple actions, conservation laws
module bank {
  const ACCOUNTS: Set[str]
  const INITIAL_BALANCE: int

  var balances: str -> int

  action init = {
    balances' = ACCOUNTS.mapBy(_ => INITIAL_BALANCE)
  }

  // Deposit money into an account
  action deposit(acct: str, amt: int): bool = all {
    ACCOUNTS.contains(acct),
    amt > 0,
    balances' = balances.set(acct, balances.get(acct) + amt),
  }

  // Withdraw money (must have sufficient funds)
  action withdraw(acct: str, amt: int): bool = all {
    ACCOUNTS.contains(acct),
    amt > 0,
    balances.get(acct) >= amt,
    balances' = balances.set(acct, balances.get(acct) - amt),
  }

  // Transfer between accounts
  action transfer(sender: str, receiver: str, amt: int): bool = all {
    ACCOUNTS.contains(sender),
    ACCOUNTS.contains(receiver),
    sender != receiver,
    amt > 0,
    balances.get(sender) >= amt,
    balances' = balances
      .set(sender,   balances.get(sender) - amt)
      .set(receiver, balances.get(receiver) + amt),
  }

  action step = {
    nondet acct1 = ACCOUNTS.oneOf()
    nondet acct2 = ACCOUNTS.oneOf()
    nondet amount = 1.to(10).oneOf()
    any {
      deposit(acct1, amount),
      withdraw(acct1, amount),
      transfer(acct1, acct2, amount),
    }
  }

  // No account goes negative
  val no_overdraft = ACCOUNTS.forall(a => balances.get(a) >= 0)

  // Total money never decreases (deposits only add, transfers conserve)
  // NOTE: this will FAIL -- deposits increase total. Interesting to discuss!
  val total_conserved = {
    ACCOUNTS.fold(0, (sum, a) => sum + balances.get(a)) ==
      ACCOUNTS.size() * INITIAL_BALANCE
  }
}
