module my_kiosk::my_kiosk;

use sui::coin::Coin;
use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
use sui::package;
use sui::sui::SUI;
use sui::transfer_policy::{Self, TransferPolicy};

public struct Item has key, store {
    id: UID,
}

public struct MY_KIOSK has drop {}

#[allow(lint(share_owned))]
fun init(otw: MY_KIOSK, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);
    let (policy, tp_cap) = transfer_policy::new<Item>(&publisher, ctx);

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_share_object(policy);
    transfer::public_transfer(tp_cap, ctx.sender());
}

#[allow(lint(self_transfer))]
public fun create_kiosk(ctx: &mut TxContext) {
    let (kiosk, kiosk_owner_cap) = kiosk::new(ctx);

    transfer::public_transfer(kiosk_owner_cap, ctx.sender());
    transfer::public_share_object(kiosk);
}

public fun create_item(ctx: &mut TxContext): Item {
    let item = Item {
        id: object::new(ctx),
    };
    (item)
}

public fun place_item_in_kiosk(kiosk: &mut Kiosk, cap: &KioskOwnerCap, ctx: &mut TxContext) {
    let item = create_item(ctx);
    kiosk::place(kiosk, cap, item)
}

public fun lock_item_in_kiosk(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    _policy: &TransferPolicy<Item>,
    ctx: &mut TxContext,
) {
    let item = create_item(ctx);
    kiosk::lock(kiosk, cap, _policy, item)
}

#[allow(lint(self_transfer))]
public fun take_item_from_kiosk(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    item_id: ID,
    ctx: &mut TxContext,
) {
    let item = kiosk::take<Item>(kiosk, cap, item_id);
    transfer::public_transfer(item, ctx.sender());
}

public fun list_item(kiosk: &mut Kiosk, cap: &KioskOwnerCap, item_id: ID, price: u64) {
    kiosk::list<Item>(kiosk, cap, item_id, price);
}

public fun place_and_list_item(kiosk: &mut Kiosk, cap: &KioskOwnerCap, item: Item, price: u64) {
    kiosk::place_and_list(kiosk, cap, item, price);
}

public fun delist_item(kiosk: &mut Kiosk, cap: &KioskOwnerCap, item_id: ID) {
    kiosk::delist<Item>(kiosk, cap, item_id);
}

public fun list_with_purchase_cap(
    kiosk: &mut Kiosk,
    cap: &KioskOwnerCap,
    item_id: ID,
    min_price: u64,
    allowed_buyer: address,
    ctx: &mut TxContext,
) {
    let purchase_cap = kiosk::list_with_purchase_cap<Item>(kiosk, cap, item_id, min_price, ctx);
    transfer::public_transfer(purchase_cap, allowed_buyer);
}

#[allow(lint(self_transfer))]
public fun withdraw_kiosk_profits(kiosk: &mut Kiosk, cap: &KioskOwnerCap, amount: Option<u64>,ctx: &mut TxContext){
    let profits = kiosk::withdraw(kiosk, cap, amount, ctx);
    transfer::public_transfer(profits, ctx.sender());

}
// ===Purchase Functions ===

#[allow(lint(self_transfer))]
public fun purchase_item_from_kiosk(
    kiosk: &mut Kiosk,
    item_id: ID,
    policy: &TransferPolicy<Item>,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
) {
    let (item, request) = kiosk::purchase<Item>(kiosk, item_id, payment);

    transfer_policy::confirm_request(policy, request);
    transfer::public_transfer(item, ctx.sender())
}

#[allow(lint(self_transfer))]
public fun purchase_item_from_kiosk_with_purchase_cap(
    kiosk: &mut Kiosk,
    purchase_cap: PurchaseCap<Item>,
    policy: &TransferPolicy<Item>,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
) {
    let (item, request) = kiosk::purchase_with_cap(kiosk, purchase_cap, payment);
    transfer_policy::confirm_request(policy, request);
    transfer::public_transfer(item, ctx.sender())
}
