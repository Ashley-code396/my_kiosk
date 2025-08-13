module my_kiosk::royalty_fee_rule;

use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::transfer_policy::{Self, TransferPolicy, TransferRequest, TransferPolicyCap};

const EIncorrectArgument: u64 = 0;
const EInsufficientAmount: u64 = 1;
const MAX_BPS: u16 = 10_000;

public struct Rule has drop {}

public struct Config has drop, store {
    amount_bp: u16,
    min_amount: u64,
}

public fun add_rule_to_policy<Item>(
    policy: &mut TransferPolicy<Item>,
    cap: &TransferPolicyCap<Item>,
    cfg: Config,
    amount_bp: u16,
) {
    assert!(amount_bp<=MAX_BPS, EIncorrectArgument);
    transfer_policy::add_rule(Rule {}, policy, cap, cfg)
}

public fun calculate_fee_amount<Item>(policy: &TransferPolicy<Item>, paid: u64): u64 {
    let config: &Config = transfer_policy::get_rule(Rule {}, policy);
    let mut amount = (((paid as u128) * (config.amount_bp as u128) / 10_000) as u64);

    if (amount < config.min_amount) {
        amount = config.min_amount
    };

    amount
}

public fun pay_royalty<Item>(
    policy: &mut TransferPolicy<Item>,
    request: &mut TransferRequest<Item>,
    payment: Coin<SUI>,
) {
    let paid = transfer_policy::paid(request);
    let amount = calculate_fee_amount(policy, paid);

    assert!(coin::value(&payment) == amount, EInsufficientAmount);

    transfer_policy::add_to_balance(Rule {}, policy, payment);
    transfer_policy::add_receipt(Rule {}, request);
}
