use revi_fixture_app_rust::discount::bulk_discount;

#[test]
fn applies_bulk_discount_at_exactly_ten_units() {
    // Orders of exactly 10 units should receive the 10% bulk discount.
    assert_eq!(bulk_discount(100, 10), 900);
}

#[test]
fn applies_bulk_discount_above_ten_units() {
    assert_eq!(bulk_discount(100, 11), 990);
}

#[test]
fn no_discount_below_ten_units() {
    assert_eq!(bulk_discount(50, 9), 450);
}
