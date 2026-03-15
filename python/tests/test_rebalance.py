import unittest

from python.src.main import calculate_orders

class TestKernelRebalancer(unittest.TestCase):
    def setUp(self):
        self.targets = {"US": 0.65, "ex-US": 0.30, "NZ": 0.05}
        self.starting_balances = {"US": 37500.0, "ex-US": 12500.0, "NZ": 0.0}

    def test_standard_waterfall_deposit(self):
        deposit = 1500.0
        orders = calculate_orders(self.starting_balances, deposit, self.targets, is_buy=True)
        self.assertEqual(sum(orders.values()), deposit)
        self.assertTrue(orders["NZ"] > 0)
        self.assertTrue(orders["US"] == 0)

    def test_massive_lump_sum_spillover(self):
        deposit = 5000.0
        orders = calculate_orders(self.starting_balances, deposit, self.targets, is_buy=True)
        self.assertLessEqual(self.starting_balances["NZ"] + orders["NZ"], 2750.0)
        self.assertLessEqual(self.starting_balances["ex-US"] + orders["ex-US"], 16500.0)
        self.assertEqual(sum(orders.values()), deposit)

    def test_massive_liquidation_sell(self):
        withdrawal = 10000.0
        orders = calculate_orders(self.starting_balances, withdrawal, self.targets, is_buy=False)

        # Total sell should exactly match withdrawal amount
        self.assertEqual(sum(orders.values()), withdrawal)

        # NZ is at 0, so it shouldn't be sold from at all
        self.assertEqual(orders["NZ"], 0.0)

        # Both US and ex-US are technically overweight compared to the NEW 40k portfolio size
        # (New targets: US = 26k, ex-US = 12k. Current: US = 37.5k, ex-US = 12.5k)
        # Therefore, we should be selling from both, but mostly from the massively overweight US fund.
        self.assertTrue(orders["US"] > orders["ex-US"])
        self.assertTrue(orders["ex-US"] > 0)


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestKernelRebalancer)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)