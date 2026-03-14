def get_float_input(prompt: str) -> float:
    """Pure function to handle string-to-float conversion from stdin."""
    try:
        return float(input(prompt).replace('$', '').replace(',', ''))
    except ValueError:
        print("Invalid input. Please enter a number.")
        return get_float_input(prompt)


def get_action_input() -> bool:
    """Pure function to determine if the user is buying or selling."""
    choice = input("\nAction: (1) Buy or (2) Sell? Enter 1 or 2: ").strip()
    if choice == '1':
        return True
    elif choice == '2':
        return False
    else:
        print("Invalid choice. Please enter 1 or 2.")
        return get_action_input()


def calculate_orders(balances: dict, amount: float, targets: dict, is_buy: bool) -> dict:
    """
    Pure function that handles both DCA buying and withdrawal liquidations.
    Uses dict comprehensions to calculate either deficits (for buys) or
    surpluses (for sells) against the projected new total.
    """
    # Calculate what the portfolio will be worth after the transaction
    new_total = sum(balances.values()) + (amount if is_buy else -amount)

    # If buying, delta is target - current. If selling, delta is current - target.
    # Max(0, ...) ensures we only buy underweighted assets and only sell overweighted assets.
    deltas = {
        fund: max(0, (targets[fund] * new_total) - balance if is_buy else balance - (targets[fund] * new_total))
        for fund, balance in balances.items()
    }

    total_delta = sum(deltas.values())

    # Distribute the transaction amount proportionally based on the deltas
    return {
        fund: round((delta / total_delta) * amount, 2) if total_delta > 0 else 0
        for fund, delta in deltas.items()
    }


def main():
    print("--- Kernel Portfolio Rebalancer ---")

    targets = {
        "US": 0.65,
        "ex-US": 0.30,
        "NZ": 0.05
    }

    balances = {
        "US": get_float_input("Current US fund balance: $"),
        "ex-US": get_float_input("Current ex-US fund balance: $"),
        "NZ": get_float_input("Current NZ fund balance: $")
    }

    is_buy = get_action_input()
    action_word = "Deposit" if is_buy else "Withdrawal"

    amount = get_float_input(f"\n{action_word} amount: $")

    # Guardrail against selling more than exists
    if not is_buy and amount > sum(balances.values()):
        print("\nError: You cannot withdraw more than the total portfolio value.")
        return

    orders = calculate_orders(balances, amount, targets, is_buy)

    print(f"\n--- Optimal {'Buy' if is_buy else 'Sell'} Orders ---")
    for fund, order_amount in orders.items():
        print(f"{fund}: ${order_amount:,.2f}")


if __name__ == "__main__":
    main()