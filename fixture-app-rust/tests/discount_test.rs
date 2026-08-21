use revi_fixture_app_rust::discount::bulk_discount;

#[test]
fn applies_discount_at_exactly_10_units() {
    // 10 units at 100 each should get the 10% bulk discount: 1000 -> 900
    assert_eq!(bulk_discount(100, 10), 900);
}

#[test]
fn applies_discount_above_10_units() {
    assert_eq!(bulk_discount(100, 11), 990);
}

#[test]
fn no_discount_below_10_units() {
    assert_eq!(bulk_discount(100, 9), 900);
}
